import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:tuple/tuple.dart';

enum BoardStatus {
  inProgress,
  solved,
  hasErrors,
}

class SudokuGrid extends ChangeNotifier {
  final List<SudokuGridBlock> _blockList;
  final _undoQueue = Queue<Tuple4<int, int, int, int>>();

  List<List<SudokuGridCell>>? _cellList;
  SudokuGridCell? _selectedCell;
  int _emptyCount = 0;
  BoardStatus _status = BoardStatus.inProgress;

  SudokuGrid()
      : _blockList = List.generate(9, (index) => SudokuGridBlock(index),
            growable: false);

  void fillIn(Uint8List valueList) {
    _cellList = List.generate(9, (index) {
      final row = index;
      return List.generate(9, (index) {
        final col = index;
        final id = row * 9 + col;
        final value = valueList[id];
        if (value == 0) _emptyCount++;
        return SudokuGridCell(id, row, col, value);
      }, growable: false);
    });
  }

  int getValue(int row, int col) {
    assert(_cellList != null);
    return _cellList![row][col].value;
  }

  CellStatus getCellStatus(int row, int col) {
    assert(_cellList != null);
    return _cellList![row][col].status;
  }

  bool isModifiable(int row, int col) {
    assert(_cellList != null);
    return _cellList![row][col].isModifiable;
  }

  BoardStatus getBoardStatus() {
    return _status;
  }

  bool hasUndoHistory() {
    return _undoQueue.isNotEmpty;
  }

  void select(int row, int col, {bool update = false}) {
    if (_cellList == null) return;
    if (!update && _cellList![row][col].id == _selectedCell?.id) return;

    final cell = _cellList![row][col];
    final oldSelectedCell = _selectedCell;

    // Notify old cell and its unit of unselect.
    if (oldSelectedCell != null) {
      oldSelectedCell.status = CellStatus.none;
      _actOnUnits(
        oldSelectedCell,
        (uCell) {
          uCell.status = CellStatus.none;
          return true;
        },
        onlyPeers: true,
      );
    }
    // Notify new cell and its unit of select.
    cell.status = CellStatus.selected;
    _actOnUnits(
      cell,
      (uCell) {
        uCell.status = (uCell.value != 0 && uCell.value == cell.value)
            ? CellStatus.sameValue
            : CellStatus.inUnit;
        return true;
      },
      onlyPeers: true,
    );

    _selectedCell = cell;
    notifyListeners();
  }

  void writeSelected(int value) {
    if (_selectedCell == null ||
        !_selectedCell!.isModifiable ||
        _selectedCell!.value == value) return;

    int dEmptyCount = 0;

    if (_selectedCell!.value == 0) {
      _emptyCount--;
      dEmptyCount = 1;
    } else if (value == 0) {
      _emptyCount++;
      dEmptyCount = -1;
    }

    _undoQueue.addLast(Tuple4<int, int, int, int>(
      _selectedCell!.row,
      _selectedCell!.col,
      _selectedCell!.value,
      dEmptyCount,
    ));

    _selectedCell!.value = value;
    _actOnUnits(
      _selectedCell!,
      (uCell) {
        uCell.status = (value != 0 && uCell.value == value)
            ? CellStatus.sameValue
            : CellStatus.inUnit;
        return true;
      },
      onlyPeers: true,
    );

    _checkWinCondition();
    notifyListeners();
  }

  void undo() {
    assert(_cellList != null);
    if (_undoQueue.isEmpty) return;

    final lastAction = _undoQueue.removeLast();
    final row = lastAction.item1;
    final col = lastAction.item2;
    final value = lastAction.item3;
    final dEmptyCount = lastAction.item4;

    _cellList![row][col].value = value;
    _emptyCount += dEmptyCount;

    _checkWinCondition();
    select(row, col, update: true);
  }

  /// Based on http://norvig.com/sudoku.html
  bool solve() {
    if (_cellList == null) return false;
    // Assign static values.
    // TODO: maybe do this in constructor of SudokuGrid?
    for (final row in _cellList!) {
      for (final cell in row.where((cell) => !cell.isModifiable)) {
        if (!_assign(cell, cell.value, [])) return false;
      }
    }

    if (!_search()) return false;

    // Change actual values of Sudoku grid.
    for (final row in _cellList!) {
      for (final cell in row) {
        cell.value = cell.possibilities.first;
      }
    }

    _emptyCount = 0;
    _status = BoardStatus.solved;
    _undoQueue.clear();

    if (_selectedCell != null) {
      select(_selectedCell!.row, _selectedCell!.col, update: true);
    } else {
      notifyListeners();
    }

    return true;
  }

  bool _assign(
      SudokuGridCell cell, int value, List<SudokuGridCell>? backtrackList) {
    final otherValues = Set<int>.from(cell.possibilities);
    otherValues.remove(value);

    return otherValues.every((value) => _eliminate(cell, value, backtrackList));
  }

  bool _eliminate(
      SudokuGridCell cell, int value, List<SudokuGridCell>? backtrackList) {
    bool doBacktrack = backtrackList != null;
    // Already eliminated.
    if (!cell.eliminatePosibility(value, backtrack: doBacktrack)) return true;

    if (doBacktrack) backtrackList.add(cell);

    if (cell.possibilities.isEmpty) {
      // Contradiction: removed last value.
      return false;
    } else if (cell.possibilities.length == 1) {
      final possibleValues = cell.possibilities;

      if (!possibleValues.every((value) => _actOnUnits(
            cell,
            (cell) => _eliminate(cell, value, backtrackList),
            onlyPeers: true,
          ))) {
        return false;
      }
    }

    // Check if value can only be asigned to one cell.
    List<SudokuGridCell> valuePlaces = [];
    _actOnUnits(cell, (cell) {
      if (cell.possibilities.contains(value)) valuePlaces.add(cell);
      return true;
    });

    if (valuePlaces.isEmpty) {
      // Contradiction: no place for this value.
      return false;
    } else if (valuePlaces.length == 1) {
      if (!_assign(valuePlaces[0], value, backtrackList)) return false;
    }
    return true;
  }

