import 'dart:math';

enum MagnitudeSubmitResult { invalid, accurate, inaccurate, complete }

class MagnitudeRound {
  const MagnitudeRound({
    required this.minimum,
    required this.maximum,
    required this.target,
    required this.toleranceFraction,
  })  : assert(maximum > minimum),
        assert(target > minimum && target < maximum),
        assert(toleranceFraction > 0);

  final int minimum;
  final int maximum;
  final int target;
  final double toleranceFraction;

  double get targetPosition => (target - minimum) / (maximum - minimum);
  double get tolerance => (maximum - minimum) * toleranceFraction;

  bool isAccurate(double position) {
    if (!position.isFinite || position < 0 || position > 1) return false;
    final estimate = minimum + position * (maximum - minimum);
    return (estimate - target).abs() <= tolerance;
  }
}

/// Estimate where a written number belongs on a number line.
class MagnitudeMapperSession {
  MagnitudeMapperSession({required this.seed, int level = 1}) {
    final random = Random(seed);
    final maxLevel = level.clamp(1, 20).toInt();
    final toleranceFraction =
        (.12 - (maxLevel - 1) * .003).clamp(.06, .12).toDouble();
    final ranges = _rangesFor(maxLevel);
    rounds = List<MagnitudeRound>.unmodifiable([
      for (final maximum in ranges)
        MagnitudeRound(
          minimum: 0,
          maximum: maximum,
          target: 1 + random.nextInt(maximum - 1),
          toleranceFraction: toleranceFraction,
        ),
    ]);
  }

  static const int roundCount = 6;
  static const int passScore = 4;

  final int seed;
  late final List<MagnitudeRound> rounds;
  final List<bool> _results = [];
  int roundIndex = 0;
  double guessPosition = .5;

  bool get finished => roundIndex >= roundCount;
  bool get passed => finished && accurateCount >= passScore;
  int get accurateCount => _results.where((result) => result).length;
  int get mistakes => _results.where((result) => !result).length;
  double get progress => roundIndex / roundCount;
  MagnitudeRound get current =>
      rounds[roundIndex.clamp(0, roundCount - 1).toInt()];
  List<bool> get results => List<bool>.unmodifiable(_results);

  bool setGuess(double position) {
    if (finished || !position.isFinite || position < 0 || position > 1) {
      return false;
    }
    guessPosition = position;
    return true;
  }

  MagnitudeSubmitResult submit() {
    if (finished) return MagnitudeSubmitResult.invalid;

    final accurate = current.isAccurate(guessPosition);
    _results.add(accurate);
    roundIndex++;
    guessPosition = .5;

    if (finished) return MagnitudeSubmitResult.complete;
    return accurate
        ? MagnitudeSubmitResult.accurate
        : MagnitudeSubmitResult.inaccurate;
  }

  static List<int> _rangesFor(int level) {
    if (level <= 3) return const [100, 100, 100, 100, 100, 100];
    if (level <= 6) return const [100, 100, 500, 500, 500, 500];
    if (level <= 9) return const [100, 500, 500, 1000, 1000, 1000];
    return const [500, 1000, 1000, 2000, 5000, 5000];
  }
}
