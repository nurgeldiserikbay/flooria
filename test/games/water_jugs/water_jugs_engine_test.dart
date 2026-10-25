import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/water_jugs/water_jugs_engine.dart';

List<JugAction> solve(JugPuzzle puzzle) {
  const initial = JugState(0, 0);
  final queue = <JugState>[initial];
  final seen = <JugState>{initial};
  final paths = <JugState, List<JugAction>>{initial: []};
  for (var index = 0; index < queue.length; index++) {
    final state = queue[index];
    if (state.a == puzzle.goal || state.b == puzzle.goal) {
      return paths[state]!;
    }
    for (final action in JugAction.values) {
      final next = WaterJugsSession.apply(state, action,
        puzzle.capacityA, puzzle.capacityB);
      if (seen.add(next)) {
        paths[next] = [...paths[state]!, action];
        queue.add(next);
      }
    }
  }
  throw StateError('Unsolvable puzzle');
}

void main() {
  test('seeded generation always selects reachable goals', () {
    for (var seed = -20; seed < 150; seed++) {
      final session = WaterJugsSession(seed: seed);
      final duplicate = WaterJugsSession(seed: seed);
      for (var stage = 0; stage < 3; stage++) {
        final puzzle = session.puzzle;
        expect(puzzle.capacityA, duplicate.puzzle.capacityA);
        expect(puzzle.capacityB, duplicate.puzzle.capacityB);
        expect(puzzle.goal, duplicate.puzzle.goal);
        final solution = solve(puzzle);
        expect(solution.length, puzzle.minimumMoves);
        expect(solution.length, greaterThanOrEqualTo(2 + stage));
        for (final action in solution) {
          expect(session.perform(action), true);
          expect(duplicate.perform(action), true);
        }
        expect(session.round, stage + 1);
      }
      expect(session.complete, true);
      expect(session.perform(JugAction.fillA), false);
    }
  });

  test('no-op actions do not count as moves', () {
    final session = WaterJugsSession(seed: 15);
    expect(session.perform(JugAction.emptyA), false);
    expect(session.perform(JugAction.emptyB), false);
    expect(session.perform(JugAction.pourAtoB), false);
    expect(session.moves, 0);
    expect(session.invalidActions, 3);
  });

  test('undo restores previous state and rejects a second undo', () {
    final session = WaterJugsSession(seed: 8);
    expect(session.perform(JugAction.fillA), true);
    expect(session.state.a, session.puzzle.capacityA);
    expect(session.undo(), true);
    expect(session.state, const JugState(0, 0));
    expect(session.moves, 0);
    expect(session.undo(), false);
  });

  test('pour respects source volume and destination capacity', () {
    const state = JugState(5, 2);
    final next = WaterJugsSession.apply(state, JugAction.pourAtoB, 5, 4);
    expect(next, const JugState(3, 4));
    expect(WaterJugsSession.shortestSolution(4, 6, 3), null);
  });
}
