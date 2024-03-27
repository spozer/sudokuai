// ignore_for_file: camel_case_types

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'bounding_box.dart';

// Structs don't have to be allocated to be passed as value from dart to native c code:
// https://medium.com/dartlang/implementing-structs-by-value-in-dart-ffi-1cb1829d11a9
// Futhermore structs returned from native c code to dart are backed in c heap

final class NativeOffset extends Struct {
  @Double()
  external double x;

  @Double()
  external double y;
}

final class NativeBoundingBox extends Struct {
  external NativeOffset topLeft;
  external NativeOffset topRight;
  external NativeOffset bottomLeft;
  external NativeOffset bottomRight;

  static Pointer<NativeBoundingBox> from(BoundingBox bb) {
    final nativeBoundingBoxPointer = malloc<NativeBoundingBox>();
    nativeBoundingBoxPointer.ref
      ..topLeft.x = bb.topLeft.dx
      ..topLeft.y = bb.topLeft.dy
      ..topRight.x = bb.topRight.dx
      ..topRight.y = bb.topRight.dy
      ..bottomLeft.x = bb.bottomLeft.dx
      ..bottomLeft.y = bb.bottomLeft.dy
      ..bottomRight.x = bb.bottomRight.dx
      ..bottomRight.y = bb.bottomRight.dy;
    return nativeBoundingBoxPointer;
  }
}

// The following typedefs are function layouts needed for bridging between
// native code and dart.

typedef detect_grid_function = Pointer<NativeBoundingBox> Function(Pointer<Utf8> imagePath);
typedef DetectGridFunction = Pointer<NativeBoundingBox> Function(Pointer<Utf8> imagePath);

typedef extract_grid_function = Pointer<Int32> Function(
  Pointer<Utf8> imagePath,
  Pointer<NativeBoundingBox> detectionResult,
);

typedef ExtractGridFunction = Pointer<Int32> Function(
  Pointer<Utf8> imagePath,
  Pointer<NativeBoundingBox> detectionResult,
);

typedef extract_grid_from_roi_function = Pointer<Int32> Function(
  Pointer<Utf8> imagePath,
  Int32 roiSize,
  Int32 roiOffset,
);

typedef ExtractGridFromRoiFunction = Pointer<Int32> Function(
  Pointer<Utf8> imagePath,
  int roiSize,
  int roiOffset,
);

typedef debug_grid_extraction_function = Int8 Function(
  Pointer<Utf8> imagePath,
  Pointer<NativeBoundingBox> detectionResult,
);

typedef DebugGridExtractionFunction = int Function(
  Pointer<Utf8> imagePath,
  Pointer<NativeBoundingBox> detectionResult,
);

typedef debug_function = Int8 Function(Pointer<Utf8> imagePath);
typedef DebugFunction = int Function(Pointer<Utf8> imagePath);

typedef set_model_function = Void Function(Pointer<Utf8> path);
typedef SetModelFunction = void Function(Pointer<Utf8> path);

typedef free_pointer_function = Void Function(Pointer<Int32> pointer);
typedef FreePointerFunction = void Function(Pointer<Int32> pointer);
