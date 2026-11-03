import 'dart:math';

enum ZipMove { moved, blocked, completed, ignored }

/// Trace a single non-repeating path through every cell and numbered checkpoint.
class ZipRouteEngine {
  ZipRouteEngine._(this.level, this.side, this.checkpoints, this.path);

  final int level;
  final int side;
  final Map<int, int> checkpoints;
  final List<int> path;
  int nextCheckpoint = 2;
  bool isCompleted = false;
  int get filledCount => path.length;
  int get score => max(100, 1000 - path.length * 3).toInt();
  int get position => path.last;

  factory ZipRouteEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final side = safe < 12 ? 5 : safe < 36 ? 6 : 7;
    final solution = <int>[];
    for (var row = 0; row < side; row++) {
      final columns = row.isEven
          ? [for (var col = 0; col < side; col++) col]
          : [for (var col = side - 1; col >= 0; col--) col];
      for (final col in columns) {
        solution.add(row * side + col);
      }
    }
    if (safe.isEven) {
      solution.setAll(0, solution.reversed.toList());
    }
    final checkpointCount = min(4 + (safe - 1) ~/ 8, 9).toInt();
    final checkpoints = <int, int>{};
    for (var number = 0; number < checkpointCount; number++) {
      final index = (number * (solution.length - 1) ~/ (checkpointCount - 1));
      checkpoints[solution[index]] = number + 1;
    }
    return ZipRouteEngine._(safe, side, checkpoints, [solution.first]);
  }

  ZipMove enter(int cell) {
    if (isCompleted || cell < 0 || cell >= side * side) return ZipMove.ignored;
    if (path.contains(cell)) return ZipMove.blocked;
    final row = cell ~/ side, col = cell % side;
    final currentRow = position ~/ side, currentCol = position % side;
    if ((row - currentRow).abs() + (col - currentCol).abs() != 1) return ZipMove.blocked;
    final checkpoint = checkpoints[cell];
    if (checkpoint != null && checkpoint != nextCheckpoint) return ZipMove.blocked;
    path.add(cell);
    if (checkpoint == nextCheckpoint) nextCheckpoint++;
    isCompleted = path.length == side * side && nextCheckpoint > checkpoints.length;
    return isCompleted ? ZipMove.completed : ZipMove.moved;
  }
}
