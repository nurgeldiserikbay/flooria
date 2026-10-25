import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/fraction_forge/fraction_forge_engine.dart';

void main() {
  group('FractionForgeSession', () {
    test('seeded questions repeat and each has one closest option', () {
      final first = FractionForgeSession(seed: 418);
      final second = FractionForgeSession(seed: 418);
      expect(first.challenges.length, FractionForgeSession.roundCount);

      for (var round = 0; round < first.challenges.length; round++) {
        final a = first.challenges[round];
        final b = second.challenges[round];
        expect(a.target, b.target);
        expect(a.options, b.options);
        expect(a.options.length, round < 4 ? 3 : 4);
        expect(a.options.toSet().length, a.options.length);

        final distances = a.options
            .map((fraction) => fraction.distanceFrom(a.target))
            .toList();
        final nearest = distances.reduce((x, y) => x.compareTo(y) < 0 ? x : y);
        expect(distances.where((distance) => distance == nearest), hasLength(1));
        expect(a.options[a.answerIndex].distanceFrom(a.target), nearest);
      }
    });

    test('fractions normalize and compare exactly', () {
      expect(FractionValue.of(2, 4), FractionValue.of(1, 2));
      expect(FractionValue.of(1, 3).compareTo(FractionValue.of(2, 5)),
          lessThan(0));
      expect(FractionValue.of(3, 4).distanceFrom(FractionValue.of(1, 2)),
          FractionValue.of(1, 4));
    });

    test('invalid choices do not change state', () {
      final session = FractionForgeSession(seed: 7);
      expect(session.choose(-1), FractionPickResult.invalid);
      expect(session.choose(session.current.options.length),
          FractionPickResult.invalid);
      expect(session.roundIndex, 0);
      expect(session.mistakes, 0);
      expect(session.correctAnswers, 0);
    });

    test('incorrect option records a slip and answer advances', () {
      final session = FractionForgeSession(seed: 92);
      final wrong = (session.current.answerIndex + 1) %
          session.current.options.length;
      expect(session.choose(wrong), FractionPickResult.incorrect);
      expect(session.mistakes, 1);
      expect(session.roundIndex, 0);
      expect(session.choose(session.current.answerIndex),
          FractionPickResult.correct);
      expect(session.correctAnswers, 1);
      expect(session.roundIndex, 1);
    });

    test('completes all rounds once and rejects later input', () {
      final session = FractionForgeSession(seed: 11);
      for (var round = 0; round < FractionForgeSession.roundCount; round++) {
        final answer = session.current.answerIndex;
        final result = session.choose(answer);
        expect(result, round == FractionForgeSession.roundCount - 1
            ? FractionPickResult.complete
            : FractionPickResult.correct);
      }
      expect(session.finished, isTrue);
      expect(session.correctAnswers, FractionForgeSession.roundCount);
      expect(session.progress, 1);
      expect(session.choose(0), FractionPickResult.invalid);
    });
  });
}
