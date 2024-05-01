import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:sudoku_scanner/sudoku_scanner.dart';
import 'package:sudoku_scanner/bounding_box.dart';

class ScannerView extends StatefulWidget {
  final String imagePath;
  final void Function(Future<Uint8List> sudokuGrid) showSudoku;
  final void Function() onBack;

  const ScannerView({
    super.key,
    required this.imagePath,
    required this.showSudoku,
    required this.onBack,
  });

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  late Future<ui.Image> _imageFuture;
  late Future<void> _firstBuildFuture;

  List<Offset> _points = [];
  Size? _maxPreviewSize;
  Offset _minPreviewOffset = const Offset(0, 0);
  Size? _previewSize;
  Offset _previewOffset = const Offset(0, 0);
  bool _gotBoundingBox = false;
  bool _showMagnifier = false;
  int? _touchBubbleId;

  @override
  void initState() {
    final firstBuildCompleter = Completer();
    _firstBuildFuture = firstBuildCompleter.future;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Indicate that first build was completed.
      firstBuildCompleter.complete();
    });

    _imageFuture = _getUiImage(widget.imagePath);

    SudokuScanner.detectGrid(widget.imagePath).then(_onScanComplete);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Padding for preview.
    final previewLeft = 0.07 * screenWidth;
    final previewTop =
        MediaQuery.of(context).viewPadding.top + 0.02 * screenHeight;

    _minPreviewOffset = Offset(previewLeft, previewTop);
    _maxPreviewSize = Size(screenWidth - 2 * previewLeft, screenHeight * 0.83);

    final touchBubbleSize = screenHeight * 0.04;
    final magnifierWidth = screenWidth * 0.2;
    final magnifierHeight = magnifierWidth / 1.25;
    final magnifierYOffset = -magnifierHeight / 2 - touchBubbleSize;
    final buttonBarSize = screenHeight - _maxPreviewSize!.height - previewTop;
    final buttonBarOffset = buttonBarSize / 2;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            _getPreview(_maxPreviewSize!, _minPreviewOffset),
            _getBoundingBox(touchBubbleSize),
            if (_showMagnifier)
              _getMagnifier(magnifierWidth, magnifierHeight, magnifierYOffset),
            _getButtonBar(buttonBarSize, buttonBarOffset),
          ],
        ),
      ),
    );
  }

  Widget _getPreview(Size size, Offset offset) {
    return Padding(
      padding:
          EdgeInsets.only(top: offset.dy, left: offset.dx, right: offset.dx),
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: FutureBuilder(
            future: _imageFuture,
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return RawImage(
                  image: snapshot.data as ui.Image,
                  fit: BoxFit.contain,
                );
              } else {
                return const SizedBox();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _getBoundingBox(double touchBubbleSize) {
    return (_gotBoundingBox)
        ? SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: <Widget>[
                _getTouchBubble(0, touchBubbleSize),
                _getTouchBubble(1, touchBubbleSize),
                _getTouchBubble(2, touchBubbleSize),
                _getTouchBubble(3, touchBubbleSize),
                CustomPaint(
                  painter: EdgePainter(
                    points: _points,
                    color: const Color.fromARGB(255, 43, 188, 255),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox();
  }

  Widget _getMagnifier(double width, double height, double yOffset) {
    final topEdge = _points[_touchBubbleId!].dy - height / 2;

    if (topEdge + yOffset <= 0) {
      yOffset = -yOffset;
    }
    return Positioned(
      left: _points[_touchBubbleId!].dx - width / 2,
      top: topEdge + yOffset,
      child: RawMagnifier(
        focalPointOffset: Offset(0, -yOffset),
        decoration: const MagnifierDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            side: BorderSide(color: Colors.white, width: 1.25),
          ),
        ),
        size: Size(width, height),
        magnificationScale: 1.5,
      ),
    );
  }

  Widget _getTouchBubble(int id, double size) {
    assert(id < _points.length);

    return Positioned(
      top: _points[id].dy - (size / 2),
      left: _points[id].dx - (size / 2),
      child: TouchBubble(
        id: id,
        size: size,
        onDraggingStarted: _onDraggingStarted,
        onDrag: _onDrag,
        onDraggingStopped: _onDraggingStopped,
      ),
    );
  }

  Widget _getButtonBar(double size, double offset) {
    Size buttonSize = Size(size, size * 0.6);
    return Padding(
      padding: EdgeInsets.only(bottom: offset - buttonSize.height / 2),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                // delete image from cache
                File(widget.imagePath).delete();
                return widget.onBack();
              },
              style: ElevatedButton.styleFrom(
                fixedSize: buttonSize,
                backgroundColor: const Color.fromARGB(255, 102, 102, 102),
                elevation: 5,
                shadowColor: Colors.black,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_points.isEmpty || _previewSize == null) return;

                final relativePoints = List.generate(
                  _points.length,
                  (index) => _points[index] - _previewOffset,
                );

                final boundingBox =
                    BoundingBox.fromPoints(relativePoints, _previewSize!);
                final valueList =
                    SudokuScanner.extractGrid(widget.imagePath, boundingBox)
                        .then((valueList) {
                  // delete image from cache
                  File(widget.imagePath).delete();
                  return valueList;
                });

                widget.showSudoku(valueList);
              },
              style: ElevatedButton.styleFrom(
                fixedSize: buttonSize,
                backgroundColor: (_gotBoundingBox)
                    ? const Color.fromARGB(255, 102, 102, 102)
                    : Colors.grey[800],
                elevation: (_gotBoundingBox) ? 5 : 0,
                shadowColor: Colors.black,
              ),
              child: (_gotBoundingBox)
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                    )
                  : const CircularProgressIndicator(
                      color: Colors.grey,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _onScanComplete(BoundingBox boundingBox) async {
    final image = await _imageFuture;
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());

    await _firstBuildFuture;
    double previewAspectRatio =
        _maxPreviewSize!.height / _maxPreviewSize!.width;
    double imageAspectRatio = imageSize.height / imageSize.width;
    bool fitHeight = (imageAspectRatio > previewAspectRatio);

    final previewWidth = fitHeight
        ? _maxPreviewSize!.height / imageAspectRatio
        : _maxPreviewSize!.width;
    final previewHeight = fitHeight
        ? _maxPreviewSize!.height
        : _maxPreviewSize!.width * imageAspectRatio;

    _previewSize = Size(previewWidth, previewHeight);

    // Adjust for image location.
    _previewOffset = Offset(
      _minPreviewOffset.dx + (_maxPreviewSize!.width - previewWidth) / 2,
      _minPreviewOffset.dy + (_maxPreviewSize!.height - previewHeight) / 2,
    );

    final relativePoints = boundingBox.toPoints(_previewSize!);

    // Absolut locations.
    _points = List.generate(
      relativePoints.length,
      (index) => relativePoints[index] + _previewOffset,
    );

    if (mounted) {
      setState(() {
        _gotBoundingBox = true;
      });
    }
  }

  Offset _clampPosition(Offset position) {
    if (_previewSize == null) return position;
    double clampX = position.dx
        .clamp(_previewOffset.dx, _previewSize!.width + _previewOffset.dx);
    double clampY = position.dy
        .clamp(_previewOffset.dy, _previewSize!.height + _previewOffset.dy);
    return Offset(clampX, clampY);
  }

  void _onDraggingStarted(int id, Offset newPosition) {
    if (mounted) {
      setState(() {
        _points[id] = _clampPosition(newPosition);
        _showMagnifier = true;
        _touchBubbleId = id;
      });
    }
  }

  void _onDrag(int id, Offset newPosition) {
    if (mounted) {
      setState(() {
        _points[id] = _clampPosition(newPosition);
      });
    }
  }

  void _onDraggingStopped() {
    if (mounted) {
      setState(() {
        _showMagnifier = false;
      });
    }
  }

  Future<ui.Image> _getUiImage(String imagePath) {
    return File(imagePath).readAsBytes().then(decodeImageFromList);
  }
}

class EdgePainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  EdgePainter({
    required List<Offset> points,
    required this.color,
  }) : points = [points[0], points[1], points[3], points[2], points[0]];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawPoints(ui.PointMode.polygon, points, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class TouchBubble extends StatelessWidget {
  final int id;
  final double size;
  final void Function(int, Offset) onDraggingStarted;
  final void Function(int, Offset) onDrag;
  final void Function() onDraggingStopped;

  const TouchBubble({
    super.key,
    required this.id,
    required this.size,
    required this.onDraggingStarted,
    required this.onDrag,
    required this.onDraggingStopped,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) => onDraggingStarted(id, details.globalPosition),
      onPanUpdate: (details) => onDrag(id, details.globalPosition),
      onPanCancel: onDraggingStopped,
      onPanEnd: (_) => onDraggingStopped(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 43, 188, 255).withOpacity(0.5),
          borderRadius: BorderRadius.circular(size / 2),
        ),
      ),
    );
  }
}