  bool _search() {
    assert(_cellList != null);
    // Check if Sudoku already solved.
    if (_cellList!
        .every((row) => row.every((cell) => cell.possibilities.length == 1))) {
      return true;
    }

    // Get cell with fewest possibilities.
    SudokuGridCell? nextCell;
    for (final row in _cellList!) {
      for (final cell in row.where((cell) => cell.possibilities.length > 1)) {
        if (nextCell == null ||
            cell.possibilities.length < nextCell.possibilities.length) {
          nextCell = cell;
        }
      }
    }

    // At least one cell has empty possibilities.
    if (nextCell == null) return false;

    final possibilities = Set<int>.from(nextCell.possibilities);

    // Try to assign one of the possible values.
    for (final value in possibilities) {
      List<SudokuGridCell> backtrackList = [];
      if (_assign(nextCell, value, backtrackList) && _search()) return true;

      for (final cell in backtrackList) {
        cell.backtrackPosibilities();
      }
    }
    // None of the possible assignments worked.
    return false;
  }

  bool _actOnUnits(
      SudokuGridCell cell, bool Function(SudokuGridCell cell) action,
      {bool onlyPeers = false}) {
    assert(_cellList != null);
    final row = cell.row;
    final col = cell.col;
    final blockId = cell.blockId;

    // Run action on row unit.
    for (int uCol = 0; uCol < 9; ++uCol) {
      if (onlyPeers && uCol == col) continue;
      if (!action(_cellList![row][uCol])) return false;
    }

    // Run action on column unit.
    for (int uRow = 0; uRow < 9; ++uRow) {
      if (onlyPeers && uRow == row) continue;
      if (!action(_cellList![uRow][col])) return false;
    }

    // Run action on block unit.
    final block = _blockList[blockId];
    for (final bRow in block.rows) {
      for (final bCol in block.cols) {
        if ((bRow == row) != (bCol == col)) continue;
        if (onlyPeers && bRow == row && bCol == col) continue;
        if (!action(_cellList![bRow][bCol])) return false;
      }
    }
    return true;
  }

  bool _checkWinCondition() {
    assert(_cellList != null);
    if (_emptyCount != 0) {
      _status = BoardStatus.inProgress;
      return false;
    }

    for (int index = 0; index < 9; ++index) {
      final digits = <int>{};
      // Check row unit.
      if (!_cellList![index].every((cell) => digits.add(cell.value))) {
        if (kDebugMode) debugPrint("Duplicate in row: $index");
        _status = BoardStatus.hasErrors;
        return false;
      }

      digits.clear();
      // Check column unit.
      for (int cRow = 0; cRow < 9; ++cRow) {
        if (!digits.add(_cellList![cRow][index].value)) {
          if (kDebugMode) debugPrint("Duplicate in column: $index");
          _status = BoardStatus.hasErrors;
          return false;
        }
      }

      digits.clear();
      // Check block unit.
      for (final bRow in _blockList[index].rows) {
        for (final bCol in _blockList[index].cols) {
          if (!digits.add(_cellList![bRow][bCol].value)) {
            if (kDebugMode) debugPrint("Duplicate in block: $index");
            _status = BoardStatus.hasErrors;
            return false;
          }
        }
      }
    }
    _status = BoardStatus.solved;
    return true;
  }
}

class SudokuGridBlock {
  final int _id;
  final List<int> _rows;
  final List<int> _cols;

  SudokuGridBlock(this._id)
      : _rows = List.generate(3, (index) => (_id ~/ 3) * 3 + index),
        _cols = List.generate(3, (index) => (_id % 3) * 3 + index);

  int get id => _id;
  List<int> get rows => _rows;
  List<int> get cols => _cols;
}

enum CellStatus {
  none,
  selected,
  inUnit,
  sameValue,
}

/// Defines a Sudoku grid cell.
///
/// Holds [id], [row, col] and [value].
class SudokuGridCell {
  final int _id;
  final int _row;
  final int _col;
  final int _blockId;
  final bool _isModifiable;
  final _backtrackQueue = Queue<int>();
  final Set<int> _possibilities = {1, 2, 3, 4, 5, 6, 7, 8, 9};
  int _value;
  CellStatus status = CellStatus.none;

  SudokuGridCell(this._id, this._row, this._col, this._value)
      : _isModifiable = (_value == 0),
        _blockId = (_row ~/ 3) * 3 + _col ~/ 3;

  bool eliminatePosibility(int value, {bool backtrack = true}) {
    if (!_possibilities.remove(value)) return false;

    if (backtrack) _backtrackQueue.addLast(value);
    return true;
  }

  void backtrackPosibilities() {
    assert(_backtrackQueue.isNotEmpty);
    _possibilities.add(_backtrackQueue.removeLast());
  }

  int get id => _id;
  int get row => _row;
  int get col => _col;
  int get blockId => _blockId;
  bool get isModifiable => _isModifiable;
  int get value => _value;
  Set<int> get possibilities => _possibilities;

  set value(int value) {
    assert(0 <= value && value < 10);
    if (!isModifiable) return;
    _value = value;
  }
}
