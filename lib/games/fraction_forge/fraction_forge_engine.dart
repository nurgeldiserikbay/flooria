import 'dart:math';

enum FractionPickResult { invalid, incorrect, correct, complete }

class FractionValue implements Comparable<FractionValue> {
  const FractionValue._(this.numerator, this.denominator);

  factory FractionValue.of(int numerator, int denominator) {
    if (denominator <= 0 || numerator < 0) {
      throw ArgumentError('Fractions must be non-negative with a positive denominator.');
    }
    final divisor = _gcd(numerator, denominator);
    return FractionValue._(numerator ~/ divisor, denominator ~/ divisor);
  }

  final int numerator;
  final int denominator;

  double get value => numerator / denominator;
  String get label => '$numerator/$denominator';

  FractionValue distanceFrom(FractionValue other) => FractionValue.of(
        (numerator * other.denominator - other.numerator * denominator).abs(),
        denominator * other.denominator,
      );

  @override
  int compareTo(FractionValue other) =>
      (numerator * other.denominator)
          .compareTo(other.numerator * denominator);

  @override
  bool operator ==(Object other) =>
      other is FractionValue &&
      numerator == other.numerator &&
      denominator == other.denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  static int _gcd(int a, int b) {
    while (b != 0) {
      final remainder = a % b;
      a = b;
      b = remainder;
    }
    return a == 0 ? 1 : a;
  }
}

class FractionChallenge {
  FractionChallenge({
    required this.target,
    required Iterable<FractionValue> options,
    required this.answerIndex,
  }) : options = List<FractionValue>.unmodifiable(options);

  final FractionValue target;
  final List<FractionValue> options;
  final int answerIndex;

  FractionValue get answer => options[answerIndex];
}

/// Each generated question has one fraction uniquely closest to its target.
class FractionForgeSession {
  FractionForgeSession({required this.seed}) {
    final random = Random(seed);
    challenges = List<FractionChallenge>.unmodifiable(List.generate(
      roundCount,
      (round) => _makeChallenge(random, round),
    ));
  }

  static const int roundCount = 8;
  final int seed;
  late final List<FractionChallenge> challenges;
  int roundIndex = 0;
  int correctAnswers = 0;
  int mistakes = 0;

  bool get finished => roundIndex >= roundCount;
  double get progress => roundIndex / roundCount;
  FractionChallenge get current =>
      challenges[roundIndex.clamp(0, roundCount - 1).toInt()];

  FractionPickResult choose(int optionIndex) {
    if (finished || optionIndex < 0 || optionIndex >= current.options.length) {
      return FractionPickResult.invalid;
    }
    if (optionIndex != current.answerIndex) {
      mistakes++;
      return FractionPickResult.incorrect;
    }
    correctAnswers++;
    roundIndex++;
    return finished ? FractionPickResult.complete : FractionPickResult.correct;
  }

  FractionChallenge _makeChallenge(Random random, int round) {
    final targets = <FractionValue>[
      FractionValue.of(1, 2),
      FractionValue.of(1, 3),
      FractionValue.of(2, 3),
      FractionValue.of(1, 4),
      FractionValue.of(3, 4),
      FractionValue.of(2, 5),
      FractionValue.of(3, 5),
    ];
    final target = targets[random.nextInt(targets.length)];
    final optionCount = round < 4 ? 3 : 4;
    final maxDenominator = 6 + round;
    final unique = <String, FractionValue>{};
    for (var denominator = 2; denominator <= maxDenominator; denominator++) {
      for (var numerator = 1; numerator < denominator; numerator++) {
        final fraction = FractionValue.of(numerator, denominator);
        unique[fraction.label] = fraction;
      }
    }
    final candidates =
        unique.values.where((fraction) => fraction != target).toList();

    final eligibleAnswers = candidates.where((candidate) {
      return candidates.where((other) =>
          other != candidate &&
          _compareDistance(other, candidate, target) > 0).length >=
          optionCount - 1;
    }).toList()
      ..shuffle(random);

    if (eligibleAnswers.isEmpty) {
      throw StateError('No unique closest fraction could be generated.');
    }
    final answer = eligibleAnswers.first;
    final distractors = candidates.where((other) =>
        other != answer && _compareDistance(other, answer, target) > 0).toList()
      ..shuffle(random);
    final options = <FractionValue>[
      answer,
      ...distractors.take(optionCount - 1),
    ]..shuffle(random);

    return FractionChallenge(
      target: target,
      options: options,
      answerIndex: options.indexOf(answer),
    );
  }

  /// Positive means [first] is farther from [target] than [second].
  int _compareDistance(
    FractionValue first,
    FractionValue second,
    FractionValue target,
  ) {
    final a = first.distanceFrom(target);
    final b = second.distanceFrom(target);
    return (a.numerator * b.denominator)
        .compareTo(b.numerator * a.denominator);
  }
}
