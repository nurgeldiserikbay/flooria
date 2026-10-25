import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/analogy_lab/analogy_lab_engine.dart';

void main() {
  group('AnalogyLabSession', () {
    test('seeded analogies repeat and each answer list is unique', () {
      final first = AnalogyLabSession(seed: 5281);
      final second = AnalogyLabSession(seed: 5281);

      expect(first.rounds.length, AnalogyLabSession.roundCount);
      for (var index = 0; index < first.rounds.length; index++) {
        final a = first.rounds[index];
        final b = second.rounds[index];
        expect(a.exampleFrom, b.exampleFrom);
        expect(a.exampleTo, b.exampleTo);
        expect(a.prompt, b.prompt);
        expect(a.options, b.options);
        expect(a.correctIndex, b.correctIndex);
        expect(a.options.toSet().length, 4);
        expect(a.changedFeatures, 1);
      }
    });

    test('same feature changes from example pair produce the answer', () {
      for (var seed = 0; seed < 80; seed++) {
        final session = AnalogyLabSession(seed: seed, level: 10);
        for (final round in session.rounds) {
          final a = round.exampleFrom;
          final b = round.exampleTo;
          final prompt = round.prompt;

          final shapeDelta =
              (b.shape.index - a.shape.index) % AnalogyShape.values.length;
          final colorDelta =
              (b.color.index - a.color.index) % AnalogyColor.values.length;
          final countDelta = (b.count - a.count) % 3;
          final expected = AnalogyToken(
            shape: AnalogyShape.values[
                (prompt.shape.index + shapeDelta) % AnalogyShape.values.length],
            color: AnalogyColor.values[
                (prompt.color.index + colorDelta) % AnalogyColor.values.length],
            count: (prompt.count - 1 + countDelta) % 3 + 1,
          );

          expect(round.changedFeatures, 3);
          expect(round.answer, expected);
          expect(round.options.where((option) => option == expected).length, 1);
        }
      }
    });

    test('invalid choices leave score and progress unchanged', () {
      final session = AnalogyLabSession(seed: 27);

      expect(session.submit(-1), AnalogySubmitResult.invalid);
      expect(session.submit(4), AnalogySubmitResult.invalid);
      expect(session.roundIndex, 0);
      expect(session.correctCount, 0);
      expect(session.mistakes, 0);
      expect(session.progress, 0);
    });

    test('correct and incorrect choices update results once', () {
      final session = AnalogyLabSession(seed: 64);
      final wrongIndex = (session.current.correctIndex + 1) % 4;

      expect(session.submit(wrongIndex), AnalogySubmitResult.incorrect);
      expect(session.roundIndex, 1);
      expect(session.mistakes, 1);
      expect(session.correctCount, 0);

      expect(
        session.submit(session.current.correctIndex),
        AnalogySubmitResult.correct,
      );
      expect(session.roundIndex, 2);
      expect(session.correctCount, 1);
      expect(session.mistakes, 1);
    });

    test('completes and passes at six correct answers', () {
      final session = AnalogyLabSession(seed: 91);

      for (var index = 0; index < AnalogyLabSession.roundCount; index++) {
        final choice = index < AnalogyLabSession.passScore
            ? session.current.correctIndex
            : (session.current.correctIndex + 1) % 4;
        final result = session.submit(choice);
        expect(
          result,
          index == AnalogyLabSession.roundCount - 1
              ? AnalogySubmitResult.complete
              : index < AnalogyLabSession.passScore
                  ? AnalogySubmitResult.correct
                  : AnalogySubmitResult.incorrect,
        );
      }

      expect(session.finished, isTrue);
      expect(session.passed, isTrue);
      expect(session.correctCount, AnalogyLabSession.passScore);
      expect(session.mistakes, 2);
      expect(session.progress, 1);
      expect(session.submit(0), AnalogySubmitResult.invalid);
    });

    test('higher levels use more attributes in each transformation', () {
      final easy = AnalogyLabSession(seed: 5, level: 1);
      final medium = AnalogyLabSession(seed: 5, level: 5);
      final hard = AnalogyLabSession(seed: 5, level: 12);

      expect(easy.rounds.every((round) => round.changedFeatures == 1), isTrue);
      expect(
        medium.rounds.every((round) => round.changedFeatures == 2),
        isTrue,
      );
      expect(hard.rounds.every((round) => round.changedFeatures == 3), isTrue);
    });
  });
}
