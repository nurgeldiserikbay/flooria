import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/cue_keeper/cue_keeper_engine.dart';

void main() {
  group('CueKeeperSession', () {
    test('seeded streams repeat and contain the requested cue', () {
      for (var seed = 0; seed < 200; seed++) {
        final first = CueKeeperSession(seed: seed);
        final second = CueKeeperSession(seed: seed);
        expect(first.sequence, second.sequence);
        expect(first.targetSymbol, second.targetSymbol);
        expect(first.targetOccurrence, second.targetOccurrence);
        expect(first.sequence, hasLength(CueKeeperSession.cuesPerRound));
        expect(first.sequence.where((symbol) => symbol == first.targetSymbol),
            hasLength(greaterThanOrEqualTo(first.targetOccurrence)));

        var targetMoments = 0;
        for (var cue = 0; cue < CueKeeperSession.cuesPerRound; cue++) {
          expect(first.nextCue(), CueKeeperAdvanceResult.cueRevealed);
          expect(second.nextCue(), CueKeeperAdvanceResult.cueRevealed);
          expect(first.currentSymbol, second.currentSymbol);
          if (first.targetNow) targetMoments++;
        }
        expect(targetMoments, 1);
        expect(first.nextCue(), CueKeeperAdvanceResult.streamComplete);
        expect(second.nextCue(), CueKeeperAdvanceResult.streamComplete);
        expect(first.lastRoundCorrect, isFalse);
      }
    });

    test('acts only at the remembered occurrence and ignores duplicates', () {
      final session = CueKeeperSession(seed: 31);
      expect(session.actNow(), CueKeeperActionResult.invalid);
      expect(session.mistakes, 0);

      while (!session.targetNow) {
        expect(session.nextCue(), CueKeeperAdvanceResult.cueRevealed);
      }
      expect(session.actNow(), CueKeeperActionResult.correct);
      expect(session.actNow(), CueKeeperActionResult.invalid);
      expect(session.mistakes, 0);
      expect(
        [CueKeeperAdvanceResult.cueRevealed, CueKeeperAdvanceResult.streamComplete],
        contains(session.nextCue()),
      );
      expect(session.actionCorrect, isTrue);
    });

    test('early action or skipped intention counts one miss only', () {
      final early = CueKeeperSession(seed: 47);
      early.nextCue();
      expect(early.targetNow, isFalse);
      expect(early.actNow(), CueKeeperActionResult.incorrect);
      expect(early.mistakes, 1);
      _finishStream(early, actAtTarget: false);
      expect(early.mistakes, 1);
      expect(early.lastRoundCorrect, isFalse);

      final skipped = CueKeeperSession(seed: 47);
      while (!skipped.targetNow) {
        skipped.nextCue();
      }
      expect(
        [CueKeeperAdvanceResult.cueRevealed, CueKeeperAdvanceResult.streamComplete],
        contains(skipped.nextCue()),
      );
      expect(skipped.mistakes, 1);
      expect(skipped.actNow(), CueKeeperActionResult.invalid);
      _finishStream(skipped, actAtTarget: false);
      expect(skipped.mistakes, 1);
    });

    test('six rounds complete and four remembered intentions pass', () {
      final passing = CueKeeperSession(seed: 91);
      for (var round = 0; round < CueKeeperSession.roundCount; round++) {
        _finishStream(passing, actAtTarget: round < 4);
        if (round < CueKeeperSession.roundCount - 1) {
          expect(passing.roundComplete, isTrue);
          expect(passing.nextRound(), isTrue);
        }
      }
      expect(passing.finished, isTrue);
      expect(passing.passed, isTrue);
      expect(passing.correctRounds, 4);
      expect(passing.mistakes, 2);
      expect(passing.nextRound(), isFalse);
      expect(passing.nextCue(), CueKeeperAdvanceResult.invalid);

      final failing = CueKeeperSession(seed: 91);
      for (var round = 0; round < CueKeeperSession.roundCount; round++) {
        _finishStream(failing, actAtTarget: round < 3);
        if (round < CueKeeperSession.roundCount - 1) failing.nextRound();
      }
      expect(failing.finished, isTrue);
      expect(failing.passed, isFalse);
      expect(failing.correctRounds, 3);
    });
  });
}

void _finishStream(CueKeeperSession session, {required bool actAtTarget}) {
  while (!session.roundComplete && !session.finished) {
    final result = session.nextCue();
    if (result == CueKeeperAdvanceResult.cueRevealed &&
        actAtTarget &&
        session.targetNow) {
      expect(session.actNow(), CueKeeperActionResult.correct);
    }
  }
}
