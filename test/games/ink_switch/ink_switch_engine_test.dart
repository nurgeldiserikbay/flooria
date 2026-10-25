import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/ink_switch/ink_switch_engine.dart';

void main() {
  group('InkSwitchSession', () {
    test('seeded rounds are repeatable and always conflict', () {
      final first = InkSwitchSession(seed: 425);
      final second = InkSwitchSession(seed: 425);
      expect(first.rounds.length, InkSwitchSession.roundCount);
      for (var index = 0; index < first.rounds.length; index++) {
        final a = first.rounds[index];
        final b = second.rounds[index];
        expect(a.wordHue, b.wordHue);
        expect(a.inkHue, b.inkHue);
        expect(a.options, b.options);
        expect(a.wordHue, isNot(a.inkHue));
        expect(a.options, hasLength(4));
        expect(a.options.toSet(), hasLength(4));
        expect(a.options.where((hue) => hue == a.inkHue), hasLength(1));
        expect(a.options.where((hue) => hue == a.wordHue), hasLength(1));
      }
    });

    test('invalid choices do not change progress or score', () {
      final session = InkSwitchSession(seed: 3);
      expect(session.answer(-1), isFalse);
      expect(session.answer(4), isFalse);
      expect(session.round, 0);
      expect(session.correct, 0);
      expect(session.mistakes, 0);
    });

    test('valid answers record the earned score and enforce the pass target', () {
      final session = InkSwitchSession(seed: 91);
      for (var round = 0; round < InkSwitchSession.roundCount; round++) {
        final answer = round < InkSwitchSession.passScore
            ? session.current.correctIndex
            : (session.current.correctIndex + 1) % session.current.options.length;
        expect(session.answer(answer), isTrue);
      }
      expect(session.finished, isTrue);
      expect(session.correct, InkSwitchSession.passScore);
      expect(session.mistakes, InkSwitchSession.roundCount - InkSwitchSession.passScore);
      expect(session.passed, isTrue);
      expect(session.answer(0), isFalse);
    });
  });
}
