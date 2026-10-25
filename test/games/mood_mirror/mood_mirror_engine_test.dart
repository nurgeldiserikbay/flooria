import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/mood_mirror/mood_mirror_engine.dart';

void main() {
  group('MoodMirrorSession', () {
    test('seeded sessions repeat and every round has one correct option', () {
      final first = MoodMirrorSession(seed: 360);
      final second = MoodMirrorSession(seed: 360);

      expect(first.rounds.length, MoodMirrorSession.roundCount);
      expect(
        first.rounds.map((round) => round.emotion),
        orderedEquals(second.rounds.map((round) => round.emotion)),
      );
      for (var index = 0; index < first.rounds.length; index++) {
        final round = first.rounds[index];
        expect(round.choices, orderedEquals(second.rounds[index].choices));
        expect(round.choices.length, 3);
        expect(round.choices.where((choice) => choice == round.emotion),
            hasLength(1));
      }
      expect(first.rounds.map((round) => round.emotion).toSet(),
          FacialEmotion.values.toSet());
    });

    test('invalid options do not change counters or advance', () {
      final session = MoodMirrorSession(seed: 17);
      final invalid = FacialEmotion.values.firstWhere(
        (emotion) => !session.current.choices.contains(emotion),
      );

      expect(session.respond(invalid), MoodResponseResult.invalid);
      expect(session.roundIndex, 0);
      expect(session.correctAnswers, 0);
      expect(session.mistakes, 0);
    });

    test('wrong choice counts a mistake and advances once', () {
      final session = MoodMirrorSession(seed: 42);
      final wrong = session.current.choices.firstWhere(
        (emotion) => emotion != session.current.emotion,
      );

      expect(session.respond(wrong), MoodResponseResult.incorrect);
      expect(session.roundIndex, 1);
      expect(session.correctAnswers, 0);
      expect(session.mistakes, 1);
    });

    test('higher levels show more emotion choices', () {
      final easy = MoodMirrorSession(seed: 91, level: 1);
      final hard = MoodMirrorSession(seed: 91, level: 8);

      expect(easy.current.choices.length, 3);
      expect(hard.current.choices.length, 4);
      for (final round in hard.rounds) {
        expect(round.choices, contains(round.emotion));
        expect(round.choices.toSet().length, round.choices.length);
      }
    });

    test('five correct answers earn completion; later responses are ignored',
        () {
      final session = MoodMirrorSession(seed: 5);

      for (var index = 0; index < MoodMirrorSession.roundCount; index++) {
        final result = session.respond(session.current.emotion);
        expect(
          result,
          index == MoodMirrorSession.roundCount - 1
              ? MoodResponseResult.complete
              : MoodResponseResult.correct,
        );
      }

      expect(session.finished, isTrue);
      expect(session.passed, isTrue);
      expect(session.progress, 1);
      expect(session.correctAnswers, MoodMirrorSession.roundCount);
      expect(session.respond(FacialEmotion.joy), MoodResponseResult.invalid);
    });

    test('a low-accuracy session does not pass', () {
      final session = MoodMirrorSession(seed: 81);

      for (var index = 0; index < MoodMirrorSession.roundCount; index++) {
        final wrong = session.current.choices.firstWhere(
          (emotion) => emotion != session.current.emotion,
        );
        session.respond(wrong);
      }

      expect(session.finished, isTrue);
      expect(session.passed, isFalse);
      expect(session.correctAnswers, 0);
      expect(session.mistakes, MoodMirrorSession.roundCount);
    });
  });
}
