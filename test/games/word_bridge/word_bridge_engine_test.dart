import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/word_bridge/word_bridge_engine.dart';

void main() {
  group('WordBridgeSession', () {
    test('seeded questions repeat and ramp through three difficulty tiers', () {
      final first = WordBridgeSession(seed: 719);
      final second = WordBridgeSession(seed: 719);
      expect(first.rounds, hasLength(WordBridgeSession.roundCount));
      expect(first.rounds.map((question) => question.difficulty),
          [1, 1, 1, 2, 2, 2, 2, 3, 3, 3]);

      for (var index = 0; index < first.rounds.length; index++) {
        final a = first.rounds[index];
        final b = second.rounds[index];
        expect(a.firstWord, b.firstWord);
        expect(a.relatedWord, b.relatedWord);
        expect(a.bridgeWord, b.bridgeWord);
        expect(a.options, b.options);
        expect(a.correctIndex, b.correctIndex);
        expect(a.options, hasLength(3));
        expect(a.options.toSet(), hasLength(3));
        expect(a.correctIndex, inInclusiveRange(0, 2));
        expect(a.options[a.correctIndex], isNotEmpty);
      }
    });

    test('invalid choices do not alter the session', () {
      final session = WordBridgeSession(seed: 22);
      expect(session.answer(-1), isFalse);
      expect(session.answer(3), isFalse);
      expect(session.round, 0);
      expect(session.correct, 0);
      expect(session.mistakes, 0);
    });

    test('correct answers pass at the threshold and post-finish taps are ignored', () {
      final session = WordBridgeSession(seed: 91);
      for (var index = 0; index < WordBridgeSession.roundCount; index++) {
        final answer = index < WordBridgeSession.passScore
            ? session.current.correctIndex
            : (session.current.correctIndex + 1) % session.current.options.length;
        expect(session.answer(answer), isTrue);
      }
      expect(session.finished, isTrue);
      expect(session.correct, WordBridgeSession.passScore);
      expect(session.mistakes, WordBridgeSession.roundCount - WordBridgeSession.passScore);
      expect(session.passed, isTrue);
      expect(session.answer(0), isFalse);
    });
  });
}
