import 'dart:collection';
import 'dart:math';

enum MineAction { revealed, flagged, won, hit, ignored }

/// Classic minefield deduction with a guaranteed clear first tap.
class MinefieldEngine {
  MinefieldEngine._(this.level, this.mineCount, this._random) {
    _placeMines();
    _calculateClues();
  }

  static const int side = 8;
  static const int cellCount = side * side;
  final int level;
  final int mineCount;
  final Random _random;
  final Set<int> mines = {};
  final Set<int> revealed = {};
  final Set<int> flags = {};
  late List<int> clues;
  bool _firstReveal = true;
  bool isCompleted = false;
  bool isFailed = false;
  int get safeCount => cellCount - mineCount;
  int get score => max(100, 1000 - flags.length * 15 - revealed.length).toInt();

  factory MinefieldEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    return MinefieldEngine._(safe, min(8 + (safe - 1) ~/ 7, 22).toInt(),
      Random(safe * 9091 + 29));
  }

  void _placeMines({Set<int> excluded = const {}}) {
    final candidates = [for (var i = 0; i < cellCount; i++)
      if (!excluded.contains(i)) i]..shuffle(_random);
    mines
      ..clear()
      ..addAll(candidates.take(mineCount));
  }

  List<int> _neighbors(int cell) {
    final row = cell ~/ side, col = cell % side;
    return [for (var dr = -1; dr <= 1; dr++)
      for (var dc = -1; dc <= 1; dc++)
        if ((dr != 0 || dc != 0) && row + dr >= 0 && row + dr < side &&
            col + dc >= 0 && col + dc < side)
          (row + dr) * side + col + dc];
  }

  void _calculateClues() {
    clues = [for (var cell = 0; cell < cellCount; cell++)
      mines.contains(cell) ? -1 : _neighbors(cell).where(mines.contains).length];
  }

  MineAction revealCell(int cell) {
    if (cell < 0 || cell >= cellCount || isCompleted || isFailed ||
        revealed.contains(cell) || flags.contains(cell)) return MineAction.ignored;
    if (_firstReveal) {
      _firstReveal = false;
      final safeZone = {cell, ..._neighbors(cell)};
      if (mines.intersection(safeZone).isNotEmpty) {
        _placeMines(excluded: safeZone);
        _calculateClues();
      }
    }
    if (mines.contains(cell)) {
      revealed.add(cell);
      isFailed = true;
      return MineAction.hit;
    }
    final queue = Queue<int>()..add(cell);
    while (queue.isNotEmpty) {
      final next = queue.removeFirst();
      if (revealed.contains(next) || flags.contains(next) || mines.contains(next)) continue;
      revealed.add(next);
      if (clues[next] == 0) {
        for (final neighbor in _neighbors(next)) {
          if (!revealed.contains(neighbor) && !flags.contains(neighbor)) queue.add(neighbor);
        }
      }
    }
    if (revealed.length >= safeCount) {
      isCompleted = true;
      return MineAction.won;
    }
    return MineAction.revealed;
  }

  MineAction toggleFlag(int cell) {
    if (cell < 0 || cell >= cellCount || isCompleted || isFailed || revealed.contains(cell)) {
      return MineAction.ignored;
    }
    if (!flags.add(cell)) flags.remove(cell);
    return MineAction.flagged;
  }
}
