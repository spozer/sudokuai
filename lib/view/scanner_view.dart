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
    final topPadding = MediaQuery.of(context).viewPadding.top;
    final previewLeft = 0.07 * screenWidth;
    final previewTop = topPadding + 0.02 * screenHeight;

    _minPreviewOffset = Offset(previewLeft, previewTop);
    _maxPreviewSize = Size(screenWidth - 2 * previewLeft, screenHeight * 0.83);

    final touchBubbleSize = screenHeight * 0.04;
    final magnifierWidth = screenWidth * 0.19;
    final magnifierHeight = magnifierWidth / 1.2;
    final magnifierYOffset = -magnifierHeight / 2 - touchBubbleSize;
    final buttonBarSize = screenHeight - _maxPreviewSize!.height - previewTop;
    final buttonBarOffset = buttonBarSize / 2;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            _getPreview(_maxPreviewSize!, _minPreviewOffset),
            if (_gotBoundingBox) _getBoundingBox(touchBubbleSize),
            if (_showMagnifier)
              _getMagnifier(magnifierWidth, magnifierHeight, magnifierYOffset,
                  topPadding),
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
    return SizedBox(
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
    );
  }

  Widget _getMagnifier(
      double width, double height, double yOffset, double topPadding) {
    final topEdge = _points[_touchBubbleId!].dy - height / 2;

    if (topEdge + yOffset <= topPadding) {
      yOffset = -yOffset;
    }

    double scale = 1.5;

    double transX =
        _points[_touchBubbleId!].dx - _previewOffset.dx - width / 2 / scale;
    double transY =
        _points[_touchBubbleId!].dy - _previewOffset.dy - height / 2 / scale;

    final Matrix4 cropMatrix = Matrix4.identity()
      ..scale(scale, scale)
      ..translate(-transX, -transY);

    return Positioned(
        left: _points[_touchBubbleId!].dx - width / 2,
        top: topEdge + yOffset,
        child: Stack(children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.white, width: 1.25),
              borderRadius: BorderRadius.circular(width / 10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10.0,
                  offset: const Offset(0, 3.0),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(width / 10 - 1.25),
              child: FittedBox(
                alignment: Alignment.topLeft,
                fit: BoxFit.none,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.matrix(cropMatrix.storage),
                  child: FutureBuilder(
                    future: _imageFuture,
                    builder: (_, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return RawImage(
                          image: snapshot.data as ui.Image,
                          fit: BoxFit.contain,
                          height: _previewSize!.height,
                          width: _previewSize!.width,
                        );
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          CustomPaint(
            size: Size(width, height),
            painter: const CrosshairPainter(),
          )
        ]));
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

class CrosshairPainter extends CustomPainter {
  const CrosshairPainter({
    this.color = Colors.white,
    this.strokeWidth = 2,
  });

  final double strokeWidth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    Paint crossPaint = Paint()
      ..strokeWidth = strokeWidth
      ..color = color
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.difference;

    Offset center = Offset(size.width, size.height) / 2;
    double crossSize = size.longestSide * 0.15;

    Path crosshair = Path();

    crosshair.moveTo(center.dx - crossSize, center.dy);
    crosshair.lineTo(center.dx + crossSize, center.dy);
    crosshair.moveTo(center.dx, center.dy - crossSize);
    crosshair.lineTo(center.dx, center.dy + crossSize);

    canvas.drawPath(crosshair, crossPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
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
