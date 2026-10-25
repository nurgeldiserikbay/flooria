import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/beat_bloom/beat_bloom_engine.dart';

void main() {
  group('BeatBloomSession', () {
    test('seed produces repeatable tempos in the supported range', () {
      final first = BeatBloomSession(seed: 281);
      final second = BeatBloomSession(seed: 281);

      for (var round = 0; round < BeatBloomSession.roundCount; round++) {
        expect(first.currentIntervalMillis, second.currentIntervalMillis);
        expect(BeatBloomSession.tempoChoices,
            contains(first.currentIntervalMillis));
        if (round < BeatBloomSession.roundCount - 1) {
          expect(first.advance(), isFalse);
          _tapRound(first, onBeat: true);
          expect(first.advance(), isTrue);
          expect(second.advance(), isFalse);
          _tapRound(second, onBeat: true);
          expect(second.advance(), isTrue);
        }
      }
    });

    test('scores taps against beat tolerance and rejects invalid actions', () {
      final session = BeatBloomSession(seed: 9);
      final interval = session.currentIntervalMillis;
      final tolerance = session.toleranceMillis;

      expect(session.tapAt(-1), BeatBloomTapResult.invalid);
      expect(session.tapCount, 0);
      expect(session.tapAt(interval + tolerance), BeatBloomTapResult.onBeat);
      expect(session.tapCount, 1);
      expect(session.tapAt(interval * 2 + tolerance + 1),
          BeatBloomTapResult.offBeat);
      expect(session.offBeatTaps, 1);
      expect(session.advance(), isFalse);
    });

    test('six taps complete a round and only four accurate rounds pass', () {
      final session = BeatBloomSession(seed: 15);
      for (var round = 0; round < BeatBloomSession.roundCount; round++) {
        final result = _tapRound(session, accurateTaps: round < 4 ? 4 : 3);
        expect(result, BeatBloomTapResult.roundComplete);
        if (round < BeatBloomSession.roundCount - 1) {
          expect(session.roundComplete, isTrue);
          expect(session.advance(), isTrue);
        }
      }

      expect(session.finished, isTrue);
      expect(session.passed, isTrue);
      expect(session.correctRounds, 4);
      expect(session.offBeatTaps, 14);
      expect(session.tapAt(1), BeatBloomTapResult.invalid);
      expect(session.advance(), isFalse);
    });

    test('three accurate rounds do not pass', () {
      final session = BeatBloomSession(seed: 15);
      for (var round = 0; round < BeatBloomSession.roundCount; round++) {
        _tapRound(session, onBeat: round < 3);
        if (round < BeatBloomSession.roundCount - 1) session.advance();
      }
      expect(session.finished, isTrue);
      expect(session.passed, isFalse);
      expect(session.correctRounds, 3);
    });
  });
}

BeatBloomTapResult _tapRound(BeatBloomSession session,
    {bool? onBeat, int? accurateTaps}) {
  var result = BeatBloomTapResult.invalid;
  final interval = session.currentIntervalMillis;
  for (var tap = 1; tap <= BeatBloomSession.tapsPerRound; tap++) {
    final isAccurate = onBeat ?? tap <= accurateTaps!;
    result = session.tapAt(tap * interval + (isAccurate ? 0 : 300));
  }
  return result;
}
