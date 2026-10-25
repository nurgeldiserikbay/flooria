import 'dart:math';

class TimeSenseRound {
  const TimeSenseRound({required this.targetMillis});

  final int targetMillis;

  int get toleranceMillis => max(350, targetMillis ~/ 5).toInt();

  bool isAccurate(int elapsedMillis) =>
      (elapsedMillis - targetMillis).abs() <= toleranceMillis;

  @override
  bool operator ==(Object other) =>
      other is TimeSenseRound && targetMillis == other.targetMillis;

  @override
  int get hashCode => targetMillis.hashCode;
}

class TimeSenseResult {
  const TimeSenseResult({
    required this.targetMillis,
    required this.elapsedMillis,
    required this.accurate,
  });

  final int targetMillis;
  final int elapsedMillis;
  final bool accurate;
}

/// Estimate a target duration without watching a clock.
class TimeSenseSession {
  TimeSenseSession({required this.seed, int level = 1}) {
    final random = Random(seed);
    final levelRange = 8 + max(0, level - 1).toInt();
    final maxHalfSeconds = levelRange.clamp(8, 12).toInt();
    rounds = List<TimeSenseRound>.unmodifiable(List.generate(
      roundCount,
      (_) => TimeSenseRound(targetMillis: (5 + random.nextInt(maxHalfSeconds - 4)) * 500),
    ));
  }

  static const int roundCount = 5;
  static const int passScore = 3;
  static const int maximumAttemptMillis = 12000;

  final int seed;
  late final List<TimeSenseRound> rounds;
  final List<TimeSenseResult> _results = [];
  int round = 0;

  bool get finished => round >= roundCount;
  int get accurateCount => _results.where((result) => result.accurate).length;
  bool get passed => finished && accurateCount >= passScore;
  double get progress => round / roundCount;
  List<TimeSenseResult> get results => List.unmodifiable(_results);
  TimeSenseRound get current => rounds[round.clamp(0, roundCount - 1).toInt()];

  /// Records one stop time. Values outside the session's timer window and
  /// submissions after completion are ignored without changing the session.
  bool submit(int elapsedMillis) {
    if (finished || elapsedMillis <= 0 || elapsedMillis > maximumAttemptMillis) {
      return false;
    }
    final target = current.targetMillis;
    final accurate = current.isAccurate(elapsedMillis);
    _results.add(TimeSenseResult(
      targetMillis: target,
      elapsedMillis: elapsedMillis,
      accurate: accurate,
    ));
    round++;
    return true;
  }
}
