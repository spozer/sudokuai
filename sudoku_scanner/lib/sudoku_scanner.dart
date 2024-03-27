import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'sudoku_scanner_bindings.dart' as bridge;
import 'bounding_box.dart';

// TODO: use Isolate.run() instead of compute() for longer tasks

class SudokuScanner {
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
      var tfliteModel = await rootBundle.load('sudoku_scanner/assets/model.tflite');

      File(tfliteModelPath).writeAsBytes(tfliteModel.buffer.asUint8List(
        tfliteModel.offsetInBytes,
        tfliteModel.lengthInBytes,
      ));
    }
    return compute(bridge.setModel, tfliteModelPath);
  }

  static Future<BoundingBox> detectGrid(String imagePath) {
    return compute(bridge.detectGrid, imagePath);
  }

  static Future<List<int>> extractGrid(String imagePath, BoundingBox boundingBox) {
    return compute((_) => bridge.extractGrid(imagePath, boundingBox), null);
  }

  static Future<List<int>> extractGridfromRoi(String imagePath, int roiSize, int roiOffset) async {
    return compute((_) => bridge.extractGridfromRoi(imagePath, roiSize, roiOffset), null);
  }

  static Future<bool> debugGridDetection(String imagePath) {
    return compute(bridge.debugGridDetection, imagePath);
  }
}
