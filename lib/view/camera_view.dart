import 'dart:io';
import 'dart:ui';
import 'dart:async';
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
  // Offset percentage from center to top.
  late double _roiOffset;
  // Percentage, based off of overlay size.
  late double _roiSize;
  // The actual preview size of the camera widget.
  late double _previewHeight;
  late double _previewWidth;

  // Various states.
  bool _isTakingPicture = false;
  bool _isFlashOn = false;
  bool _wasFlashOn = false;
  // Keep in mind that _controller.value.isInitialized is not changed on
  // dispose of camera controller. So only use this to check if camera
  // was initialized at least once in the past. Use the following
  // parameter to check the actual state.
  bool _isCameraInitialized = false;
  bool _isCameraAccessGranted = false;
  bool _isCameraDisabled = false;

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
    debugPrint("Dispose CameraView");
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
      debugPrint("CameraView state changed to resumed");
      // Resume with last state of camera flash.
      if (!_isCameraDisabled) _initCamera(flashOn: _wasFlashOn);
    } else if (state == AppLifecycleState.paused) {
      // Make sure the current [CameraController] gets disposed of cleanly.
      debugPrint("CameraView state changed to paused");
      // Save current state of camera flash.
      _wasFlashOn = _isFlashOn;
      _closeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen height and width (in logical pixels).
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    // Define widget sizes which are scaled by the screen size.
    final bottomBarHeight = screenHeight * 0.15;
    final bottomBarWidth = screenWidth * 0.9;
    final bottomBarOffset = screenHeight * 0.03;
    final overlayOffset = 0.5 * (bottomBarOffset + bottomBarHeight);
    final overlaySize = screenWidth * 0.7;

    // Define Region Of Interest (ROI) based on camera overlay.
    // It is expected that the user tries to place the Sudoku grid
    // inside this region.
    // Offset from center in [-height / 2, height / 2].
    _roiOffset = -overlayOffset / screenHeight; // -0.09;
    _roiSize = (1.0 + (overlaySize / screenWidth)) / 2;

    // Main widget existing of the camera preview, the ROI indicator overlay,
    // the buttons for taking a picture, loading a picture from device storage,
    // and a button detecated for turining flash on/off.
    return Scaffold(
      body: Stack(
        children: <Widget>[
          _getCameraWidget(screenHeight, screenWidth),
          _getCameraOverlay(overlaySize, overlayOffset),
          _getBottomBar(bottomBarHeight, bottomBarWidth, bottomBarOffset),
        ],
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
  Future<void> _initCamera({bool flashOn = false}) async {
    if (_isCameraInitialized || !_isCameraAccessGranted) return;

    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      await camera,
      // Define the resolution to use.
      // Better to use 1280x720 because the flutter camera plugin just
      // doesn't recognize higher resolutions, even though the resulting
      // image has the right resolution.
      ResolutionPreset.high,
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
      // Set initial flash mode.
      await _controller!
          .setFlashMode(flashOn ? FlashMode.torch : FlashMode.off);
      _isFlashOn = flashOn;
    } on CameraException catch (e) {
      // Ignore error, just move on.
      debugPrint('Error in _initCamera: $e.code\nError Message: $e.message');
    }

    // Refresh page if mounted.
    if (mounted) setState(() {});
  }

  // Dispose of camera.
  Future<void> _closeCamera() async {
    if (_isCameraInitialized) _controller?.dispose();
    _isCameraInitialized = false;
    _isFlashOn = false;

    // Refresh page if mounted.
    if (mounted) setState(() {});
  }

  /// A widget to show the camera preview.
  ///
  /// The goal is to fit the camera preview to the size of the widget.
  /// To fill out the whole widget - we don't want any black bars - we need
  /// to crop the preview first. Depending on the aspect ratio of
  /// the widget [widgetAspectRatio] and the camera [cameraAspectRatio],
  /// the preview gets fitted eighter to its height or its width.
  /// When fitting to its height we lose some pixels on both sides left/right.
  /// When fitting to its width we lose some pixels at the top and de botttom.
  Widget _getCameraWidget(double height, double width) {
    // You must wait until the controller is initialized before displaying the
    // camera preview. Use a FutureBuilder to display a loading spinner until the
    // controller has finished initializing.
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

          // Get aspect ratios in landscape orientation.
          double cameraAspectRatio = cameraHeight / cameraWidth;
          double widgetAspectRatio = height / width;

          // Whether we have to fit the camera preview to its height
          // or its width.
          bool fitHeight = (widgetAspectRatio > cameraAspectRatio);

          // Save cropped size of preview, which is displayed in this widget.
          _previewWidth =
              fitHeight ? cameraHeight / widgetAspectRatio : cameraWidth;
          _previewHeight =
              fitHeight ? cameraHeight : cameraWidth * widgetAspectRatio;

          return SizedBox(
            width: width,
            height: height,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: fitHeight ? BoxFit.fitHeight : BoxFit.fitWidth,
                  child: SizedBox(
                    width: fitHeight ? height / cameraAspectRatio : width,
                    height: fitHeight ? height : width * cameraAspectRatio,
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),
            ),
          );
        } else {
          // Otherwise, display a loading indicator.
          return Container(color: Colors.black);
        }
      },
    );
  }

  /// A widget indicating the ROI as an overlay.
  ///
  /// The overlay exists of four corner pieces forming a square.
  Widget _getCameraOverlay(double size, double vOffset) {
    // Color and thickness of the overlay.
    const defaultLine = BorderSide(color: Colors.white, width: 3);
    // Size of a corner piece.
    final lineLength = size * 0.1;
    return Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: 2 * vOffset),
        child: SizedBox(
          height: size,
          width: size,
          child: Stack(
            children: <Widget>[
              Align(
                alignment: Alignment.center,
                // Display loading indicator while taking a picture.
                child: _isTakingPicture
                    ? const CircularProgressIndicator()
                    : Container(),
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
        ),
      ),
    );
  }

  /// Helper function which creates corner pieces for the overlay widget.
  Container _makeOverlayCorner(
    double size, {
    BorderSide top = BorderSide.none,
    BorderSide bottom = BorderSide.none,
    BorderSide left = BorderSide.none,
    BorderSide right = BorderSide.none,
  }) {
    return Container(
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
    );
  }

  /// A widget defining the bottom bar.
  ///
  /// The bottom bar exists of three buttons (from left to right):
  ///  * A button for toggling the flash on/off.
  ///  * A button for taking a picture.
  ///  * A button to load an image from the devices storage.
  Widget _getBottomBar(double height, double width, double offset) {
    return Padding(
      padding: EdgeInsets.only(bottom: offset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(40)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: height,
              width: width,
              color: Colors.black.withOpacity(0.1),
              alignment: Alignment.center,
              child: _getButtonRow(height, width),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper function creating the buttons for the buttom bar widget.
  Widget _getButtonRow(double barHeight, double barWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: barWidth * 0.07),
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
              size: barHeight * 0.32,
            ),
          ),
          SizedBox(
            height: barHeight * 0.7,
            width: barHeight * 0.7,
            child: FloatingActionButton(
              heroTag: "TakePictureButton",
              foregroundColor: Colors.grey,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(50))),
              onPressed: _onTakePictureButtonPressed,
              child: Icon(
                Icons.circle,
                size: barHeight * 0.65,
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
              size: barHeight * 0.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Callback function for handling ToggleFlashButton pressed events.
  void _onToggleFlashButtonPressed() async {
    if (!_isCameraInitialized || _isTakingPicture) return;

    try {
      await _controller!
          .setFlashMode(_isFlashOn ? FlashMode.off : FlashMode.torch);
      _isFlashOn = !_isFlashOn;
    } on CameraException catch (e) {
      // Ignore error, just do nothing.
      debugPrint(
          'Error in _onToggleFlashButtonPressed: $e.code\nError Message: $e.message');
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

      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }

      // If the picture was taken, scan its content.
      widget.scanImage(
        image.path,
        roiSize: (_roiSize * _previewWidth).toInt(),
        roiOffset: (_roiOffset * _previewHeight).toInt(),
      );
    } on CameraException catch (e) {
      // TODO: error handling when taking picture fails
      debugPrint(
          'Error in _onTakePictureButtonPressed: $e.code\nError Message: $e.message');
      rethrow;
    }
  }

  /// Callback function for handling GalleryButton pressed events.
  void _onGalleryButtonPressed() async {
    if (_isTakingPicture) return;

    try {
      // TODO: maybe implement transition stage which replaces Camera View
      // Mark camera as disabled for App Lifecycle Observer, because
      // opening Image Picker (Gallery) causes app to get paused/resumed.
      _isCameraDisabled = true;

      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        widget.scanImage(image.path);
      } else {
        // Back button was pressed.
        _isCameraDisabled = false;
        if (!_isCameraInitialized) _initCamera(flashOn: _wasFlashOn);
      }
    } on PlatformException catch (e) {
      // TODO: error handling when picking image fails
      debugPrint(
          'Error in _onGalleryButtonPressed: $e.code\nError Message: $e.message');
      rethrow;
    }
  }
}
