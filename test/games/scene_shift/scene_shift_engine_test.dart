import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/scene_shift/scene_shift_engine.dart';

void main() {
  group('SceneShiftSession', () {
    test('seeded rounds repeat and change exactly one tile', () {
      final first = SceneShiftSession(seed: 508);
      final second = SceneShiftSession(seed: 508);

      expect(first.rounds.length, SceneShiftSession.roundCount);
      for (var index = 0; index < first.rounds.length; index++) {
        final a = first.rounds[index];
        final b = second.rounds[index];
        expect(a.before, orderedEquals(b.before));
        expect(a.after, orderedEquals(b.after));
        expect(a.changedIndex, b.changedIndex);
        final changes = [
          for (var tile = 0; tile < a.before.length; tile++)
            if (a.before[tile] != a.after[tile]) tile,
        ];
        expect(changes, [a.changedIndex]);
      }
    });

    test('cannot answer before revealing the new scene', () {
      final session = SceneShiftSession(seed: 81);

      expect(session.showingPreview, isTrue);
      expect(session.choose(session.current.changedIndex),
          SceneShiftResult.invalid);
      expect(session.roundIndex, 0);
      expect(session.correctFinds, 0);
      expect(session.mistakes, 0);
    });

    test('invalid reveal and tile indices leave state unchanged', () {
      final session = SceneShiftSession(seed: 32);

      expect(session.reveal(), isTrue);
      expect(session.reveal(), isFalse);
      expect(session.choose(-1), SceneShiftResult.invalid);
      expect(session.choose(session.current.after.length),
          SceneShiftResult.invalid);
      expect(session.roundIndex, 0);
      expect(session.mistakes, 0);
    });

    test('incorrect location counts a mistake and allows another pick', () {
      final session = SceneShiftSession(seed: 98);
      session.reveal();
      final wrong = session.current.changedIndex == 0 ? 1 : 0;

      expect(session.choose(wrong), SceneShiftResult.incorrect);
      expect(session.awaitingAnswer, isTrue);
      expect(session.roundIndex, 0);
      expect(session.mistakes, 1);
      expect(session.choose(session.current.changedIndex),
          SceneShiftResult.correct);
      expect(session.roundIndex, 1);
      expect(session.correctFinds, 1);
    });

    test('correct locations finish the session and reject further actions', () {
      final session = SceneShiftSession(seed: 604);

      for (var index = 0; index < SceneShiftSession.roundCount; index++) {
        expect(session.reveal(), isTrue);
        expect(
          session.choose(session.current.changedIndex),
          index == SceneShiftSession.roundCount - 1
              ? SceneShiftResult.complete
              : SceneShiftResult.correct,
        );
      }

      expect(session.finished, isTrue);
      expect(session.passed, isTrue);
      expect(session.progress, 1);
      expect(session.correctFinds, SceneShiftSession.roundCount);
      expect(session.reveal(), isFalse);
      expect(session.choose(0), SceneShiftResult.invalid);
    });

    test('higher difficulty adds tiles while keeping one solvable change', () {
      final easy = SceneShiftSession(seed: 10, level: 1);
      final harder = SceneShiftSession(seed: 10, level: 4);

      expect(harder.rounds.first.before.length,
          greaterThan(easy.rounds.first.before.length));
      for (final scene in harder.rounds) {
        expect(scene.before.length, lessThanOrEqualTo(20));
        expect(
          [
            for (var index = 0; index < scene.before.length; index++)
              if (scene.before[index] != scene.after[index]) index,
          ],
          [scene.changedIndex],
        );
      }
    });
  });
}
