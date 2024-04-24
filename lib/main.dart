import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sudoku_scanner/sudoku_scanner.dart';
import 'view_controller.dart';

void main() async {
  // Ensure that plugin services are initialized.
  WidgetsFlutterBinding.ensureInitialized();

  // Show Status and Navigation Bar.
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [
      SystemUiOverlay.top,
      SystemUiOverlay.bottom,
    ],
  );

  // Disable screen rotation.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize SudokuScanner
  await SudokuScanner.init();

  runApp(MaterialApp(
    theme: ThemeData(
      brightness: Brightness.dark,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    home: const ViewController(),
  ));
}
