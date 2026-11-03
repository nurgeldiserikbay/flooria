import 'dart:math';

enum PaintMove { moved, blocked, completed, ignored }

/// Perfect-maze rules for a continuous start-to-exit tracing game.
class PathPaintEngine {
  PathPaintEngine._({required this.level, required this.size, required this.walls})
      : start = 0,
        goal = size * size - 1,
        _position = 0 {
    _visited.add(0);
  }

  final int level;
  final int size;
  // A bit mask per cell: up=1, right=2, down=4, left=8. A set bit is a wall.
  final List<int> walls;
  final int start;
  final int goal;
  int _position;
  final Set<int> _visited = {};
  bool _completed = false;
  int blockedMoves = 0;

  int get position => _position;
  bool get isCompleted => _completed;
  int get paintedCount => _visited.length;
  Set<int> get paintedCells => Set.unmodifiable(_visited);
  int get score => max(100, 1000 - blockedMoves * 20).toInt();
  int get focusMetric => (100 - blockedMoves * 5).clamp(25, 100).toInt();

  factory PathPaintEngine.forLevel(int level, {int? seed}) {
    final safeLevel = max(1, level).toInt();
    final size = min(5 + (safeLevel - 1) ~/ 12, 9).toInt();
    final random = Random(seed ?? safeLevel * 7919 + 17);
    final walls = List<int>.filled(size * size, 15);
    final seen = <int>{0};
    final stack = <int>[0];
    const bits = [1, 2, 4, 8];
    const opposite = [4, 8, 1, 2];
    const dr = [-1, 0, 1, 0];
    const dc = [0, 1, 0, -1];
    while (stack.isNotEmpty) {
      final cell = stack.last;
      final row = cell ~/ size;
      final col = cell % size;
      final choices = <(int, int)>[];
      for (var d = 0; d < 4; d++) {
        final nr = row + dr[d];
        final nc = col + dc[d];
        if (nr < 0 || nc < 0 || nr >= size || nc >= size) continue;
        final next = nr * size + nc;
        if (!seen.contains(next)) choices.add((d, next));
      }
      if (choices.isEmpty) {
        stack.removeLast();
        continue;
      }
      final (direction, next) = choices[random.nextInt(choices.length)];
      walls[cell] &= ~bits[direction];
      walls[next] &= ~opposite[direction];
      seen.add(next);
      stack.add(next);
    }
    return PathPaintEngine._(level: safeLevel, size: size, walls: walls);
  }

  bool canStep(int from, int to) {
    if (from < 0 || to < 0 || from >= size * size || to >= size * size) return false;
    final delta = to - from;
    final direction = delta == -size ? 0 : delta == 1 && from ~/ size == to ~/ size
        ? 1 : delta == size ? 2 : delta == -1 && from ~/ size == to ~/ size ? 3 : -1;
    if (direction < 0) return false;
    const directionBits = [1, 2, 4, 8];
    return (walls[from] & directionBits[direction]) == 0;
  }

  PaintMove moveTo(int cell) {
    if (_completed || cell < 0 || cell >= size * size) return PaintMove.ignored;
    if (cell == _position) return PaintMove.ignored;
    if (!canStep(_position, cell)) {
      blockedMoves++;
      return PaintMove.blocked;
    }
    _position = cell;
    _visited.add(cell);
    if (_position == goal) {
      _completed = true;
      return PaintMove.completed;
    }
    return PaintMove.moved;
  }
}
