import 'dart:math';

/// Rules for a short visual beat-synchronization session.
///
/// Every round uses a seeded tempo. Taps are judged against the beat times
/// measured from the start of that round, so the rules remain independent of
/// Flutter and straightforward to replay in tests.
class BeatBloomSession {
  BeatBloomSession({required this.seed}) : _intervals = _makeIntervals(seed);

  static const int roundCount = 6;
  static const int tapsPerRound = 6;
  static const int passScore = 4;
  static const List<int> tempoChoices = [520, 590, 660, 730, 800];

  final int seed;
  final List<int> _intervals;

  int round = 0;
  int tapCount = 0;
  int onBeatTaps = 0;
  int offBeatTaps = 0;
  int correctRounds = 0;
  bool lastRoundAccurate = false;
  bool lastTapOnBeat = false;
  final List<bool> tapAccuracy = <bool>[];

  bool get finished => round >= roundCount;
  bool get roundComplete => !finished && tapCount >= tapsPerRound;
  bool get passed => finished && correctRounds >= passScore;
  int get currentIntervalMillis => finished ? 0 : _intervals[round];
  int get toleranceMillis => (currentIntervalMillis * 0.22).round();

  /// Scores one tap. Invalid timestamps and taps outside an active round do
  /// not change the session.
  BeatBloomTapResult tapAt(int elapsedMillis) {
    if (finished || roundComplete || elapsedMillis < 0) {
      return BeatBloomTapResult.invalid;
    }

    tapCount++;
    final expectedMillis = tapCount * currentIntervalMillis;
    lastTapOnBeat = (elapsedMillis - expectedMillis).abs() <= toleranceMillis;
    if (lastTapOnBeat) {
      onBeatTaps++;
    } else {
      offBeatTaps++;
    }
    tapAccuracy.add(lastTapOnBeat);

    if (roundComplete) {
      lastRoundAccurate = onBeatTaps >= passScore;
      if (lastRoundAccurate) correctRounds++;
      if (round == roundCount - 1) round++;
      return BeatBloomTapResult.roundComplete;
    }
    return lastTapOnBeat
        ? BeatBloomTapResult.onBeat
        : BeatBloomTapResult.offBeat;
  }

  /// Moves to the next rhythm only after all six taps have been recorded.
  bool advance() {
    if (!roundComplete) return false;
    round++;
    tapCount = 0;
    onBeatTaps = 0;
    lastTapOnBeat = false;
    lastRoundAccurate = false;
    tapAccuracy.clear();
    return true;
  }

  static List<int> _makeIntervals(int seed) {
    final random = Random(seed);
    return List<int>.generate(
      roundCount,
      (_) => tempoChoices[random.nextInt(tempoChoices.length)],
      growable: false,
    );
  }
}

enum BeatBloomTapResult { invalid, onBeat, offBeat, roundComplete }
