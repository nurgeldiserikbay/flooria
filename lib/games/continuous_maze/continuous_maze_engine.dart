import 'dart:collection';
import 'dart:math';

enum MazeMoveResult { started, moved, backtracked, completed, invalid, ignored }

class MazeCell {
  const MazeCell(this.row, this.column);

  final int row;
  final int column;

  @override
  bool operator ==(Object other) =>
      other is MazeCell && row == other.row && column == other.column;

  @override
  int get hashCode => Object.hash(row, column);

  @override
  String toString() => 'MazeCell($row, $column)';
}

/// A seeded perfect maze. Every cell is connected, so the start-to-exit route
/// is unique; the player can explore and backtrack while keeping one finger
/// down on the board.
class ContinuousMazeEngine {
  ContinuousMazeEngine._({
    required this.level,
    required this.side,
    required Set<int> passages,
    required this.start,
    required this.goal,
    required List<MazeCell> solution,
  })  : _passages = passages,
        solution = List.unmodifiable(solution);

  static const int minSide = 5;
  static const int maxSide = 9;

  final int level;
  final int side;
  final Set<int> _passages;
  final MazeCell start;
  final MazeCell goal;
  final List<MazeCell> solution;
  final List<MazeCell> path = [];
  int invalidMoves = 0;
  bool complete = false;

  int get totalCells => side * side;
  int get moves => max(0, path.length - 1);
  int get score => max(0, 1000 - moves * 2 - invalidMoves * 25).toInt();

  factory ContinuousMazeEngine.forLevel(int level, {int? seed}) {
    final safeLevel = max(1, level).toInt();
    final side = min(minSide + (safeLevel - 1) ~/ 12, maxSide).toInt();
    final random = Random(seed ?? safeLevel * 65537 + 431);
    final startIndex = 0;
    final passages = <int>{};
    final seen = <int>{startIndex};
    final stack = <int>[startIndex];

    int index(int row, int column) => row * side + column;
    List<int> neighbors(int cell) {
      final row = cell ~/ side;
      final column = cell % side;
      final result = <int>[];
      if (row > 0) result.add(index(row - 1, column));
      if (column + 1 < side) result.add(index(row, column + 1));
      if (row + 1 < side) result.add(index(row + 1, column));
      if (column > 0) result.add(index(row, column - 1));
      result.shuffle(random);
      return result;
    }

    while (stack.isNotEmpty) {
      final current = stack.last;
      final next = neighbors(current).where((cell) => !seen.contains(cell));
      final candidate = next.isEmpty ? null : next.first;
      if (candidate == null) {
        stack.removeLast();
        continue;
      }
      seen.add(candidate);
      passages.add(_edgeKey(current, candidate, side));
      stack.add(candidate);
    }

    final distances = <int, int>{startIndex: 0};
    final parent = <int, int>{};
    final queue = Queue<int>()..add(startIndex);
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final next in _neighborsOf(current, side)) {
        if (!passages.contains(_edgeKey(current, next, side)) ||
            distances.containsKey(next)) {
          continue;
        }
        distances[next] = distances[current]! + 1;
        parent[next] = current;
        queue.add(next);
      }
    }

    final goalIndex = distances.entries.reduce(
      (best, item) => item.value > best.value ? item : best,
    ).key;
    final reversed = <int>[goalIndex];
    while (reversed.last != startIndex) {
      reversed.add(parent[reversed.last]!);
    }
    final route = reversed.reversed
        .map((cell) => MazeCell(cell ~/ side, cell % side))
        .toList(growable: false);

    return ContinuousMazeEngine._(
      level: safeLevel,
      side: side,
      passages: passages,
      start: const MazeCell(0, 0),
      goal: MazeCell(goalIndex ~/ side, goalIndex % side),
      solution: route,
    );
  }

  bool isPassage(MazeCell from, MazeCell to) {
    if (!_contains(from) || !_contains(to)) return false;
    final distance = (from.row - to.row).abs() +
        (from.column - to.column).abs();
    return distance == 1 &&
        _passages.contains(_edgeKey(_cellIndex(from), _cellIndex(to), side));
  }

  MazeMoveResult begin(MazeCell cell) {
    if (complete || path.isNotEmpty) return MazeMoveResult.ignored;
    if (cell != start) {
      invalidMoves++;
      return MazeMoveResult.invalid;
    }
    path.add(start);
    return MazeMoveResult.started;
  }

  MazeMoveResult moveTo(MazeCell cell) {
    if (complete || path.isEmpty || !_contains(cell)) {
      return MazeMoveResult.ignored;
    }
    final current = path.last;
    if (cell == current) return MazeMoveResult.ignored;
    if (path.length > 1 && cell == path[path.length - 2]) {
      path.removeLast();
      return MazeMoveResult.backtracked;
    }
    if (path.contains(cell) || !isPassage(current, cell)) {
      invalidMoves++;
      return MazeMoveResult.invalid;
    }
    path.add(cell);
    if (cell == goal) {
      complete = true;
      return MazeMoveResult.completed;
    }
    return MazeMoveResult.moved;
  }

  void reset() {
    path.clear();
    invalidMoves = 0;
    complete = false;
  }

  /// Lifting a finger before reaching the exit cancels the current trace.
  void cancelTrace() {
    if (complete || path.isEmpty) return;
    path.clear();
    invalidMoves++;
  }

  bool _contains(MazeCell cell) =>
      cell.row >= 0 && cell.row < side &&
      cell.column >= 0 && cell.column < side;

  int _cellIndex(MazeCell cell) => cell.row * side + cell.column;

  static int _edgeKey(int a, int b, int side) {
    final low = min(a, b);
    final high = max(a, b);
    return low * side * side + high;
  }

  static Iterable<int> _neighborsOf(int cell, int side) sync* {
    final row = cell ~/ side;
    final column = cell % side;
    if (row > 0) yield cell - side;
    if (column + 1 < side) yield cell + 1;
    if (row + 1 < side) yield cell + side;
    if (column > 0) yield cell - 1;
  }
}
