import 'dart:math';

enum CueKeeperAdvanceResult { invalid, cueRevealed, streamComplete }
enum CueKeeperActionResult { invalid, correct, incorrect }

/// Seeded prospective-memory rounds: remember a delayed action and perform it
/// at the requested occurrence while a stream of symbols advances.
class CueKeeperSession {
  CueKeeperSession({required this.seed}) {
    _newRound();
  }

  static const int roundCount = 6;
  static const int cuesPerRound = 12;
  static const int passScore = 4;
  static const int symbolCount = 4;

  final int seed;

  int round = 0;
  int cueIndex = -1;
  int targetSymbol = 0;
  int targetOccurrence = 2;
  int seenTargetCount = 0;
  int correctRounds = 0;
  int mistakes = 0;
  int? currentSymbol;
  bool actionResolved = false;
  bool actionCorrect = false;
  bool lastRoundCorrect = false;
  bool _roundComplete = false;
  late List<int> sequence;

  bool get finished => round >= roundCount;
  bool get passed => finished && correctRounds >= passScore;
  bool get roundComplete => !finished && _roundComplete;
  bool get targetNow =>
      currentSymbol == targetSymbol && seenTargetCount == targetOccurrence;

  /// Reveals the next stream symbol, or ends the stream after its twelfth cue.
  CueKeeperAdvanceResult nextCue() {
    if (finished || roundComplete) return CueKeeperAdvanceResult.invalid;

    if (targetNow && !actionResolved) _resolveMissedIntention();
    if (cueIndex == cuesPerRound - 1) {
      if (!actionResolved) _resolveMissedIntention();
      lastRoundCorrect = actionCorrect;
      if (lastRoundCorrect) correctRounds++;
      if (round == roundCount - 1) {
        round++;
      } else {
        _roundComplete = true;
      }
      return CueKeeperAdvanceResult.streamComplete;
    }

    cueIndex++;
    currentSymbol = sequence[cueIndex];
    if (currentSymbol == targetSymbol) seenTargetCount++;
    return CueKeeperAdvanceResult.cueRevealed;
  }

  /// Performs the remembered action at the current symbol.
  CueKeeperActionResult actNow() {
    if (finished || roundComplete || cueIndex < 0 || actionResolved) {
      return CueKeeperActionResult.invalid;
    }
    actionResolved = true;
    actionCorrect = targetNow;
    if (actionCorrect) return CueKeeperActionResult.correct;
    mistakes++;
    return CueKeeperActionResult.incorrect;
  }

  /// Begins the next intention only after the previous cue stream has ended.
  bool nextRound() {
    if (!roundComplete) return false;
    round++;
    _roundComplete = false;
    _newRound();
    return true;
  }

  void _resolveMissedIntention() {
    actionResolved = true;
    actionCorrect = false;
    mistakes++;
  }

  void _newRound() {
    if (finished) return;
    final random = Random((seed * 65537 + round * 104729) & 0x7fffffff);
    targetSymbol = random.nextInt(symbolCount);
    targetOccurrence = 2 + random.nextInt(2);

    final positions = List<int>.generate(cuesPerRound, (index) => index)
      ..shuffle(random);
    final generated = List<int>.generate(
      cuesPerRound,
      (_) => random.nextInt(symbolCount),
    );
    for (final position in positions.take(4)) {
      generated[position] = targetSymbol;
    }
    generated.shuffle(random);
    sequence = List<int>.unmodifiable(generated);

    cueIndex = -1;
    seenTargetCount = 0;
    currentSymbol = null;
    actionResolved = false;
    actionCorrect = false;
    lastRoundCorrect = false;
  }
}
