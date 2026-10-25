import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/quick_count/quick_count_engine.dart';

void main() {
  group('QuickCountSession', () {
    test('seeded boards repeat and every round has three valid choices', () {
      final first = QuickCountSession(seed: 742, level: 4);
      final second = QuickCountSession(seed: 742, level: 4);

      expect(first.rounds.length, QuickCountSession.roundCount);
      expect(first.rounds, second.rounds);
      for (final round in first.rounds) {
        expect(round.choices, contains(round.target));
        expect(round.choices.toSet().length, 3);
        expect(round.dots.length, round.target);
        expect(round.dots.toSet().length, round.target);
        for (final dot in round.dots) {
          expect(dot.x, inInclusiveRange(0, 1));
          expect(dot.y, inInclusiveRange(0, 1));
        }
      }
    });

    test('invalid answers do not change the round or score', () {
      final session = QuickCountSession(seed: 19);
      final invalid = session.current.target + 100;

      expect(session.answer(invalid), isFalse);
      expect(session.round, 0);
      expect(session.correct, 0);
    });

    test('accepts one answer per round and counts exact estimates', () {
      final session = QuickCountSession(seed: 98);
      for (var index = 0; index < QuickCountSession.roundCount; index++) {
        final target = session.current.target;
        expect(session.answer(target), isTrue);
        expect(session.answer(target), isFalse);
      }

      expect(session.finished, isTrue);
      expect(session.correct, QuickCountSession.roundCount);
      expect(session.progress, 1);
      expect(session.passed, isTrue);
      expect(session.answer(session.current.target), isFalse);
    });

    test('six exact estimates pass while five do not', () {
      final six = QuickCountSession(seed: 13);
      for (var index = 0; index < QuickCountSession.roundCount; index++) {
        final target = six.current.target;
        final answer = index < QuickCountSession.passScore
            ? target
            : six.current.choices.firstWhere((choice) => choice != target);
        six.answer(answer);
      }
      expect(six.correct, QuickCountSession.passScore);
      expect(six.passed, isTrue);

      final five = QuickCountSession(seed: 13);
      for (var index = 0; index < QuickCountSession.roundCount; index++) {
        final target = five.current.target;
        final answer = index < QuickCountSession.passScore - 1
            ? target
            : five.current.choices.firstWhere((choice) => choice != target);
        five.answer(answer);
      }
      expect(five.correct, QuickCountSession.passScore - 1);
      expect(five.passed, isFalse);
    });
  });
}
