import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/belief_detective/belief_detective_engine.dart';

void main() {
  group('BeliefDetectiveSession', () {
    test('seeded stories repeat and options are complete and unique', () {
      final first = BeliefDetectiveSession(seed: 77);
      final second = BeliefDetectiveSession(seed: 77);

      expect(first.rounds.length, BeliefDetectiveSession.roundCount);
      for (var index = 0; index < first.rounds.length; index++) {
        final a = first.rounds[index];
        final b = second.rounds[index];
        expect(a.character, b.character);
        expect(a.objectName, b.objectName);
        expect(a.initialPlace, b.initialPlace);
        expect(a.options, b.options);
        expect(a.correctPlace, b.correctPlace);
        expect(a.options.toSet().length, BeliefPlace.values.length);
        expect(a.options, contains(a.correctPlace));
      }
    });

    test('moves form a valid sequence and beliefs follow observed moves', () {
      for (var seed = 0; seed < 100; seed++) {
        final session = BeliefDetectiveSession(seed: seed);
        for (final round in session.rounds) {
          var actual = round.initialPlace;
          var belief = round.initialPlace;
          var hasUnseenMove = false;

          for (final move in round.moves) {
            expect(move.from, actual);
            expect(move.to, isNot(move.from));
            actual = move.to;
            if (move.characterSaw) {
              belief = move.to;
            } else {
              hasUnseenMove = true;
            }
          }

          expect(hasUnseenMove, isTrue);
          expect(actual, round.actualPlace);
          expect(belief, round.beliefPlace);
          expect(belief, round.correctPlace);
        }
      }
    });

    test('answers after completion are invalid and do not change score', () {
      final session = BeliefDetectiveSession(seed: 18);
      for (var index = 0; index < BeliefDetectiveSession.roundCount; index++) {
        session.answer(session.current.correctPlace);
      }

      expect(session.answer(BeliefPlace.garden), BeliefAnswerResult.invalid);
      expect(session.roundIndex, BeliefDetectiveSession.roundCount);
      expect(session.correctCount, BeliefDetectiveSession.roundCount);
      expect(session.mistakes, 0);
      expect(session.progress, 1);
    });

    test('answers advance once and track correct and incorrect choices', () {
      final session = BeliefDetectiveSession(seed: 24);
      final correct = session.current.correctPlace;
      final wrong = BeliefPlace.values.firstWhere((place) => place != correct);

      expect(session.answer(wrong), BeliefAnswerResult.incorrect);
      expect(session.roundIndex, 1);
      expect(session.mistakes, 1);
      expect(session.correctCount, 0);

      expect(session.answer(session.current.correctPlace),
          BeliefAnswerResult.correct);
      expect(session.roundIndex, 2);
      expect(session.correctCount, 1);
      expect(session.mistakes, 1);
    });

    test('four correct answers are enough to pass the six story session', () {
      final session = BeliefDetectiveSession(seed: 91);

      for (var index = 0; index < BeliefDetectiveSession.roundCount; index++) {
        final place = index < BeliefDetectiveSession.passScore
            ? session.current.correctPlace
            : BeliefPlace.values
                .firstWhere((place) => place != session.current.correctPlace);
        final result = session.answer(place);
        expect(
          result,
          index == BeliefDetectiveSession.roundCount - 1
              ? BeliefAnswerResult.complete
              : index < BeliefDetectiveSession.passScore
                  ? BeliefAnswerResult.correct
                  : BeliefAnswerResult.incorrect,
        );
      }

      expect(session.finished, isTrue);
      expect(session.passed, isTrue);
      expect(session.correctCount, 4);
      expect(session.mistakes, 2);
      expect(session.progress, 1);
      expect(
        session.answer(BeliefPlace.garden),
        BeliefAnswerResult.invalid,
      );
    });

    test('higher levels show more changes to track', () {
      final easy = BeliefDetectiveSession(seed: 5, level: 1);
      final hard = BeliefDetectiveSession(seed: 5, level: 12);

      expect(
        easy.rounds.every((round) => round.moves.length <= 3),
        isTrue,
      );
      expect(
        hard.rounds.every((round) => round.moves.length >= 4),
        isTrue,
      );
    });
  });
}
