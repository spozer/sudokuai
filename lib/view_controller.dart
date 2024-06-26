import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'view/camera_view.dart';
import 'view/scanner_view.dart';
import 'view/sudoku_view.dart';
import 'package:sudoku_scanner/sudoku_scanner.dart';

class ViewController extends StatefulWidget {
  const ViewController({super.key});

  @override
  State<ViewController> createState() => _ViewControllerState();
}

enum ViewName {
  camera,
  scanner,
  sudoku,
}

class View {
  ViewName name;
  List<dynamic> args;

  View(this.name, {this.args = const []});
}

class _ViewControllerState extends State<ViewController> {
  // Default view is camera.
  View currentView = View(ViewName.camera);

  @override
  Widget build(BuildContext context) {
    switch (currentView.name) {
      case ViewName.camera:
        return CameraView(scanImage: _scanImage);
      case ViewName.scanner:
        final String imagePath = currentView.args[0];
        return ScannerView(
          imagePath: imagePath,
          showSudoku: _showSudoku,
          onBack: _openCamera,
        );
      case ViewName.sudoku:
        final Future<Uint8List> valueList = currentView.args[0];
        return SudokuView(
          valueList: valueList,
          openCamera: _openCamera,
        );
    }
  }

  void _setView(View newView) {
    if (mounted) {
      setState(() {
        currentView = newView;
      });
    }
  }

  // Callback
  void _openCamera() => _setView(View(ViewName.camera));

  void _scanImage(String imagePath, {int? roiSize, int? roiOffset}) {
    if (roiSize != null && roiOffset != null) {
      _setView(View(ViewName.sudoku, args: [
        SudokuScanner.extractGridfromRoi(imagePath, roiSize, roiOffset)
            .then((valueList) {
          // delete image from cache
          File(imagePath).delete();
          return valueList;
        }),
      ]));
    } else {
      _setView(View(ViewName.scanner, args: [
        imagePath,
      ]));
    }
  }

  void _showSudoku(Future<Uint8List> sudokuGrid) =>
      _setView(View(ViewName.sudoku, args: [sudokuGrid]));
}
