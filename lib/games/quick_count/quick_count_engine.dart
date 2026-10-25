import 'dart:math';

/// A normalized dot location inside the flash card.
class DotPoint {
  const DotPoint(this.x, this.y);

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is DotPoint && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

class QuickCountRound {
  const QuickCountRound({
    required this.target,
    required this.choices,
    required this.dots,
  });

  final int target;
  final List<int> choices;
  final List<DotPoint> dots;

  @override
  bool operator ==(Object other) => other is QuickCountRound &&
      target == other.target && _same(choices, other.choices) && _same(dots, other.dots);

  @override
  int get hashCode => Object.hash(target, Object.hashAll(choices), Object.hashAll(dots));

  static bool _same<T>(List<T> first, List<T> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }
}

/// Estimate the quantity in a brief flash of scattered dots.
class QuickCountSession {
  QuickCountSession({required this.seed, int level = 1}) {
    final random = Random(seed);
    final levelSteps = max(0, level - 1).toInt() ~/ 3;
    final maximum = (11 + levelSteps).clamp(11, 17).toInt();
    rounds = List<QuickCountRound>.unmodifiable(List.generate(
      roundCount,
      (_) => _makeRound(random, maximum),
    ));
  }

  static const int roundCount = 8;
  static const int passScore = 6;

  final int seed;
  late final List<QuickCountRound> rounds;
  int round = 0;
  int correct = 0;

  bool get finished => round >= roundCount;
  bool get passed => finished && correct >= passScore;
  double get progress => round / roundCount;
  QuickCountRound get current => rounds[round.clamp(0, roundCount - 1).toInt()];

  /// Accepts only a choice shown for this round. Invalid or duplicate answers
  /// leave the session unchanged.
  bool answer(int count) {
    if (finished || !current.choices.contains(count)) return false;
    if (count == current.target) correct++;
    round++;
    return true;
  }

  static QuickCountRound _makeRound(Random random, int maximum) {
    final target = 6 + random.nextInt(maximum - 5);
    final candidates = <int>{target};
    while (candidates.length < 3) {
      final offset = random.nextInt(7) - 3;
      if (offset == 0) continue;
      final choice = target + offset;
      if (choice >= 3 && choice <= 20) candidates.add(choice);
    }
    final choices = candidates.toList()..sort();

    // Select cells from an even grid before adding a little jitter. This keeps
    // marks visually distinct on narrow screens while retaining a random feel.
    final cells = List<int>.generate(25, (index) => index)
      ..shuffle(random);
    final dots = List<DotPoint>.generate(target, (index) {
      final cell = cells[index];
      final column = cell % 5;
      final row = cell ~/ 5;
      final jitterX = (random.nextDouble() - .5) * .18;
      final jitterY = (random.nextDouble() - .5) * .18;
      return DotPoint(
        ((column + .5) / 5 + jitterX).clamp(.04, .96).toDouble(),
        ((row + .5) / 5 + jitterY).clamp(.05, .95).toDouble(),
      );
    });
    return QuickCountRound(
      target: target,
      choices: List<int>.unmodifiable(choices),
      dots: List<DotPoint>.unmodifiable(dots),
    );
  }
}
