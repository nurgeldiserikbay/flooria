import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/mind_loop/mind_loop_engine.dart';

void main() {
  group('MindLoopSession', () {
    test('seeded sequences repeat and contain four guaranteed matches', () {
      final first = MindLoopSession(seed: 641);
      final second = MindLoopSession(seed: 641);

      expect(first.symbols, orderedEquals(second.symbols));
      expect(first.backSteps, 2);
      expect(
        List<bool>.generate(
          MindLoopSession.roundCount,
          first.isMatchAt,
        ).where((match) => match),
        hasLength(4),
      );
    });

    test('higher levels use three-back rules and preserve fixed matches', () {
      final session = MindLoopSession(seed: 76, level: 8);

      expect(session.backSteps, 3);
      expect(
        List<bool>.generate(
          MindLoopSession.roundCount,
          session.isMatchAt,
        ).where((match) => match),
        hasLength(4),
      );
    });

    test('invalid trial indices throw without changing the session', () {
      final session = MindLoopSession(seed: 14);

      expect(() => session.isMatchAt(-1), throwsRangeError);
      expect(
        () => session.isMatchAt(MindLoopSession.roundCount),
        throwsRangeError,
      );
      expect(session.trialIndex, 0);
      expect(session.correctAnswers, 0);
      expect(session.mistakes, 0);
    });

    test('wrong answers count but still advance one trial', () {
      final session = MindLoopSession(seed: 34);
      final answer = session.currentIsMatch;

      expect(session.respond(!answer), LoopResponseResult.incorrect);
      expect(session.trialIndex, 1);
      expect(session.correctAnswers, 0);
      expect(session.mistakes, 1);
    });

    test('perfect play earns completion and rejects later responses', () {
      final session = MindLoopSession(seed: 91);

      for (var index = 0; index < MindLoopSession.roundCount; index++) {
        final result = session.respond(session.currentIsMatch);
        expect(
          result,
          index == MindLoopSession.roundCount - 1
              ? LoopResponseResult.complete
              : LoopResponseResult.correct,
        );
      }

      expect(session.finished, isTrue);
      expect(session.passed, isTrue);
      expect(session.progress, 1);
      expect(session.correctAnswers, MindLoopSession.roundCount);
      expect(session.respond(false), LoopResponseResult.invalid);
      expect(session.trialIndex, MindLoopSession.roundCount);
    });

    test('failed session records errors without earning a pass', () {
      final session = MindLoopSession(seed: 284);

      for (var index = 0; index < MindLoopSession.roundCount; index++) {
        session.respond(!session.currentIsMatch);
      }

      expect(session.finished, isTrue);
      expect(session.passed, isFalse);
      expect(session.correctAnswers, 0);
      expect(session.mistakes, MindLoopSession.roundCount);
    });
  });
}
