/// Bridge between Dart and native C++ code.
///
/// Defines all public functions of the SudokuScanner C++ library and
/// makes them callable through Dart's Foreign Function Interface (FFI).

// Example at https://github.com/dart-lang/samples/blob/master/ffi/structs/structs.dart

import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'native_functions.dart';
import 'bounding_box.dart';

/// Bridge for [detect_grid].
BoundingBox detectGrid(String imagePath) {
  final nativeSudokuScanner = DynamicLibrary.open("libsudoku_scanner.so");
  final nativeDetectGrid = nativeSudokuScanner.lookupFunction<detect_grid_function, DetectGridFunction>("detect_grid");

  // Creates a char pointer.
  final imagePathPointer = imagePath.toNativeUtf8();

  final nativeBoundingBoxPointer = nativeDetectGrid(imagePathPointer);

  final boundingBox = BoundingBox.from(nativeBoundingBoxPointer.ref);

  // Need to free memory.
  malloc.free(imagePathPointer);
  malloc.free(nativeBoundingBoxPointer);

  return boundingBox;
}

/// Bridge for [extract_grid].
List<int> extractGrid(String imagePath, BoundingBox boundingBox) {
  final nativeSudokuScanner = DynamicLibrary.open("libsudoku_scanner.so");
  final nativeExtractGrid =
      nativeSudokuScanner.lookupFunction<extract_grid_function, ExtractGridFunction>("extract_grid");

  // Creates a char pointer and Native Bounding Box pointer.
  final imagePathPointer = imagePath.toNativeUtf8();
  final nativeBoundingBoxPointer = NativeBoundingBox.from(boundingBox);

  Pointer<Int32> gridArray = nativeExtractGrid(imagePathPointer, nativeBoundingBoxPointer);

  // It is not clear, whether asTypeList gets handled from GC or not:
  // https://github.com/dart-lang/ffi/issues/22
  // https://github.com/dart-lang/sdk/issues/45508
  // Either way it is probably better to free c heap in native code.
  List<int> gridList = List.from(gridArray.asTypedList(81), growable: false);

  // Free memory.
  malloc.free(imagePathPointer);
  malloc.free(nativeBoundingBoxPointer);
  _freePointer(gridArray);

  return gridList;
}

/// Bridge for [extract_grid_from_roi].
List<int> extractGridfromRoi(String imagePath, int roiSize, int roiOffset) {
  final nativeSudokuScanner = DynamicLibrary.open("libsudoku_scanner.so");
  final nativeExtractGridfromRoi = nativeSudokuScanner
      .lookupFunction<extract_grid_from_roi_function, ExtractGridFromRoiFunction>("extract_grid_from_roi");

  // creates a char pointer
  final imagePathPointer = imagePath.toNativeUtf8();

  Pointer<Int32> gridArray = nativeExtractGridfromRoi(imagePathPointer, roiSize, roiOffset);

  // It is not clear, whether asTypeList gets handled from GC or not:
  // https://github.com/dart-lang/ffi/issues/22
  // https://github.com/dart-lang/sdk/issues/45508
  // Either way it is probably better to free c heap in native code.
  List<int> gridList = List.from(gridArray.asTypedList(81), growable: false);

  // Free memory.
  malloc.free(imagePathPointer);
  _freePointer(gridArray);

  return gridList;
}

/// Bridge for [debug_grid_detection].
Future<bool> debugGridDetection(String imagePath) async {
  final nativeSudokuScanner = DynamicLibrary.open("libsudoku_scanner.so");
  final nativeDebugGridDetection =
      nativeSudokuScanner.lookupFunction<debug_function, DebugFunction>("debug_grid_detection");

  // Creates a char pointer.
  final imagePathPointer = imagePath.toNativeUtf8();

  int debugImage = nativeDebugGridDetection(imagePathPointer);

  // Free memory.
  malloc.free(imagePathPointer);

  return debugImage == 1;
}

/// Bridge for [debug_grid_extraction].
Future<bool> debugGridExtraction(String imagePath, BoundingBox boundingBox) async {
  final nativeSudokuScanner = DynamicLibrary.open("libsudoku_scanner.so");
  final nativeDebugGridExtraction = nativeSudokuScanner
      .lookupFunction<debug_grid_extraction_function, DebugGridExtractionFunction>("debug_grid_extraction");

  // Creates a char pointer.
  final imagePathPointer = imagePath.toNativeUtf8();
  final nativeBoundingBoxPointer = NativeBoundingBox.from(boundingBox);

  int debugImage = nativeDebugGridExtraction(imagePathPointer, nativeBoundingBoxPointer);

  // Free memory.
  malloc.free(imagePathPointer);

  return debugImage == 1;
}

/// Bridge for [set_model].
/// This function is only needed for initialization.
void setModel(String imagePath) {
  final nativeSudokuScanner = DynamicLibrary.open("libsudoku_scanner.so");
  final nativeSetModel = nativeSudokuScanner.lookupFunction<set_model_function, SetModelFunction>("set_model");

  // Creates a char pointer.
  final imagePathPointer = imagePath.toNativeUtf8();

  nativeSetModel(imagePathPointer);

  // Free memory.
  malloc.free(imagePathPointer);
}

/// Bridge for [free_pointer].
/// Free a pointer on native heap.
void _freePointer(Pointer<Int32> pointer) {
  final nativeSudokuScanner = DynamicLibrary.open("libsudoku_scanner.so");
  final nativeFreePointer =
      nativeSudokuScanner.lookupFunction<free_pointer_function, FreePointerFunction>("free_pointer");

  nativeFreePointer(pointer);
}
