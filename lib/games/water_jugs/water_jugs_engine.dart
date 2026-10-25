import 'dart:math';

/// Exact-measurement puzzle: use fills, empties and pours to obtain a goal.
/// Rules and procedural level construction are pure Dart.
enum JugAction { fillA, fillB, emptyA, emptyB, pourAtoB, pourBtoA }

class JugState {
  const JugState(this.a, this.b);
  final int a;
  final int b;
  @override
  bool operator ==(Object other) =>
      other is JugState && other.a == a && other.b == b;
  @override
  int get hashCode => Object.hash(a, b);
}

class JugPuzzle {
  const JugPuzzle(this.capacityA, this.capacityB, this.goal, this.minimumMoves);
  final int capacityA;
  final int capacityB;
  final int goal;
  final int minimumMoves;
}

class WaterJugsSession {
  WaterJugsSession({required this.seed, this.roundCount = 3})
      : assert(roundCount > 0) {
    _startRound();
  }

  final int seed;
  final int roundCount;
  int round = 0;
  int moves = 0;
  int totalMoves = 0;
  int invalidActions = 0;
  bool get complete => round >= roundCount;
  late JugPuzzle puzzle;
  JugState state = const JugState(0, 0);
  JugState? previous;

  static JugState apply(JugState s, JugAction action, int capacityA, int capacityB) {
    switch (action) {
      case JugAction.fillA:
        return JugState(capacityA, s.b);
      case JugAction.fillB:
        return JugState(s.a, capacityB);
      case JugAction.emptyA:
        return JugState(0, s.b);
      case JugAction.emptyB:
        return JugState(s.a, 0);
      case JugAction.pourAtoB:
        final amount = min(s.a, capacityB - s.b);
        return JugState(s.a - amount, s.b + amount);
      case JugAction.pourBtoA:
        final amount = min(s.b, capacityA - s.a);
        return JugState(s.a + amount, s.b - amount);
    }
  }

  /// BFS produces the shortest solution length, or null when impossible.
  static int? shortestSolution(int capA, int capB, int target) {
    if (capA <= 0 || capB <= 0 || target <= 0 ||
        target > max(capA, capB)) {
      return null;
    }
    final queue = <JugState>[const JugState(0, 0)];
    final distance = <JugState, int>{queue.first: 0};
    for (var i = 0; i < queue.length; i++) {
      final current = queue[i];
      if (current.a == target || current.b == target) {
        return distance[current];
      }
      for (final action in JugAction.values) {
        final next = apply(current, action, capA, capB);
        if (!distance.containsKey(next)) {
          distance[next] = distance[current]! + 1;
          queue.add(next);
        }
      }
    }
    return null;
  }

  void _startRound() {
    if (complete) return;
    final random = Random((seed * 65537 + round * 104729) & 0x7fffffff);
    final options = <JugPuzzle>[];
    for (var a = 3; a <= 7; a++) {
      for (var b = a + 1; b <= 9; b++) {
        for (var goal = 1; goal < b; goal++) {
          final steps = shortestSolution(a, b, goal);
          if (steps != null && steps >= 2 + round &&
              steps <= 5 + round * 2 &&
              goal != a) {
            options.add(JugPuzzle(a, b, goal, steps));
          }
        }
      }
    }
    if (options.isEmpty) throw StateError('No reachable water jug levels');
    puzzle = options[random.nextInt(options.length)];
    state = const JugState(0, 0);
    previous = null;
    moves = 0;
  }

  bool get solved => !complete &&
      (state.a == puzzle.goal || state.b == puzzle.goal);

  /// No-op operations cannot spend moves or affect the round.
  bool perform(JugAction action) {
    if (complete) return false;
    final next = apply(state, action, puzzle.capacityA, puzzle.capacityB);
    if (next == state) {
      invalidActions++;
      return false;
    }
    previous = state;
    state = next;
    moves++;
    totalMoves++;
    if (solved) {
      round++;
      _startRound();
    }
    return true;
  }

  /// Undo current round's last move; never crosses a completed round.
  bool undo() {
    if (complete || previous == null) return false;
    state = previous!;
    previous = null;
    moves--;
    totalMoves--;
    return true;
  }
}
