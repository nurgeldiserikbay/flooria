import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/chance_garden/chance_garden_engine.dart';

void main() {
  group('ChanceGardenSession', () {
    test('seeded rounds repeat and every sample has one most-likely jar', () {
      final first = ChanceGardenSession(seed: 418);
      final second = ChanceGardenSession(seed: 418);
      expect(first.rounds, hasLength(ChanceGardenSession.roundCount));

      for (var index = 0; index < first.rounds.length; index++) {
        final a = first.rounds[index];
        final b = second.rounds[index];
        expect(a.sample, b.sample);
        expect(a.correctJarIndex, b.correctJarIndex);
        expect(a.jars.map((jar) => jar.coralCount),
            b.jars.map((jar) => jar.coralCount));
        expect(a.jars, hasLength(2));
        expect(a.sample.length, inInclusiveRange(4, 8));
        expect(a.jars.every((jar) => jar.coralCount >= 1 && jar.coralCount <= 9), isTrue);

        final correctWeight = a.likelihoodNumerator(a.jars[a.correctJarIndex]);
        final otherWeight = a.likelihoodNumerator(a.jars[1 - a.correctJarIndex]);
        expect(correctWeight, greaterThan(otherWeight));
      }
    });

    test('seeded generation stays distinguishable over many seeds', () {
      for (var seed = 0; seed < 200; seed++) {
        final session = ChanceGardenSession(seed: seed);
        for (final round in session.rounds) {
          expect(round.correctJarIndex, inInclusiveRange(0, 1));
          expect(
            round.likelihoodNumerator(round.jars[round.correctJarIndex]),
            greaterThan(round.likelihoodNumerator(round.jars[1 - round.correctJarIndex])),
          );
        }
      }
    });

    test('invalid answers do not change state and pass score is earned', () {
      final session = ChanceGardenSession(seed: 29);
      expect(session.answer(-1), isFalse);
      expect(session.answer(2), isFalse);
      expect(session.round, 0);
      expect(session.correct, 0);
      expect(session.mistakes, 0);

      for (var round = 0; round < ChanceGardenSession.roundCount; round++) {
        final answer = round < ChanceGardenSession.passScore
            ? session.current.correctJarIndex
            : 1 - session.current.correctJarIndex;
        expect(session.answer(answer), isTrue);
      }
      expect(session.finished, isTrue);
      expect(session.passed, isTrue);
      expect(session.correct, ChanceGardenSession.passScore);
      expect(session.mistakes, ChanceGardenSession.roundCount - ChanceGardenSession.passScore);
      expect(session.answer(0), isFalse);
    });
  });
}
