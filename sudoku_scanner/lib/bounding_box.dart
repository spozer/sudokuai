import 'dart:ui';

class BoundingBox {
  Offset topLeft;
  Offset topRight;
  Offset bottomLeft;
  Offset bottomRight;

  BoundingBox({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  /// Expects the list ordered as [topLeft, topRight, bottomLeft, bottomRight]
  factory BoundingBox.fromPoints(List<Offset> points, Size size) {
    assert(points.length == 4);
    assert(size.width != 0 && size.height != 0);

    final scaleX = 1 / size.width;
    final scaleY = 1 / size.height;

    return BoundingBox(
      topLeft: _scaleOffset(points[0], scaleX, scaleY),
      topRight: _scaleOffset(points[1], scaleX, scaleY),
      bottomLeft: _scaleOffset(points[2], scaleX, scaleY),
      bottomRight: _scaleOffset(points[3], scaleX, scaleY),
    );
  }

  List<Offset> toPoints(Size size) {
    final scaleX = size.width;
    final scaleY = size.height;

    return [
      _scaleOffset(topLeft, scaleX, scaleY),
      _scaleOffset(topRight, scaleX, scaleY),
      _scaleOffset(bottomLeft, scaleX, scaleY),
      _scaleOffset(bottomRight, scaleX, scaleY),
    ];
  }

  static Offset _scaleOffset(Offset offset, double scaleX, double scaleY) {
    return Offset(offset.dx * scaleX, offset.dy * scaleY);
  }
}
