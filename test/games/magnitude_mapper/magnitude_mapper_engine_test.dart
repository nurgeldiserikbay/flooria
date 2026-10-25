import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/magnitude_mapper/magnitude_mapper_engine.dart';

void main() {
  group('MagnitudeMapperSession', () {
    test('seeded number lines repeat and targets stay inside the range', () {
      final first = MagnitudeMapperSession(seed: 711);
      final second = MagnitudeMapperSession(seed: 711);

      expect(first.rounds.length, MagnitudeMapperSession.roundCount);
      for (var index = 0; index < first.rounds.length; index++) {
        final a = first.rounds[index];
        final b = second.rounds[index];
        expect(a.minimum, b.minimum);
        expect(a.maximum, b.maximum);
        expect(a.target, b.target);
        expect(a.target, greaterThan(a.minimum));
        expect(a.target, lessThan(a.maximum));
        expect(a.targetPosition, inInclusiveRange(0, 1));
        expect(a.tolerance, greaterThan(0));
      }
    });

    test('invalid slider values do not change the current estimate', () {
      final session = MagnitudeMapperSession(seed: 22);

      expect(session.setGuess(double.nan), isFalse);
      expect(session.setGuess(double.infinity), isFalse);
      expect(session.setGuess(-.01), isFalse);
      expect(session.setGuess(1.01), isFalse);
      expect(session.guessPosition, .5);
      expect(session.roundIndex, 0);
    });

    test('incorrect estimate records a miss and advances the line', () {
      final session = MagnitudeMapperSession(seed: 32);
      final wrongPosition =
          session.current.targetPosition < .5 ? 1.0 : 0.0;

      expect(session.setGuess(wrongPosition), isTrue);
      expect(session.submit(), MagnitudeSubmitResult.inaccurate);
      expect(session.roundIndex, 1);
      expect(session.mistakes, 1);
      expect(session.accurateCount, 0);
      expect(session.guessPosition, .5);
    });

    test('target estimate is accurate and six responses complete', () {
      final session = MagnitudeMapperSession(seed: 91);

      for (var index = 0; index < MagnitudeMapperSession.roundCount; index++) {
        expect(session.setGuess(session.current.targetPosition), isTrue);
        expect(
          session.submit(),
          index == MagnitudeMapperSession.roundCount - 1
              ? MagnitudeSubmitResult.complete
              : MagnitudeSubmitResult.accurate,
        );
      }

      expect(session.finished, isTrue);
      expect(session.passed, isTrue);
      expect(session.accurateCount, MagnitudeMapperSession.roundCount);
      expect(session.progress, 1);
      expect(session.submit(), MagnitudeSubmitResult.invalid);
      expect(session.setGuess(.2), isFalse);
    });

    test('high difficulty uses wider ranges and tighter tolerance', () {
      final easy = MagnitudeMapperSession(seed: 5, level: 1);
      final hard = MagnitudeMapperSession(seed: 5, level: 15);

      expect(hard.rounds.last.maximum, greaterThan(easy.rounds.last.maximum));
      expect(hard.rounds.first.toleranceFraction,
          lessThan(easy.rounds.first.toleranceFraction));
      for (final round in hard.rounds) {
        expect(round.target, greaterThan(round.minimum));
        expect(round.target, lessThan(round.maximum));
      }
    });

    test('four accurate placements are enough to pass', () {
      final session = MagnitudeMapperSession(seed: 18);

      for (var index = 0; index < MagnitudeMapperSession.roundCount; index++) {
        if (index < MagnitudeMapperSession.passScore) {
          session.setGuess(session.current.targetPosition);
        } else {
          final wrong = session.current.targetPosition < .5 ? 1.0 : 0.0;
          session.setGuess(wrong);
        }
        session.submit();
      }

      expect(session.accurateCount, MagnitudeMapperSession.passScore);
      expect(session.mistakes, 2);
      expect(session.passed, isTrue);
    });
  });
}
