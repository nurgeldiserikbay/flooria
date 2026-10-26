import 'dart:math';

/// A pure-Dart chess knight navigation puzzle with reachable, seeded stages.
/// Cells are indexed row-major on a 5x5 board.
class KnightReachSession {
  KnightReachSession({required this.seed, this.roundCount = 3})
      : assert(roundCount > 0) {
    _newRound();
  }

  static const side = 5;
  static const cellCount = side * side;
  final int seed;
  final int roundCount;

  int round = 0;
  int moves = 0;
  int totalMoves = 0;
  int invalidMoves = 0;
  int start = 0;
  int position = 0;
  int goal = 0;
  int optimalMoves = 0;
  final Set<int> blocked = {};

  bool get complete => round >= roundCount;

  static bool isKnightMove(int from, int to) {
    if (from < 0 || from >= cellCount || to < 0 || to >= cellCount) {
      return false;
    }
    final dr = (from ~/ side - to ~/ side).abs();
    final dc = (from % side - to % side).abs();
    return (dr == 1 && dc == 2) || (dr == 2 && dc == 1);
  }

  List<int> get legalMoves {
    if (complete) return const [];
    return [
      for (var i = 0; i < cellCount; i++)
        if (!blocked.contains(i) && isKnightMove(position, i)) i,
    ];
  }

  /// Returns the shortest route including start and target, or null if absent.
  static List<int>? shortestPath(int from, int to, Set<int> walls) {
    if (from < 0 || from >= cellCount || to < 0 || to >= cellCount ||
        walls.contains(from) || walls.contains(to)) {
      return null;
    }
    final queue = <int>[from];
    final parents = <int, int>{from: from};
    for (var index = 0; index < queue.length; index++) {
      final cell = queue[index];
      if (cell == to) {
        final path = <int>[to];
        var current = to;
        while (current != from) {
          current = parents[current]!;
          path.add(current);
        }
        return path.reversed.toList();
      }
      for (var next = 0; next < cellCount; next++) {
        if (!walls.contains(next) &&
            isKnightMove(cell, next) &&
            !parents.containsKey(next)) {
          parents[next] = cell;
          queue.add(next);
        }
      }
    }
    return null;
  }

  void _newRound() {
    if (complete) return;
    final random = Random((seed * 65537 + round * 104729) & 0x7fffffff);
    final wallsToAdd = round == 0 ? 0 : round == 1 ? 3 : 6;
    for (var attempt = 0; attempt < 100; attempt++) {
      final candidateStart = random.nextInt(cellCount);
      final candidates = [
        for (var i = 0; i < cellCount; i++)
          if (i != candidateStart) i,
      ]..shuffle(random);
      final walls = candidates.take(wallsToAdd).toSet();
      final goals = <(int, int)>[];
      for (var candidate = 0; candidate < cellCount; candidate++) {
        final path = shortestPath(candidateStart, candidate, walls);
        if (path != null && path.length >= 3) {
          goals.add((candidate, path.length - 1));
        }
      }
      if (goals.isEmpty) continue;
      goals.shuffle(random);
      final chosen = goals.first;
      start = candidateStart;
      position = candidateStart;
      goal = chosen.$1;
      optimalMoves = chosen.$2;
      blocked
        ..clear()
        ..addAll(walls);
      moves = 0;
      return;
    }
    throw StateError('Unable to build reachable knight route');
  }

  /// Invalid taps never change progress or position.
  bool move(int cell) {
    if (complete || blocked.contains(cell) || !isKnightMove(position, cell)) {
      return false;
    }
    position = cell;
    moves++;
    totalMoves++;
    if (position == goal) {
      round++;
      _newRound();
    }
    return true;
  }
}
