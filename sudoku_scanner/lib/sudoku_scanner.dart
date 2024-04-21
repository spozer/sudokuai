import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Offset;
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'bounding_box.dart';
import 'sudoku_scanner_bindings_generated.dart' as native;

const String _libName = 'sudoku_scanner';

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
      throw UnsupportedError(
          'Unsupported platform: ${Platform.operatingSystem}');
    }

    _bindings = _getBindings();

    _setModel(tfliteModelPath);
  }

  static native.SudokuScannerBindings _getBindings() {
    /// The dynamic library in which the symbols for [SudokuScannerBindings] can be found.
    final DynamicLibrary dylib = DynamicLibrary.open('lib$_libName.so');

    /// The bindings to the native functions in [_dylib].
    final bindings = native.SudokuScannerBindings(dylib);

    return bindings;
  }

  static void _setModel(String path) {
    final pathPointer = path.toNativeUtf8().cast<Char>();
    _bindings.set_model(pathPointer);
    malloc.free(pathPointer);
  }

  static void _freePointer(Pointer pointer) {
    _bindings.free_pointer(pointer.cast<Void>());
  }

  static Future<BoundingBox> detectGrid(String imagePath) async {
    final nativeboundingBoxAdress = await compute((_) {
      // [DynamicLibrary] can't be passed through Isolate Ports, so we need to create new one
      final bindings = _getBindings();

      final imagePathPointer = imagePath.toNativeUtf8().cast<Char>();

      final nativeBoundingBoxPointer = bindings.detect_grid(imagePathPointer);
      malloc.free(imagePathPointer);

      return nativeBoundingBoxPointer.address;
    }, null);

    final nativeBoundingBoxPointer =
        Pointer<native.BoundingBox>.fromAddress(nativeboundingBoxAdress);
    final nbb = nativeBoundingBoxPointer.ref;
    final bb = BoundingBox(
      topLeft: Offset(nbb.top_left.x, nbb.top_left.y),
      topRight: Offset(nbb.top_right.x, nbb.top_right.y),
      bottomLeft: Offset(nbb.bottom_left.x, nbb.bottom_left.y),
      bottomRight: Offset(nbb.bottom_right.x, nbb.bottom_right.y),
    );

    _freePointer(nativeBoundingBoxPointer);

    return bb;
  }

  static Future<Uint8List> extractGrid(
      String imagePath, BoundingBox boundingBox) async {
    final gridArrayAddress = await compute((_) {
      // [DynamicLibrary] can't be passed through Isolate Ports, so we need to create new one
      final bindings = _getBindings();

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

      Pointer<Uint8> gridArray =
          bindings.extract_grid(imagePathPointer, nativeBoundingBoxPointer);

      malloc.free(imagePathPointer);
      malloc.free(nativeBoundingBoxPointer);

      return gridArray.address;
    }, null);

    final gridArray = Pointer<Uint8>.fromAddress(gridArrayAddress);

    final gridList =
        gridArray.asTypedList(81, finalizer: _bindings.free_pointerPtr);

    return gridList;
  }

  static Future<Uint8List> extractGridfromRoi(
      String imagePath, int roiSize, int roiOffset) async {
    final gridArrayAddress = await compute((_) {
      // [DynamicLibrary] can't be passed through Isolate Ports, so we need to create new one
      final bindings = _getBindings();

      final imagePathPointer = imagePath.toNativeUtf8().cast<Char>();

      final gridArray =
          bindings.extract_grid_from_roi(imagePathPointer, roiSize, roiOffset);

      malloc.free(imagePathPointer);

      return gridArray.address;
    }, null);

    final gridArray = Pointer<Uint8>.fromAddress(gridArrayAddress);

    final gridList =
        gridArray.asTypedList(81, finalizer: _bindings.free_pointerPtr);

    return gridList;
  }
}
