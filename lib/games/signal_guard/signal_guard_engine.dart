import 'dart:math';

enum SignalShape { circle, square }

enum SignalTint { mint, coral }

/// Which feature decides whether a signal is a "go".
enum SignalRule { color, shape }

enum TrialOutcome { hit, miss, falseAlarm, correctRejection }

class SignalTrial {
  const SignalTrial({required this.shape, required this.tint,
    required this.isGo, required this.delayMs});

  final SignalShape shape;
  final SignalTint tint;
  final bool isGo;

  /// Blank pause before this signal appears.
  final int delayMs;
}

/// Go/no-go: respond to go signals inside the window and hold back on the
/// rest. A response or a timeout resolves each trial exactly once.
class SignalGuardEngine {
  SignalGuardEngine._({required this.level, required this.rule,
    required List<SignalTrial> trials, required this.windowMs,
    required this.passRatio})
      : trials = List<SignalTrial>.unmodifiable(trials),
        outcomes = List<TrialOutcome?>.filled(trials.length, null),
        reactionMs = List<int?>.filled(trials.length, null);

  final int level;
  final SignalRule rule;
  final List<SignalTrial> trials;
  final int windowMs;
  final double passRatio;
  final List<TrialOutcome?> outcomes;
  final List<int?> reactionMs;
  int _index = 0;

  int get index => _index;
  bool get isFinished => _index >= trials.length;
  SignalTrial get current => trials[min(_index, trials.length - 1)];

  int get correctCount => outcomes.where((o) =>
      o == TrialOutcome.hit || o == TrialOutcome.correctRejection).length;
  double get accuracy => trials.isEmpty ? 0 : correctCount / trials.length;
  bool get passed => isFinished && accuracy >= passRatio;
  int get falseAlarms =>
      outcomes.where((o) => o == TrialOutcome.falseAlarm).length;
  int get misses => outcomes.where((o) => o == TrialOutcome.miss).length;

  /// Mean reaction time of correct responses, or null before any hit.
  int? get meanReactionMs {
    final hits = [
      for (var i = 0; i < trials.length; i++)
        if (outcomes[i] == TrialOutcome.hit && reactionMs[i] != null)
          reactionMs[i]!,
    ];
    if (hits.isEmpty) return null;
    return (hits.reduce((a, b) => a + b) / hits.length).round();
  }

  int get stars => accuracy >= .99 ? 3 : accuracy >= .9 ? 2 : 1;
  int get score {
    var speed = 0;
    for (var i = 0; i < trials.length; i++) {
      if (outcomes[i] == TrialOutcome.hit) {
        speed += max(0, windowMs - (reactionMs[i] ?? windowMs)) ~/ 10;
      }
    }
    return correctCount * 60 + speed;
  }

  int get controlMetric => (accuracy * 100).round();

  static SignalRule ruleForLevel(int level) {
    if (level < 10) return SignalRule.color;
    if (level < 25) return SignalRule.shape;
    return level.isOdd ? SignalRule.color : SignalRule.shape;
  }

  static int windowForLevel(int level) => max(480, 1112 - level * 12);

  factory SignalGuardEngine.forLevel(int level, {int? seed}) {
    final safeLevel = max(1, level).toInt();
    final random = Random(seed ?? safeLevel * 2749 + 5);
    final rule = ruleForLevel(safeLevel);
    final count = safeLevel < 10 ? 14 : safeLevel < 30 ? 16 : 20;
    final goCount = (count * .65).round();

    var pattern = <bool>[];
    for (var attempt = 0; attempt < 200; attempt++) {
      pattern = [
        for (var i = 0; i < count; i++) i < goCount,
      ]..shuffle(random);
      if (pattern.first && _longestRun(pattern, false) <= 2 &&
          _longestRun(pattern, true) <= 5) {
        break;
      }
    }

    final trials = <SignalTrial>[];
    for (final go in pattern) {
      // The rule feature decides; the other feature is random noise.
      final noiseShape = random.nextBool() ? SignalShape.circle : SignalShape.square;
      final noiseTint = random.nextBool() ? SignalTint.mint : SignalTint.coral;
      trials.add(SignalTrial(
        shape: rule == SignalRule.shape
            ? (go ? SignalShape.circle : SignalShape.square)
            : safeLevel < 10 ? SignalShape.circle : noiseShape,
        tint: rule == SignalRule.color
            ? (go ? SignalTint.mint : SignalTint.coral)
            : noiseTint,
        isGo: go,
        delayMs: 420 + random.nextInt(320),
      ));
    }
    return SignalGuardEngine._(level: safeLevel, rule: rule, trials: trials,
      windowMs: windowForLevel(safeLevel),
      passRatio: safeLevel < 10 ? .7 : .8);
  }

  static int _longestRun(List<bool> pattern, bool value) {
    var best = 0;
    var run = 0;
    for (final item in pattern) {
      run = item == value ? run + 1 : 0;
      best = max(best, run);
    }
    return best;
  }

  /// The player tapped during the current signal.
  TrialOutcome? respond(int elapsedMs) {
    if (isFinished) return null;
    final outcome = current.isGo ? TrialOutcome.hit : TrialOutcome.falseAlarm;
    outcomes[_index] = outcome;
    reactionMs[_index] = elapsedMs.clamp(0, windowMs);
    _index++;
    return outcome;
  }

  /// The signal window closed without a tap.
  TrialOutcome? timeout() {
    if (isFinished) return null;
    final outcome =
        current.isGo ? TrialOutcome.miss : TrialOutcome.correctRejection;
    outcomes[_index] = outcome;
    _index++;
    return outcome;
  }
}
