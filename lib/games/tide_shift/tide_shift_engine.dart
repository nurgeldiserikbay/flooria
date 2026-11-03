import 'dart:math';

enum TideMove { moved, completed, flooded, blocked, ignored }

/// Find the high-ground route before the incoming tide covers the low tiles.
class TideShiftEngine {
  TideShiftEngine._(this.level, this.heights, this.position, this.goal);
  static const side = 6;
  final int level;
  final List<int> heights;
  int position;
  final int goal;
  int moves = 0;
  int tide = 0;
  bool isCompleted = false;
  bool isFailed = false;
  int get score => max(100, 1000 - moves * 32 - tide * 30).toInt();

  factory TideShiftEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final heights = List<int>.generate(side * side, (i) => ((i * 7 + safe * 3) % 3));
    // A guaranteed raised causeway runs along the bottom, then up the east edge.
    for (var col = 0; col < side; col++) {
      heights[30 + col] = 4;
    }
    for (var row = 0; row < side; row++) {
      heights[row * side + 5] = 4;
    }
    return TideShiftEngine._(safe, heights, 30, 5);
  }

  TideMove step(int dr, int dc) {
    if (isCompleted || isFailed) return TideMove.ignored;
    final row = position ~/ side + dr, col = position % side + dc;
    if (row < 0 || row >= side || col < 0 || col >= side) return TideMove.blocked;
    position = row * side + col;
    moves++;
    tide = moves ~/ max(3, 5 - min(2, (level - 1) ~/ 10));
    if (heights[position] < tide) {
      isFailed = true;
      return TideMove.flooded;
    }
    isCompleted = position == goal;
    return isCompleted ? TideMove.completed : TideMove.moved;
  }
}
