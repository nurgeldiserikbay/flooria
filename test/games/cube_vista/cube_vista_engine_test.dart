import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/cube_vista/cube_vista_engine.dart';

void main() {
  group('CubeVistaSession', () {
    test('seeded structures repeat and only one option matches all views', () {
      final first = CubeVistaSession(seed: 914);
      final second = CubeVistaSession(seed: 914);
      expect(first.puzzles.length, CubeVistaSession.roundCount);

      for (var round = 0; round < first.puzzles.length; round++) {
        final a = first.puzzles[round];
        final b = second.puzzles[round];
        expect(a.clues.front, orderedEquals(b.clues.front));
        expect(a.clues.side, orderedEquals(b.clues.side));
        expect(a.clues.footprint, orderedEquals(b.clues.footprint));
        expect(a.options.length, 3);
        expect(a.options.map((layout) => layout.heights).toList(),
            orderedEquals(b.options.map((layout) => layout.heights).toList()));

        final matching = <int>[
          for (var index = 0; index < a.options.length; index++)
            if (a.clues.matches(a.options[index])) index,
        ];
        expect(matching, [a.answerIndex]);
      }
    });

    test('invalid option indices do not change state', () {
      final session = CubeVistaSession(seed: 8);
      expect(session.choose(-1), CubePickResult.invalid);
      expect(session.choose(session.current.options.length),
          CubePickResult.invalid);
      expect(session.roundIndex, 0);
      expect(session.correctAnswers, 0);
      expect(session.mistakes, 0);
    });

    test('wrong layout counts a mistake and correct layout advances', () {
      final session = CubeVistaSession(seed: 22);
      final wrong = (session.current.answerIndex + 1) % 3;
      expect(session.choose(wrong), CubePickResult.incorrect);
      expect(session.mistakes, 1);
      expect(session.choose(session.current.answerIndex),
          CubePickResult.correct);
      expect(session.roundIndex, 1);
      expect(session.correctAnswers, 1);
      expect(session.progress, 1 / CubeVistaSession.roundCount);
    });

    test('solves all blueprints and rejects input after completion', () {
      final session = CubeVistaSession(seed: 33);
      for (var round = 0; round < CubeVistaSession.roundCount; round++) {
        expect(session.choose(session.current.answerIndex),
            round == CubeVistaSession.roundCount - 1
                ? CubePickResult.complete
                : CubePickResult.correct);
      }
      expect(session.finished, isTrue);
      expect(session.progress, 1);
      expect(session.correctAnswers, CubeVistaSession.roundCount);
      expect(session.choose(0), CubePickResult.invalid);
    });
  });
}
