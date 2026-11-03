import 'dart:math';

enum SokobanMove { moved, blocked, completed, ignored }
enum CrateDirection { up, right, down, left }

/// Small warehouse puzzles. The goal is to push every crate onto a marked pad.
class SokobanEngine {
  SokobanEngine._(this.level, this.crates, this.goals, this.player);

  static const int side = 9;
  final int level;
  final Set<int> crates;
  final Set<int> goals;
  int player;
  int moves = 0;
  bool isCompleted = false;
  bool isFailed = false;

  int get score => max(100, 1000 - moves * 8).toInt();
  bool isWall(int cell) {
    final row = cell ~/ side, col = cell % side;
    return row == 0 || col == 0 || row == side - 1 || col == side - 1;
  }

  factory SokobanEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final crateCount = min(1 + (safe - 1) ~/ 4, 5).toInt();
    final goalColumn = min(5 + (safe - 1) ~/ 8, 7).toInt();
    final rows = [4, 2, 6, 3, 5].take(crateCount).toList();
    return SokobanEngine._(
      safe,
      {for (final row in rows) row * side + 4},
      {for (final row in rows) row * side + goalColumn},
      4 * side + 2,
    );
  }

  SokobanMove move(CrateDirection direction) {
    if (isCompleted || isFailed) return SokobanMove.ignored;
    final (dr, dc) = switch (direction) {
      CrateDirection.up => (-1, 0),
      CrateDirection.right => (0, 1),
      CrateDirection.down => (1, 0),
      CrateDirection.left => (0, -1),
    };
    final row = player ~/ side, col = player % side;
    final next = (row + dr) * side + col + dc;
    if (isWall(next)) return SokobanMove.blocked;
    if (crates.contains(next)) {
      final beyond = (row + dr * 2) * side + col + dc * 2;
      if (isWall(beyond) || crates.contains(beyond)) return SokobanMove.blocked;
      crates.remove(next);
      crates.add(beyond);
    }
    player = next;
    moves++;
    isCompleted = goals.every(crates.contains);
    return isCompleted ? SokobanMove.completed : SokobanMove.moved;
  }
}
