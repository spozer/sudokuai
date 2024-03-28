import 'dart:ffi';
import 'dart:io';
import 'dart:ui' show Offset;
import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
// import 'sudoku_scanner_bindings.dart' as bridge;
import 'bounding_box.dart';
import 'sudoku_scanner_bindings_generated.dart' as native;

// TODO: use Isolate.run() instead of compute() for longer tasks

class SudokuScanner {
  static late final native.SudokuScannerBindings _bindings;

  /// Initializes and loads the tensorflow model.
  ///
  /// The neural network model - used for classifying printed digits - is
  /// encoded in the app package. Because of this native C++ Tensorflow
  /// cannot read the model straight from assets. Therefore we read and
  /// decode the model first and save it then to the app's folder. This only
  /// needs to be done once.
  static Future<void> init() async {
    final extDir = await getExternalStorageDirectory();
    final tfliteModelPath = "${extDir!.path}/model.tflite";

    if (!await File(tfliteModelPath).exists()) {
      var tfliteModel =
          await rootBundle.load('packages/sudoku_scanner/assets/model.tflite');

      File(tfliteModelPath).writeAsBytes(tfliteModel.buffer.asUint8List(
        tfliteModel.offsetInBytes,
        tfliteModel.lengthInBytes,
      ));
    }

    if (!Platform.isAndroid) {
      throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
    }

    /// The dynamic library in which the symbols for [SudokuScannerBindings] can be found.
    final DynamicLibrary dylib = DynamicLibrary.open('libsudoku_scanner.so');

    /// The bindings to the native functions in [_dylib].
    _bindings = native.SudokuScannerBindings(dylib);

    _setModel(tfliteModelPath);
  }

  static Future<void> _setModel(String path) async {
    final pathPointer = path.toNativeUtf8().cast<Char>();
    _bindings.set_model(pathPointer);
    malloc.free(pathPointer);
  }

  static void _freePointer(Pointer<Int32> pointer) {
    _bindings.free_pointer(pointer.cast<Int>());
  }

  static Future<BoundingBox> detectGrid(String imagePath) async {
    final imagePathPointer = imagePath.toNativeUtf8().cast<Char>();

    final nativeBoundingBoxPointer = _bindings.detect_grid(imagePathPointer);
    final nbb = nativeBoundingBoxPointer.ref;
    final bb = BoundingBox(
      topLeft: Offset(nbb.top_left.x, nbb.top_left.y),
      topRight: Offset(nbb.top_right.x, nbb.top_right.y),
      bottomLeft: Offset(nbb.bottom_left.x, nbb.bottom_left.y),
      bottomRight: Offset(nbb.bottom_right.x, nbb.bottom_right.y),
    );

    malloc.free(imagePathPointer);
    malloc.free(nativeBoundingBoxPointer);

    return bb;
  }

  static Future<List<int>> extractGrid(
      String imagePath, BoundingBox boundingBox) async {
    final imagePathPointer = imagePath.toNativeUtf8().cast<Char>();
    final nativeBoundingBoxPointer = malloc<native.BoundingBox>();

    nativeBoundingBoxPointer.ref
      ..top_left.x = boundingBox.topLeft.dx
      ..top_left.y = boundingBox.topLeft.dy
      ..top_right.x = boundingBox.topRight.dx
      ..top_right.y = boundingBox.topRight.dy
      ..bottom_left.x = boundingBox.bottomLeft.dx
      ..bottom_left.y = boundingBox.bottomLeft.dy
      ..bottom_right.x = boundingBox.bottomRight.dx
      ..bottom_right.y = boundingBox.bottomRight.dy;

    Pointer<Int32> gridArray = _bindings
        .extract_grid(imagePathPointer, nativeBoundingBoxPointer)
        .cast<Int32>();

    // It is not clear, whether asTypeList gets handled from GC or not:
    // https://github.com/dart-lang/ffi/issues/22
    // https://github.com/dart-lang/sdk/issues/45508
    // Either way it is probably better to free c heap in native code.
    List<int> gridList = List.from(gridArray.asTypedList(81), growable: false);

    malloc.free(imagePathPointer);
    malloc.free(nativeBoundingBoxPointer);
    _freePointer(gridArray);

    return gridList;
  }

  static Future<List<int>> extractGridfromRoi(
      String imagePath, int roiSize, int roiOffset) async {
    final imagePathPointer = imagePath.toNativeUtf8().cast<Char>();

    Pointer<Int32> gridArray = _bindings
        .extract_grid_from_roi(imagePathPointer, roiSize, roiOffset)
        .cast<Int32>();

    // It is not clear, whether asTypeList gets handled from GC or not:
    // https://github.com/dart-lang/ffi/issues/22
    // https://github.com/dart-lang/sdk/issues/45508
    // Either way it is probably better to free c heap in native code.
    List<int> gridList = List.from(gridArray.asTypedList(81), growable: false);

    malloc.free(imagePathPointer);
    _freePointer(gridArray);

    return gridList;
  }
}
