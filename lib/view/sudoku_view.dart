import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import '../grid/sudoku_grid.dart';

class SudokuView extends StatefulWidget {
  final Future<Uint8List> valueList;
  final void Function() openCamera;

  const SudokuView({
    super.key,
    required this.valueList,
    required this.openCamera,
  });

  @override
  State<SudokuView> createState() => _SudokuViewState();
}

/// A widget that only displays the extracted sudoku grid (not interactable).
class _SudokuViewState extends State<SudokuView> {
  final _buttonForegroundColor = Colors.white;
  final _buttonPrimaryColor = const Color.fromARGB(255, 102, 102, 102);
  final sudokuGrid = SudokuGrid();
  late Future<void> sudokuGridFuture;
  int? selectedId;

  @override
  void initState() {
    super.initState();

    // Fill in Sudoku grid when extraction is finished.
    sudokuGridFuture = widget.valueList.then(
      (valueList) => sudokuGrid.fillIn(valueList),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen height and width (in logical pixels).
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    // Define widget sizes which are scaled by the screen size.
    final topBarHeight = screenHeight * 0.06;
    final topBarWidth = screenWidth * 0.95;
    final topBarOffset = screenHeight * 0.01;
    final sudokuGridOffset = 2 * topBarOffset + topBarHeight;
    final sudokuGridSize = screenWidth * 0.95;
    var numberKeyboardSize = screenWidth * 0.5;
    var numberKeyboardOffset = screenHeight * 0.05;

    // Check for overflow of number keyboard.
    if (statusBarHeight +
            sudokuGridOffset +
            sudokuGridSize +
            numberKeyboardSize +
            numberKeyboardOffset >
        screenHeight) {
      numberKeyboardSize = screenWidth * 0.45;
      numberKeyboardOffset = screenHeight * 0.02;
    }

    final deleteButtonYOffset =
        numberKeyboardOffset + numberKeyboardSize * 0.04;
    final deleteButtonXOffset = numberKeyboardSize + screenWidth * 0.22;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: ChangeNotifierProvider.value(
          value: sudokuGrid,
          child: Stack(
            children: <Widget>[
              _getTopBar(
                  topBarHeight, topBarWidth, statusBarHeight + topBarOffset),
              _getSudokuGrid(
                  sudokuGridSize, statusBarHeight + sudokuGridOffset),
              _getNumberKeyboard(numberKeyboardSize, numberKeyboardOffset),
              _getActionButtons(deleteButtonYOffset, deleteButtonXOffset),
            ],
          ),
        ),
      ),
    );
  }

  // Creates the top bar, which contains a button to take a new image and a
  // button to solve the currently displayed Sudoku.
  Widget _getTopBar(double height, double width, double offset) {
    final buttonStyle = ElevatedButton.styleFrom(
      elevation: 5,
      foregroundColor: _buttonForegroundColor,
      backgroundColor: _buttonPrimaryColor,
      shadowColor: Colors.black,
    );
    return Padding(
      padding: EdgeInsets.only(top: offset),
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: height,
          width: width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                style: buttonStyle,
                onPressed: () => widget.openCamera(),
                icon: const Icon(Icons.camera_alt),
                label: const Text("New"),
              ),
              Selector<SudokuGrid, BoardStatus>(
                  selector: (_, sudokuGrid) => sudokuGrid.getBoardStatus(),
                  builder: (_, boardStatus, __) {
                    debugPrint("rebuild Solved info text");
                    Color? color;
                    IconData icon;
                    String text;

                    switch (boardStatus) {
                      case BoardStatus.inProgress:
                        return const SizedBox();
                      case BoardStatus.solved:
                        color = Colors.green[600];
                        icon = Icons.check;
                        text = " Solved";
                        break;
                      case BoardStatus.hasErrors:
                        color = Colors.red[600];
                        icon = Icons.close;
                        text = " Wrong";
                        break;
                    }
                    return Container(
                      padding: const EdgeInsets.all(7.0),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[Icon(icon), Text(text)],
                      ),
                    );
                  }),
              ElevatedButton(
                style: buttonStyle,
                // TODO: solve Sudoku grid
                onPressed: () => sudokuGrid.solve(),
                child: const Text("Solution"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Creates the Sudoku grid widget.
  Widget _getSudokuGrid(double size, double offset) {
    return Padding(
      padding: EdgeInsets.only(top: offset),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(size * 0.02),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(10)),
              // border: Border.all(),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: FutureBuilder(
              future: sudokuGridFuture,
              builder: (_, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return SudokuGridWidget(size: size * 0.96);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            )),
      ),
    );
  }

  /// Creates the number keyboard.
  Widget _getNumberKeyboard(double size, double offset) {
    return Padding(
      padding: EdgeInsets.only(bottom: offset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: size,
          height: size,
          child: GridView.count(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            primary: false,
            addAutomaticKeepAlives: false,
            crossAxisCount: 3,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
            children: List.generate(9, (index) {
              int value = index + 1;
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 5,
                  foregroundColor: _buttonForegroundColor,
                  backgroundColor: _buttonPrimaryColor,
                  shadowColor: Colors.black,
                ),
                onPressed: () => sudokuGrid.writeSelected(value),
                child: Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 30.0,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Creates action buttons.
  Widget _getActionButtons(double yOffset, double xOffset) {
    return Padding(
      padding: EdgeInsets.only(bottom: yOffset, left: xOffset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            InkResponse(
              onTap: () => sudokuGrid.undo(),
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              child: Selector<SudokuGrid, bool>(
                selector: (_, sudokuGrid) => sudokuGrid.hasUndoHistory(),
                builder: (_, hasUndoHistory, __) {
                  debugPrint("rebuild of undo button color");
                  return Icon(
                    Icons.undo,
                    size: 45.0,
                    color: (hasUndoHistory) ? Colors.white : Colors.grey,
                  );
                },
              ),
            ),
            const SizedBox(height: 90),
            InkResponse(
              onTap: () => sudokuGrid.writeSelected(0),
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              child: const Icon(
                Icons.backspace,
                size: 40.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SudokuGridWidget extends StatelessWidget {
  final double size;

  const SudokuGridWidget({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    debugPrint("rebuild whole sudoku grid");
    return FittedBox(
      fit: BoxFit.contain,
      child: Table(
        defaultColumnWidth: FixedColumnWidth(size / 9),
        border: const TableBorder(
          left: BorderSide(width: 3.0, color: Colors.black),
          top: BorderSide(width: 3.0, color: Colors.black),
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: _getTableRows(),
      ),
    );
  }

  List<TableRow> _getTableRows() {
    return List.generate(9, (int rowNumber) {
      return TableRow(children: _getRow(rowNumber));
    });
  }

  List<Widget> _getRow(int rowNumber) {
    return List.generate(9, (int colNumber) {
      return AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                width: (colNumber % 3 == 2) ? 3.0 : 1.0,
                color: Colors.black,
              ),
              bottom: BorderSide(
                width: (rowNumber % 3 == 2) ? 3.0 : 1.0,
                color: Colors.black,
              ),
            ),
          ),
          child: SudokuCellWidget(
            row: rowNumber,
            col: colNumber,
          ),
        ),
      );
    });
  }
}

class SudokuCellWidget extends StatelessWidget {
  final int row;
  final int col;

  const SudokuCellWidget({
    super.key,
    required this.row,
    required this.col,
  });

  @override
  Widget build(BuildContext context) {
    final sudokuGrid = context.read<SudokuGrid>();
    const fontSize = 23.0;
    debugPrint("whole rebuild of ($row, $col)");
    return InkResponse(
      onTap: () => sudokuGrid.select(row, col),
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Selector<SudokuGrid, Tuple2<int, CellStatus>>(
        selector: (_, sudokuGrid) => Tuple2(
          sudokuGrid.getValue(row, col),
          sudokuGrid.getCellStatus(row, col),
        ),
        builder: (_, data, child) {
          debugPrint('container rebuild of ($row, $col)');
          return Container(
            color: _getColor(data.item2),
            child: child ??
                ((data.item1 != 0)
                    ? Center(
                        child: Text(
                          data.item1.toString(),
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontSize: fontSize,
                          ),
                        ),
                      )
                    : const SizedBox()),
          );
        },
        child: (!sudokuGrid.isModifiable(row, col))
            ? Center(
                child: Text(
                  sudokuGrid.getValue(row, col).toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  /// Get background color of grid cell based on the currently selected
  /// grid cell.
  Color _getColor(CellStatus status) {
    const defaultBackground = Colors.transparent;
    const selectedBackground = Color.fromARGB(100, 43, 188, 255);
    const unitBackground = Color.fromARGB(100, 150, 150, 150);
    const sameValueBackground = Color.fromARGB(100, 200, 0, 0);

    switch (status) {
      case CellStatus.none:
        return defaultBackground;
      case CellStatus.selected:
        return selectedBackground;
      case CellStatus.inUnit:
        return unitBackground;
      case CellStatus.sameValue:
        return sameValueBackground;
      default:
        return defaultBackground;
    }
  }
}
