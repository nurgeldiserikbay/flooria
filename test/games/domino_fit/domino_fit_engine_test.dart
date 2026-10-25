import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/domino_fit/domino_fit_engine.dart';

void main() {
  test('seeded boards always have a complete domino covering', () {
    for (var seed = -40; seed < 160; seed++) {
      final game = DominoFitSession(seed: seed);
      final duplicate = DominoFitSession(seed: seed);
      for (var round = 0; round < 3; round++) {
        expect(game.blocked, duplicate.blocked);
        expect(game.solution, duplicate.solution);
        final covered = <int>{...game.blocked};
        for (final pair in game.solution) {
          expect(game.adjacent(pair.$1, pair.$2), true);
          expect(covered.add(pair.$1), true);
          expect(covered.add(pair.$2), true);
        }
        expect(covered.length, 16);
        final pairs = List<(int, int)>.of(game.solution);
        for (final pair in pairs) {
          expect(game.tap(pair.$1), true);
          expect(game.tap(pair.$2), true);
          duplicate.tap(pair.$1);
          duplicate.tap(pair.$2);
        }
        expect(game.round, round + 1, reason: 'seed=$seed round=$round');
      }
      expect(game.complete, true);
      expect(game.moves, greaterThan(0));
      expect(game.tap(0), false);
    }
  });

  test('invalid taps do not change state or consume moves', () {
    final game = DominoFitSession(seed: 12);
    expect(game.tap(-1), false);
    expect(game.tap(16), false);
    expect(game.moves, 0);
    expect(game.tap(0), true);
    expect(game.tap(0), true);
    expect(game.anchor, null);
    expect(game.moves, 0);
  });

  test('placed domino can be removed, freeing two cells', () {
    final game = DominoFitSession(seed: 8);
    final pair = game.solution.first;
    game.tap(pair.$1);
    game.tap(pair.$2);
    expect(game.placed.length, 2);
    expect(game.tap(pair.$1), true);
    expect(game.placed, isEmpty);
    expect(game.removals, 1);
    expect(game.moves, 2);
  });

  test('wrong second selection changes anchor without placing a domino', () {
    final game = DominoFitSession(seed: 8);
    expect(game.tap(0), true);
    expect(game.tap(15), true);
    expect(game.anchor, 15);
    expect(game.placed, isEmpty);
  });
}
