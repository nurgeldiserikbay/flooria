import 'dart:math';

enum MazeMove { moved, blocked, completed, failed, ignored }

/// Reach the exit before the energy counter drops below zero.
class NumberMazeEngine {
  NumberMazeEngine._(this.level, this.values, this.energy, this.path);

  static const int side = 5;
  final int level;
  final List<int> values;
  final List<int> path;
  int energy;
  int moves = 0;
  bool isCompleted = false;
  bool isFailed = false;
  int get position => path.last;
  int get score => max(100, 500 + energy * 25 - moves * 8).toInt();

  factory NumberMazeEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final random = Random(safe * 27103 + 23);
    final values = [for (var i = 0; i < side * side; i++) random.nextInt(7) - 3];
    for (var col = 1; col < side; col++) {
      values[col] = 2;
    }
    for (var row = 1; row < side; row++) {
      values[row * side + side - 1] = 2;
    }
    values[0] = 0;
    return NumberMazeEngine._(
      safe, values, max(2, 9 - (safe - 1) ~/ 12).toInt(), [0]);
  }

  MazeMove enter(int cell) {
    if (isCompleted || isFailed || cell < 0 || cell >= values.length) {
      return MazeMove.ignored;
    }
    if (path.contains(cell)) return MazeMove.blocked;
    final row = cell ~/ side, col = cell % side;
    final currentRow = position ~/ side, currentCol = position % side;
    if ((row - currentRow).abs() + (col - currentCol).abs() != 1) {
      return MazeMove.blocked;
    }
    energy += values[cell] - 1;
    moves++;
    path.add(cell);
    if (cell == values.length - 1 && energy >= 0) {
      isCompleted = true;
      return MazeMove.completed;
    }
    if (energy < 0) {
      isFailed = true;
      return MazeMove.failed;
    }
    return MazeMove.moved;
  }
}
