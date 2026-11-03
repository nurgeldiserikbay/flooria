import 'dart:math';

enum GravityDirection { up, right, down, left }
enum GravityMove { moved, completed, blocked, ignored }

/// Rotate gravity to roll the core between stops and reach the exit.
class GravityShiftEngine {
  GravityShiftEngine._(this.level, this.walls, this.ball, this.goal, this.moveLimit);

  static const int side = 6;
  final int level;
  final Set<int> walls;
  final int goal;
  final int moveLimit;
  int ball;
  int moves = 0;
  bool isCompleted = false;
  bool get isFailed => !isCompleted && moves >= moveLimit;
  int get movesLeft => moveLimit - moves;
  int get score => max(100, 1000 - moves * 24).toInt();

  factory GravityShiftEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    const start = (side - 1) * side;
    const goal = side - 1;
    final random = Random(safe * 15391 + 89);
    final wallCount = min(10, 3 + (safe - 1) ~/ 7).toInt();
    Set<int> walls = {};
    var shortest = 0;
    for (var attempt = 0; attempt < 80; attempt++) {
      final candidate = <int>{};
      while (candidate.length < wallCount) {
        final cell = random.nextInt(side * side);
        if (cell != start && cell != goal) candidate.add(cell);
      }
      final path = _findPath(candidate, start, goal);
      if (path != null) {
        walls = candidate;
        shortest = path;
        break;
      }
    }
    if (walls.isEmpty) shortest = 2;
    return GravityShiftEngine._(safe, walls, start, goal,
      max(shortest + 3, 6 + min(8, (safe - 1) ~/ 8)).toInt());
  }

  GravityMove tilt(GravityDirection direction) {
    if (isCompleted || isFailed) return GravityMove.ignored;
    final row = ball ~/ side, col = ball % side;
    final (dr, dc) = switch (direction) {
      GravityDirection.up => (-1, 0),
      GravityDirection.right => (0, 1),
      GravityDirection.down => (1, 0),
      GravityDirection.left => (0, -1),
    };
    var nextRow = row, nextCol = col;
    while (true) {
      final r = nextRow + dr, c = nextCol + dc;
      if (r < 0 || r >= side || c < 0 || c >= side || walls.contains(r * side + c)) break;
      nextRow = r;
      nextCol = c;
    }
    final next = nextRow * side + nextCol;
    if (next == ball) return GravityMove.blocked;
    ball = next;
    moves++;
    isCompleted = ball == goal;
    return isCompleted ? GravityMove.completed : GravityMove.moved;
  }

  static int? _findPath(Set<int> walls, int start, int goal) {
    final distance = {start: 0};
    final queue = <int>[start];
    for (var i = 0; i < queue.length; i++) {
      final cell = queue[i];
      if (cell == goal) return distance[cell];
      final row = cell ~/ side, col = cell % side;
      for (final (dr, dc) in const [(-1, 0), (0, 1), (1, 0), (0, -1)]) {
        var r = row, c = col;
        while (true) {
          final nr = r + dr, nc = c + dc;
          if (nr < 0 || nr >= side || nc < 0 || nc >= side || walls.contains(nr * side + nc)) break;
          r = nr; c = nc;
        }
        final next = r * side + c;
        if (next != cell && !distance.containsKey(next)) {
          distance[next] = distance[cell]! + 1;
          queue.add(next);
        }
      }
    }
    return null;
  }
}
