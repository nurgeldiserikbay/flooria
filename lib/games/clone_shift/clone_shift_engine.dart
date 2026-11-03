import 'dart:math';

enum CloneDirection { up, right, down, left }
enum CloneMove { moved, completed, ignored }

/// Two linked explorers move together; the second mirrors horizontal input.
class CloneShiftEngine {
  CloneShiftEngine._(this.level, this.walls, this.positions, this.goals, this.limit);
  static const side = 5;
  final int level;
  final Set<int> walls;
  final List<int> positions;
  final List<int> goals;
  final int limit;
  int moves = 0;
  bool isCompleted = false;
  bool get isFailed => !isCompleted && moves >= limit;
  int get score => max(100, 1000 - moves * 45).toInt();

  factory CloneShiftEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final walls = <int>{};
    if (safe >= 2) walls.addAll([10, 14]);
    if (safe >= 5) walls.addAll([5, 9]);
    return CloneShiftEngine._(safe, walls, [20, 24], [0, 4], 14 + min(8, safe));
  }

  CloneMove move(CloneDirection direction) {
    if (isCompleted || isFailed) return CloneMove.ignored;
    final (dr, dc) = switch (direction) {
      CloneDirection.up => (-1, 0), CloneDirection.right => (0, 1),
      CloneDirection.down => (1, 0), CloneDirection.left => (0, -1),
    };
    for (var i = 0; i < positions.length; i++) {
      final mirroredDc = i == 1 ? -dc : dc;
      final row = positions[i] ~/ side + dr;
      final col = positions[i] % side + mirroredDc;
      if (row >= 0 && row < side && col >= 0 && col < side && !walls.contains(row * side + col)) {
        positions[i] = row * side + col;
      }
    }
    moves++;
    isCompleted = positions[0] == goals[0] && positions[1] == goals[1];
    return isCompleted ? CloneMove.completed : CloneMove.moved;
  }
}
