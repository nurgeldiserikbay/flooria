import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/balance_scale/balance_scale_engine.dart';

void main() {
  test('all seeded puzzles are deterministic and have an exact solution', () {
    for (var seed = 0; seed < 150; seed++) {
      final game = BalanceScaleSession(seed: seed);
      final matching = BalanceScaleSession(seed: seed);
      expect(game.weights, matching.weights);
      expect(game.target, matching.target);
      expect(game.weights.toSet().length, 5);
      expect(game.weights.every((weight) => weight > 0), isTrue);
      for (final index in game.solutionIndices) {
        expect(game.toggle(index), isTrue);
      }
      expect(game.placedWeight, game.target);
      expect(game.balanced, isTrue);
      expect(game.submit(), isTrue);
      expect(game.round, 1);
    }
  });

  test('invalid taps do not mutate state and incorrect guesses stay editable', () {
    final game = BalanceScaleSession(seed: 82);
    expect(game.toggle(-1), isFalse);
    expect(game.toggle(5), isFalse);
    expect(game.submit(), isFalse);
    expect(game.attempts, 0);
    expect(game.toggle(game.solutionIndices.first), isTrue);
    expect(game.submit(), isFalse);
    expect(game.round, 0);
    expect(game.attempts, 1);
    expect(game.selected, hasLength(1));
    expect(game.toggle(game.solutionIndices.first), isTrue);
    expect(game.selected, isEmpty);
  });

  test('three solved rounds complete exactly once and block later inputs', () {
    final game = BalanceScaleSession(seed: 71);
    while (!game.complete) {
      for (final index in game.solutionIndices) {
        expect(game.toggle(index), isTrue);
      }
      expect(game.submit(), isTrue);
    }
    expect(game.round, 3);
    expect(game.attempts, 3);
    expect(game.toggle(0), isFalse);
    expect(game.submit(), isFalse);
    expect(game.round, 3);
  });
}
