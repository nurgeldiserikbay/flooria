import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/matchstick_math/matchstick_math_engine.dart';

void main() {
  group('MatchstickMathSession', () {
    test('seeded puzzles repeat and each has one true move', () {
      final first = MatchstickMathSession(seed: 431);
      final second = MatchstickMathSession(seed: 431);
      expect(first.puzzles.length, MatchstickMathSession.roundCount);

      for (var round = 0; round < first.puzzles.length; round++) {
        final a = first.puzzles[round];
        final b = second.puzzles[round];
        expect(a.equation.glyphs, orderedEquals(b.equation.glyphs));
        expect(a.choices, orderedEquals(b.choices));
        expect(a.choices.length, 3);
        expect(a.equation.isTrue, isFalse);

        final solutions = a.equation.possibleMoves
            .where((move) => a.equation.apply(move)?.isTrue ?? false)
            .toList();
        expect(solutions, [a.answer]);
        expect(a.equation.apply(a.answer)?.isTrue, isTrue);
        expect(a.choices.where((move) => move == a.answer), hasLength(1));
      }
    });

    test('glyph representations map back to every supported symbol', () {
      for (final glyph in <String>[
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '-', '=',
      ]) {
        expect(
          MatchstickGlyph.fromSegments(MatchstickGlyph.segmentsFor(glyph)),
          glyph,
        );
      }
    });

    test('invalid choices do not change session state', () {
      final session = MatchstickMathSession(seed: 10);
      expect(session.choose(-1), MatchstickPickResult.invalid);
      expect(session.choose(session.current.choices.length),
          MatchstickPickResult.invalid);
      expect(session.roundIndex, 0);
      expect(session.correctAnswers, 0);
      expect(session.mistakes, 0);
    });

    test('incorrect move counts a slip; correct move advances', () {
      final session = MatchstickMathSession(seed: 61);
      final wrongIndex = session.current.choices.indexWhere(
        (move) => move != session.current.answer,
      );
      expect(session.choose(wrongIndex), MatchstickPickResult.incorrect);
      expect(session.mistakes, 1);
      expect(session.roundIndex, 0);
      final answerIndex =
          session.current.choices.indexOf(session.current.answer);
      expect(session.choose(answerIndex), MatchstickPickResult.correct);
      expect(session.roundIndex, 1);
      expect(session.correctAnswers, 1);
    });

    test('solves all puzzles and rejects input after completion', () {
      final session = MatchstickMathSession(seed: 93);
      for (var round = 0; round < MatchstickMathSession.roundCount; round++) {
        final answer = session.current.choices.indexOf(session.current.answer);
        expect(session.choose(answer),
            round == MatchstickMathSession.roundCount - 1
                ? MatchstickPickResult.complete
                : MatchstickPickResult.correct);
      }
      expect(session.finished, isTrue);
      expect(session.progress, 1);
      expect(session.correctAnswers, MatchstickMathSession.roundCount);
      expect(session.choose(0), MatchstickPickResult.invalid);
    });
  });
}
