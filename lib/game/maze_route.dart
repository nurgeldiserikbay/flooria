import 'dart:math';

/// Deterministic randomized depth-first maze. Every cell is connected.
/// Connections are bit masks: north=1, east=2, south=4, west=8.
class MazeRouteSession {
  MazeRouteSession({required int seed, this.size = 6})
      : assert(size >= 3 && size <= 12),
        passages = List<int>.filled(size * size, 0) {
    final random = Random(seed);
    final visited = <int>{0};
    final stack = <int>[0];
    while (stack.isNotEmpty) {
      final current = stack.last;
      final candidates = <(int, int, int)>[];
      for (final dir in directions) {
        final next = neighbor(current, dir.$1);
        if (next != null && !visited.contains(next)) {
          candidates.add((next, dir.$1, dir.$2));
        }
      }
      if (candidates.isEmpty) {
        stack.removeLast();
        continue;
      }
      final selected = candidates[random.nextInt(candidates.length)];
      passages[current] |= selected.$2;
      passages[selected.$1] |= selected.$3;
      visited.add(selected.$1);
      stack.add(selected.$1);
    }
  }

  final int size;
  final List<int> passages;
  int position = 0;
  int moves = 0;
  int wrongMoves = 0;

  static const directions = <(int, int, int)>[
    (0, 1, 4), (1, 2, 8), (2, 4, 1), (3, 8, 2),
  ];

  int get exit => size * size - 1;
  bool get finished => position == exit;

  int? neighbor(int cell, int direction) {
    if (cell < 0 || cell >= passages.length) return null;
    final row = cell ~/ size;
    final col = cell % size;
    switch (direction) {
      case 0: return row > 0 ? cell - size : null;
      case 1: return col < size - 1 ? cell + 1 : null;
      case 2: return row < size - 1 ? cell + size : null;
      case 3: return col > 0 ? cell - 1 : null;
      default: return null;
    }
  }

  bool canMove(int cell, int direction) {
    if (cell < 0 || cell >= passages.length ||
        direction < 0 || direction > 3) {
      return false;
    }
    return passages[cell] & directions[direction].$2 != 0;
  }

  bool step(int direction) {
    if (finished) return false;
    if (!canMove(position, direction)) {
      wrongMoves++;
      return false;
    }
    position = neighbor(position, direction)!;
    moves++;
    return true;
  }

  /// Shortest solution, useful for testing and tuning difficulty.
  List<int> solution() {
    final queue = <int>[0];
    final parents = <int, (int, int)>{};
    final visited = <int>{0};
    for (var cursor = 0; cursor < queue.length; cursor++) {
      final cell = queue[cursor];
      if (cell == exit) break;
      for (var dir = 0; dir < 4; dir++) {
        if (!canMove(cell, dir)) continue;
        final next = neighbor(cell, dir)!;
        if (visited.add(next)) {
          parents[next] = (cell, dir);
          queue.add(next);
        }
      }
    }
    final path = <int>[];
    var cell = exit;
    while (cell != 0) {
      final parent = parents[cell];
      if (parent == null) throw StateError('Unreachable maze exit');
      path.add(parent.$2);
      cell = parent.$1;
    }
    return path.reversed.toList();
  }
}
