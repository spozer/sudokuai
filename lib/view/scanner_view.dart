import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:sudoku_scanner/sudoku_scanner.dart';
import 'package:sudoku_scanner/bounding_box.dart';

class ScannerView extends StatefulWidget {
  final String imagePath;
  final void Function(Future<List<int>> sudokuGrid) showSudoku;
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
  late Future<ui.Image> imageFuture;
  late Future<void> firstBuildFuture;

  List<Offset> points = [];
  Size? maxPreviewSize;
  Offset minPreviewOffset = const Offset(0, 0);
  Size? previewSize;
  Offset previewOffset = const Offset(0, 0);
  bool gotBoundingBox = false;

  @override
  void initState() {
    final firstBuildCompleter = Completer();
    firstBuildFuture = firstBuildCompleter.future;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Indicate that first build was completed.
      firstBuildCompleter.complete();
    });

    imageFuture = _getUiImage(widget.imagePath);

    SudokuScanner.detectGrid(widget.imagePath).then(_onScanComplete);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Padding for preview.
    const previewLeft = 0.0;
    final previewTop = MediaQuery.of(context).viewPadding.top;

    minPreviewOffset = Offset(previewLeft, previewTop);
    maxPreviewSize = Size(screenWidth - 2 * previewLeft, screenHeight * 0.85);

    final buttonBarSize = (screenHeight - maxPreviewSize!.height - previewTop);
    final buttonBarOffset = buttonBarSize / 2;
    final touchBubbleSize = screenHeight * 0.04;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            _getPreview(maxPreviewSize!, minPreviewOffset),
            _getBoundingBox(touchBubbleSize),
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
        child: Container(
          width: size.width,
          height: size.height,
          color: Colors.black,
          child: FutureBuilder(
            future: imageFuture,
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
    return (gotBoundingBox)
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
                    points: points,
                    color: const Color.fromARGB(255, 43, 188, 255),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox();
  }

  Widget _getTouchBubble(int id, double size) {
    assert(id < points.length);

    return Positioned(
      top: points[id].dy - (size / 2),
      left: points[id].dx - (size / 2),
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
              onPressed: widget.onBack,
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
                if (points.isEmpty || previewSize == null) return;

                final relativePoints = List.generate(
                  points.length,
                  (index) => points[index] - previewOffset,
                );

                final boundingBox =
                    BoundingBox.fromPoints(relativePoints, previewSize!);
                final valueList =
                    SudokuScanner.extractGrid(widget.imagePath, boundingBox);

                widget.showSudoku(valueList);
              },
              style: ElevatedButton.styleFrom(
                fixedSize: buttonSize,
                backgroundColor: (gotBoundingBox)
                    ? const Color.fromARGB(255, 102, 102, 102)
                    : Colors.grey[800],
                elevation: (gotBoundingBox) ? 5 : 0,
                shadowColor: Colors.black,
              ),
              child: (gotBoundingBox)
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
    final image = await imageFuture;
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());

    await firstBuildFuture;
    double previewAspectRatio = maxPreviewSize!.height / maxPreviewSize!.width;
    double imageAspectRatio = imageSize.height / imageSize.width;
    bool fitHeight = (imageAspectRatio > previewAspectRatio);

    final previewWidth = fitHeight
        ? maxPreviewSize!.height / imageAspectRatio
        : maxPreviewSize!.width;
    final previewHeight = fitHeight
        ? maxPreviewSize!.height
        : maxPreviewSize!.width * imageAspectRatio;

    previewSize = Size(previewWidth, previewHeight);

    // Adjust for image location.
    previewOffset = Offset(
      minPreviewOffset.dx + (maxPreviewSize!.width - previewWidth) / 2,
      minPreviewOffset.dy + (maxPreviewSize!.height - previewHeight) / 2,
    );

    final relativePoints = boundingBox.toPoints(previewSize!);

    // Absolut locations.
    points = List.generate(
      relativePoints.length,
      (index) => relativePoints[index] + previewOffset,
    );

    if (mounted) {
      setState(() {
        gotBoundingBox = true;
      });
    }
  }

  Offset _clampPosition(Offset position) {
    if (previewSize == null) return position;
    double clampX = position.dx
        .clamp(previewOffset.dx, previewSize!.width + previewOffset.dx);
    double clampY = position.dy
        .clamp(previewOffset.dy, previewSize!.height + previewOffset.dy);
    return Offset(clampX, clampY);
  }

  void _onDraggingStarted(int id, Offset newPosition) {
    if (mounted) {
      setState(() {
        points[id] = _clampPosition(newPosition);
      });
    }
  }

  void _onDrag(int id, Offset newPosition) {
    if (mounted) {
      setState(() {
        points[id] = _clampPosition(newPosition);
      });
    }
  }

  void _onDraggingStopped() {
    if (mounted) setState(() {});
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
