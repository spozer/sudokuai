import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// The main widget for taking pictures.
class CameraView extends StatefulWidget {
  final void Function(String imagePath, {int? roiSize, int? roiOffset})
      scanImage;

  const CameraView({super.key, required this.scanImage});

  @override
  CameraViewState createState() => CameraViewState();
}

class CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  late Future<CameraDescription> camera;
  // Percentage, based off of camera preview size.
  final double _roiSize = 0.7;

  // Various states.
  bool _isTakingPicture = false;
  bool _isFlashOn = false;
  // Keep in mind that _controller.value.isInitialized is not changed on
  // dispose of camera controller. So only use this to check if camera
  // was initialized at least once in the past. Use the following
  // parameter to check the actual state.
  bool _isCameraInitialized = false;
  bool _isCameraAccessGranted = false;
  bool _showFocusCircle = false;
  double _focusX = 0;
  double _focusY = 0;

  @override
  void initState() {
    super.initState();

    // Get main back facing camera.
    camera = availableCameras().then((value) {
      return value.firstWhere(
        (CameraDescription camera) =>
            camera.lensDirection == CameraLensDirection.back,
      );
    });

    _getCameraPermission().then((_) {
      _initCamera();
    });

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    if (kDebugMode) debugPrint("Dispose CameraView");
    WidgetsBinding.instance.removeObserver(this);
    // Dispose of the controller when the widget is disposed.
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (_controller == null || !_controller!.value.isInitialized) return;

    // When the app gets minimized or when another app gets
    // control of the camera api the current [CameraController]
    // is not valid anymore. Therefore the camera needs to
    // be reinitialized on resume.
    if (state == AppLifecycleState.resumed) {
      if (kDebugMode) debugPrint("CameraView state changed to resumed");
      // Resume with last state of camera flash.
      _initCamera();
    } else if (state == AppLifecycleState.paused) {
      if (kDebugMode) debugPrint("CameraView state changed to paused");
      // Make sure the current [CameraController] gets disposed of cleanly.
      _closeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen height and width (in logical pixels).
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).viewPadding.top;

    // Define widget sizes which are scaled by the screen size.
    final bottomBarHeight = screenHeight * 0.22;
    final cameraWidgetHeight = screenHeight - bottomBarHeight - topPadding;

    // Main widget existing of the camera preview, the ROI indicator overlay,
    // the buttons for taking a picture, loading a picture from device storage,
    // and a button detecated for turining flash on/off.
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Stack(
          children: <Widget>[
            _getCameraWidget(cameraWidgetHeight, screenWidth),
            _getBottomBar(bottomBarHeight, screenWidth)
          ],
        ),
      ),
    );
  }

  /// Warning dialog that camera permission could not be granted.
  ///
  /// Give the user the option to change permissions in app settings,
  /// or to close the app completely.
  Future<void> _showPermissionDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera permission'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("To use the camera, you first have to grant access"
                    " to it. You can change permissions in the app settings."),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Retry'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                exit(-1);
              },
            ),
            TextButton(
              child: const Text('Settings'),
              onPressed: () {
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  /// Requests permission to use camera.
  Future<void> _getCameraPermission() async {
    final status = await Permission.camera.request();

    _isCameraAccessGranted = status.isGranted;

    if (status.isPermanentlyDenied) {
      // Show warning to user.
      await _showPermissionDialog();
      await _getCameraPermission();
    }
  }

  /// Initialize the camera.
  Future<void> _initCamera() async {
    if (_isCameraInitialized || !_isCameraAccessGranted) return;

    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      await camera,
      // Define the resolution to use.
      ResolutionPreset.max,
      // Audio not needed
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Initialize the controller.
    _initializeControllerFuture = _controller!.initialize();

    try {
      // Wait for initialization.
      await _initializeControllerFuture;
      _isCameraInitialized = true;
      _setFlash(false);
    } on CameraException catch (e) {
      // Ignore error, just move on.
      debugPrint("Error in _initCamera: $e.code\nError Message: $e.message");
    }

    if (mounted) setState(() {});
  }

  // Dispose of camera.
  Future<void> _closeCamera() async {
    _controller?.dispose();
    _isCameraInitialized = false;
    _isFlashOn = false;

    if (mounted) setState(() {});
  }

  /// A widget to show the camera preview.
  ///
  /// The goal is to fit the camera preview to the size of the widget.
  /// To fill out the whole widget - we don't want any black bars - we need
  /// to crop the preview first. When fitting to its width we lose some pixels
  /// at the top and de botttom.
  Widget _getCameraWidget(double height, double width) {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        // Future can have state 'done' even when finishing with errors, so
        // check actual state of camera too.
        if (snapshot.connectionState == ConnectionState.done &&
            _isCameraInitialized) {
          // Get camera height and width in portrait orientation.
          final cameraWidth = _controller!.value.previewSize!.height;
          final cameraHeight = _controller!.value.previewSize!.width;

          // Get aspect ratio in landscape orientation.
          double cameraAspectRatio = cameraHeight / cameraWidth;

          // Size of the camera preview in logical pixels.
          // camera pixels != widget (logical) pixels
          double actualWidth = width;
          double actualHeight = width * cameraAspectRatio;

          double focusCircleSize = width / 6;

          return Stack(children: [
            SizedBox(
              width: width,
              height: height,
              child: ClipRect(
                child: FittedBox(
                  alignment: Alignment.center,
                  fit: BoxFit.fitWidth,
                  child: SizedBox(
                    width: actualWidth,
                    height: actualHeight,
                    child: GestureDetector(
                      onTapUp: (details) =>
                          _onTapFocus(details, actualWidth, actualHeight),
                      child: Stack(children: [
                        CameraPreview(_controller!),
                        if (_showFocusCircle)
                          TweenAnimationBuilder(
                            tween: Tween(begin: 1.0, end: 0.8),
                            duration: const Duration(milliseconds: 300),
                            builder: (context, value, child) {
                              double scaledSize = value * focusCircleSize;
                              return Positioned(
                                top: _focusY - scaledSize / 2,
                                left: _focusX - scaledSize / 2,
                                child: Container(
                                  height: scaledSize,
                                  width: scaledSize,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      )),
                                ),
                              );
                            },
                          )
                      ]),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: width,
              height: height,
              child: Align(
                  alignment: Alignment.center,
                  child: _getCameraOverlay(width * _roiSize)),
            )
          ]);
        } else {
          return Container(color: Colors.black);
        }
      },
    );
  }

  /// Callback function to set focus on tap
  Future<void> _onTapFocus(
      TapUpDetails details, double width, double height) async {
    if (_showFocusCircle || !_isCameraInitialized || _isTakingPicture) return;

    double x = details.localPosition.dx;
    double y = details.localPosition.dy;
    double xp = x / width;
    double yp = y / height;

    Offset point = Offset(xp, yp);
    if (kDebugMode) debugPrint("tap focus point: $point");

    if (mounted) {
      setState(() {
        _focusX = x;
        _focusY = y;
        _showFocusCircle = true;
        Future.delayed(const Duration(milliseconds: 700)).whenComplete(() {
          setState(() {
            _showFocusCircle = false;
          });
        });
      });
    }

    try {
      await Future.wait([
        // Manually set focus point
        _controller!.setFocusPoint(point),
        // Manually set light exposure
        _controller!.setExposurePoint(point),
      ]);
    } on CameraException catch (e) {
      // Ignore error, just do nothing.
      debugPrint("Error in _onTapFocus: $e.code\nError Message: $e.message");
    }
  }

  /// A widget indicating the ROI as an overlay.
  ///
  /// The overlay exists of four corner pieces forming a square.
  Widget _getCameraOverlay(double size) {
    // Color and thickness of the overlay.
    const defaultLine = BorderSide(color: Colors.white, width: 3);
    // Size of a corner piece.
    final lineLength = size * 0.1;
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        children: <Widget>[
          if (_isTakingPicture)
            const Align(
              alignment: Alignment.center,
              // Display loading indicator while taking a picture.
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          Align(
            alignment: Alignment.topLeft,
            child: _makeOverlayCorner(
              lineLength,
              top: defaultLine,
              left: defaultLine,
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: _makeOverlayCorner(
              lineLength,
              top: defaultLine,
              right: defaultLine,
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: _makeOverlayCorner(
              lineLength,
              bottom: defaultLine,
              left: defaultLine,
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: _makeOverlayCorner(
              lineLength,
              bottom: defaultLine,
              right: defaultLine,
            ),
          )
        ],
      ),
    );
  }

  /// Helper function which creates corner pieces for the overlay widget.
  Widget _makeOverlayCorner(
    double size, {
    BorderSide top = BorderSide.none,
    BorderSide bottom = BorderSide.none,
    BorderSide left = BorderSide.none,
    BorderSide right = BorderSide.none,
  }) {
    return IgnorePointer(
      ignoring: true,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          border: Border(
            top: top,
            bottom: bottom,
            left: left,
            right: right,
          ),
        ),
      ),
    );
  }

  /// A widget defining the bottom bar.
  ///
  /// The bottom bar exists of three buttons (from left to right):
  ///  * A button for toggling the flash on/off.
  ///  * A button for taking a picture.
  ///  * A button to load an image from the devices storage.
  Widget _getBottomBar(double height, double width) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        child: Container(
          height: height,
          width: width,
          alignment: Alignment.topCenter,
          child: _getButtonRow(width),
        ),
      ),
    );
  }

  /// Helper function creating the buttons for the buttom bar widget.
  Widget _getButtonRow(double size) {
    return Padding(
      padding: EdgeInsets.only(
          left: size * 0.08, right: size * 0.08, top: size * 0.08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FloatingActionButton(
            heroTag: "ToggleFlashButton",
            elevation: 0,
            foregroundColor: _isFlashOn ? Colors.yellow : Colors.white,
            backgroundColor: Colors.transparent,
            onPressed: _onToggleFlashButtonPressed,
            child: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              size: size * 0.08,
            ),
          ),
          SizedBox(
            height: size * 0.22,
            width: size * 0.22,
            child: FloatingActionButton(
              heroTag: "TakePictureButton",
              foregroundColor: Colors.grey,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(50))),
              onPressed: _onTakePictureButtonPressed,
              child: Icon(
                Icons.circle,
                size: size * 0.21,
              ),
            ),
          ),
          FloatingActionButton(
            heroTag: "GalleryButton",
            elevation: 0,
            foregroundColor: Colors.white,
            backgroundColor: Colors.transparent,
            onPressed: _onGalleryButtonPressed,
            child: Icon(
              Icons.image,
              size: size * 0.1,
            ),
          ),
        ],
      ),
    );
  }

  /// Callback function for handling ToggleFlashButton pressed events.
  void _onToggleFlashButtonPressed() async {
    _setFlash(!_isFlashOn);
  }

  void _setFlash(flashOn) async {
    if (!_isCameraInitialized || _isTakingPicture) return;

    try {
      await _controller!
          .setFlashMode(flashOn ? FlashMode.torch : FlashMode.off);
      _isFlashOn = flashOn;
    } on CameraException catch (e) {
      // Ignore error, just do nothing.
      debugPrint(
          "Error in _onToggleFlashButtonPressed: $e.code\nError Message: $e.message");
    }

    if (mounted) setState(() {});
  }

  /// Callback function for handling TakePictureButton pressed events.
  void _onTakePictureButtonPressed() async {
    if (!_isCameraInitialized || _isTakingPicture) return;

    try {
      if (mounted) {
        setState(() {
          _isTakingPicture = true;
        });
      }
      // TODO: show taking picture animation here

      // Attempt to take a picture and get the file `image`
      // where it was saved.
      final image = await _controller!.takePicture();

      // read image to get its resolution (we don't know it becauce camera preview resolution != image taken)
      final buffer = await ImmutableBuffer.fromFilePath(image.path);
      final descriptor = await ImageDescriptor.encoded(buffer);

      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }

      final imageWidth = descriptor.width;
      final imageHeight = descriptor.height;

      // If the picture was taken, scan its content.
      widget.scanImage(
        image.path,
        roiSize: (_roiSize * imageWidth).toInt(),
        roiOffset: (0 * imageHeight).toInt(),
      );
    } on CameraException catch (e) {
      // TODO: error handling when taking picture fails
      debugPrint(
          "Error in _onTakePictureButtonPressed: $e.code\nError Message: $e.message");
      rethrow;
    }
  }

  /// Callback function for handling GalleryButton pressed events.
  void _onGalleryButtonPressed() async {
    if (_isTakingPicture) return;

    _setFlash(false);

    try {
      // TODO: maybe implement transition stage which replaces Camera View
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        widget.scanImage(image.path);
      }
      // Back button was pressed.
    } on PlatformException catch (e) {
      // TODO: error handling when picking image fails
      debugPrint(
          "Error in _onGalleryButtonPressed: $e.code\nError Message: $e.message");
      rethrow;
    }
  }
}
