import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/hue_mixer/hue_mixer_engine.dart';

void main() {
  group('HueMixerSession', () {
    test('same seed produces the same source colors and ratio options', () {
      final first = HueMixerSession(seed: 81, level: 15);
      final second = HueMixerSession(seed: 81, level: 15);

      expect(first.rounds.length, HueMixerSession.roundCount);
      for (var index = 0; index < first.rounds.length; index++) {
        final a = first.rounds[index];
        final b = second.rounds[index];
        expect(a.firstColor, b.firstColor);
        expect(a.secondColor, b.secondColor);
        expect(a.targetFirstPercent, b.targetFirstPercent);
        expect(a.targetColor, b.targetColor);
        expect(a.ratioChoices, b.ratioChoices);
      }
    });

    test('every target is the exact blend of its shown sources', () {
      for (final level in <int>[1, 6, 15]) {
        for (var seed = 0; seed < 70; seed++) {
          final session = HueMixerSession(seed: seed, level: level);
          for (final round in session.rounds) {
            expect(
              round.targetColor,
              HueColor.blend(
                round.firstColor,
                round.secondColor,
                round.targetFirstPercent,
              ),
            );
            expect(round.ratioChoices, contains(round.targetFirstPercent));
            expect(
              round.ratioChoices.toSet().length,
              session.ratioChoiceCount,
            );
            expect(round.ratioChoices.every((ratio) => ratio >= 0 && ratio <= 100),
                isTrue);
          }
        }
      }
    });

    test('invalid and repeated submissions do not change the round', () {
      final session = HueMixerSession(seed: 19);
      final target = session.current.targetFirstPercent;

      expect(session.submit(-1), HueAnswerResult.invalid);
      expect(session.submit(51), HueAnswerResult.invalid);
      expect(session.roundIndex, 0);
      expect(session.correctAnswers, 0);
      expect(session.mistakes, 0);

      expect(session.submit(target), HueAnswerResult.correct);
      expect(session.submit(target), HueAnswerResult.invalid);
      expect(session.roundIndex, 0);
      expect(session.correctAnswers, 1);
      expect(session.mistakes, 0);
      expect(session.advance(), isTrue);
      expect(session.answered, isFalse);
      expect(session.roundIndex, 1);
    });

    test('four matched blends are enough to pass a five-round session', () {
      final session = HueMixerSession(seed: 31, level: 15);

      for (var index = 0; index < HueMixerSession.roundCount; index++) {
        final round = session.current;
        final ratio = index < HueMixerSession.passScore
            ? round.targetFirstPercent
            : round.ratioChoices.firstWhere(
                (choice) => choice != round.targetFirstPercent,
              );
        final result = session.submit(ratio);
        expect(
          result,
          index < HueMixerSession.passScore
              ? HueAnswerResult.correct
              : HueAnswerResult.incorrect,
        );
        expect(session.advance(), isTrue);
      }

      expect(session.finished, isTrue);
      expect(session.passed, isTrue);
      expect(session.correctAnswers, 4);
      expect(session.mistakes, 1);
      expect(session.progress, 1);
      expect(session.submit(50), HueAnswerResult.invalid);
      expect(session.advance(), isFalse);
    });

    test('ratio options become more precise at higher floors', () {
      final early = HueMixerSession(seed: 11, level: 1);
      final middle = HueMixerSession(seed: 11, level: 6);
      final late = HueMixerSession(seed: 11, level: 15);

      expect(early.ratioChoiceCount, 3);
      expect(middle.ratioChoiceCount, 5);
      expect(late.ratioChoiceCount, 7);
      expect(early.rounds.every((round) => round.targetFirstPercent % 10 == 0),
          isTrue);
      expect(late.rounds.every((round) => round.targetFirstPercent % 5 == 0),
          isTrue);
    });
  });
}
