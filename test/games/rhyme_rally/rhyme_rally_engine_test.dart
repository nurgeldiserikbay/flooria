import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/rhyme_rally/rhyme_rally_engine.dart';

void main() {
  group('RhymeRallySession', () {
    test('same seed and level create identical rounds', () {
      final first = RhymeRallySession(seed: 104, level: 4);
      final second = RhymeRallySession(seed: 104, level: 4);

      expect(first.rounds.length, RhymeRallySession.roundCount);
      for (var index = 0; index < first.rounds.length; index++) {
        final a = first.rounds[index];
        final b = second.rounds[index];
        expect(a.target, b.target);
        expect(a.options, b.options);
        expect(a.correctIndex, b.correctIndex);
      }
    });

    test('every generated question has one matching rhyme family', () {
      final session = RhymeRallySession(seed: 541, level: 5);

      for (final round in session.rounds) {
        final matching = round.options
            .where((word) => word.family == round.target.family)
            .toList();
        expect(matching, [round.correctWord]);
      }
    });

    test('invalid answers do not mutate state; correct answers pass', () {
      final session = RhymeRallySession(seed: 35);
      expect(session.answer(-1), RhymeAnswerResult.invalid);
      expect(session.answer(3), RhymeAnswerResult.invalid);
      expect(session.round, 0);
      expect(session.correct, 0);
      expect(session.mistakes, 0);

      for (var index = 0; index < RhymeRallySession.roundCount; index++) {
        expect(
          session.answer(session.current.correctIndex),
          index == RhymeRallySession.roundCount - 1
              ? RhymeAnswerResult.sessionComplete
              : RhymeAnswerResult.correct,
        );
      }
      expect(session.finished, isTrue);
      expect(session.passed, isTrue);
      expect(session.correct, RhymeRallySession.roundCount);
      expect(session.answer(0), RhymeAnswerResult.invalid);
    });

    test('wrong choices count as misses and passing uses actual score', () {
      final session = RhymeRallySession(seed: 793);
      for (var index = 0; index < RhymeRallySession.roundCount; index++) {
        final round = session.current;
        final wrongChoice = (round.correctIndex + 1) % round.options.length;
        session.answer(index < RhymeRallySession.passScore
            ? round.correctIndex
            : wrongChoice);
      }

      expect(session.correct, RhymeRallySession.passScore);
      expect(session.mistakes, RhymeRallySession.roundCount - RhymeRallySession.passScore);
      expect(session.passed, isTrue);
    });
  });
}
