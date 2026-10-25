import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/balance_beam/balance_beam_engine.dart';

void main() {
  group('BalanceBeamSession', () {
    test('seeded rounds are repeatable and always have a valid solution', () {
      final first = BalanceBeamSession(seed: 9281);
      final second = BalanceBeamSession(seed: 9281);
      for (var round = 0; round < 3; round++) {
        expect(first.puzzle.targetWeight, second.puzzle.targetWeight);
        expect(first.puzzle.weights, second.puzzle.weights);
        expect(first.puzzle.hasSolution, isTrue);
        expect(first.puzzle.solutionIndices.length, greaterThanOrEqualTo(2));
        if (round < 2) {
          _placeSolution(first);
          _placeSolution(second);
          expect(first.advance(), isTrue);
          expect(second.advance(), isTrue);
        }
      }
    });

    test('rejects invalid and overweight placements without changing pan', () {
      final session = BalanceBeamSession(seed: 17);
      final before = session.placedWeight;
      expect(session.place(-1), isFalse);
      expect(session.place(session.puzzle.weights.length), isFalse);
      expect(session.placedWeight, before);

      final overweight = session.puzzle.weights.indexWhere(
        (weight) => weight > session.puzzle.targetWeight,
      );
      if (overweight >= 0) {
        expect(session.place(overweight), isFalse);
        expect(session.placedWeight, before);
        expect(session.mistakes, 1);
      }
    });

    test('only exact balance advances and completion stays final', () {
      final session = BalanceBeamSession(seed: 42);
      expect(session.advance(), isFalse);
      _placeSolution(session);
      expect(session.balanced, isTrue);
      expect(session.advance(), isTrue);
      for (var round = 1; round < 3; round++) {
        _placeSolution(session);
        expect(session.advance(), isTrue);
      }
      expect(session.finished, isTrue);
      expect(session.progress, 1);
      expect(session.advance(), isFalse);
      expect(session.place(0), isFalse);
    });

    test('placed weights can be removed to correct a choice', () {
      final session = BalanceBeamSession(seed: 83);
      final index = session.puzzle.solutionIndices.first;
      expect(session.place(index), isTrue);
      expect(session.remove(index), isTrue);
      expect(session.placedWeight, 0);
      expect(session.remove(index), isFalse);
    });
  });
}

void _placeSolution(BalanceBeamSession session) {
  for (final index in session.puzzle.solutionIndices) {
    expect(session.place(index), isTrue);
  }
  expect(session.balanced, isTrue);
}
