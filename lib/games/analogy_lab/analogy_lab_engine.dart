import 'dart:math';

enum AnalogyShape { circle, square, triangle, diamond }

enum AnalogyColor { coral, blue, amber, mint }

enum AnalogyFeature { shape, color, count }

enum AnalogySubmitResult { invalid, incorrect, correct, complete }

/// A simple symbol described by shape, color, and quantity.
class AnalogyToken {
  const AnalogyToken({
    required this.shape,
    required this.color,
    required this.count,
  }) : assert(count >= 1 && count <= 3);

  final AnalogyShape shape;
  final AnalogyColor color;
  final int count;

  int get fingerprint =>
      shape.index * 12 + color.index * 3 + (count - 1);

  @override
  bool operator ==(Object other) =>
      other is AnalogyToken &&
      shape == other.shape &&
      color == other.color &&
      count == other.count;

  @override
  int get hashCode => Object.hash(shape, color, count);
}

/// One analogy: first pair reveals a transformation applied to the prompt.
class AnalogyRound {
  const AnalogyRound({
    required this.exampleFrom,
    required this.exampleTo,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.changedFeatures,
  });

  final AnalogyToken exampleFrom;
  final AnalogyToken exampleTo;
  final AnalogyToken prompt;
  final List<AnalogyToken> options;
  final int correctIndex;
  final int changedFeatures;

  AnalogyToken get answer => options[correctIndex];
}

/// Seeded visual reasoning session. Every round is built from a known rule,
/// and the four answer choices are unique.
class AnalogyLabSession {
  AnalogyLabSession({required this.seed, int level = 1}) {
    final random = Random(seed);
    final featuresPerRule = level < 4 ? 1 : (level < 9 ? 2 : 3);
    rounds = List<AnalogyRound>.unmodifiable(
      List.generate(
        roundCount,
        (_) => _makeRound(random, featuresPerRule),
      ),
    );
  }

  static const int roundCount = 8;
  static const int passScore = 6;

  final int seed;
  late final List<AnalogyRound> rounds;
  int roundIndex = 0;
  int correctCount = 0;
  int mistakes = 0;

  bool get finished => roundIndex >= roundCount;
  bool get passed => finished && correctCount >= passScore;
  double get progress => roundIndex / roundCount;
  AnalogyRound get current =>
      rounds[roundIndex.clamp(0, roundCount - 1).toInt()];

  AnalogySubmitResult submit(int optionIndex) {
    if (finished || optionIndex < 0 || optionIndex >= current.options.length) {
      return AnalogySubmitResult.invalid;
    }

    final correct = optionIndex == current.correctIndex;
    roundIndex++;
    if (correct) {
      correctCount++;
    } else {
      mistakes++;
    }

    if (finished) return AnalogySubmitResult.complete;
    return correct
        ? AnalogySubmitResult.correct
        : AnalogySubmitResult.incorrect;
  }

  static AnalogyRound _makeRound(Random random, int featureCount) {
    final chosen = AnalogyFeature.values.toList()..shuffle(random);
    final features = chosen.take(featureCount).toSet();
    final exampleFrom = _randomToken(random);
    final prompt = _randomToken(random);
    final deltas = <AnalogyFeature, int>{};

    for (final feature in features) {
      final modulus = _modulus(feature);
      deltas[feature] = 1 + random.nextInt(modulus - 1);
    }

    final exampleTo = _apply(exampleFrom, deltas);
    final answer = _apply(prompt, deltas);
    final distractors = <AnalogyToken>[];
    for (final shape in AnalogyShape.values) {
      for (final color in AnalogyColor.values) {
        for (var count = 1; count <= 3; count++) {
          final token = AnalogyToken(shape: shape, color: color, count: count);
          if (token != answer) distractors.add(token);
        }
      }
    }
    distractors.shuffle(random);
    final options = <AnalogyToken>[
      answer,
      ...distractors.take(3),
    ]..shuffle(random);

    return AnalogyRound(
      exampleFrom: exampleFrom,
      exampleTo: exampleTo,
      prompt: prompt,
      options: List<AnalogyToken>.unmodifiable(options),
      correctIndex: options.indexOf(answer),
      changedFeatures: featureCount,
    );
  }

  static AnalogyToken _randomToken(Random random) => AnalogyToken(
        shape: AnalogyShape.values[random.nextInt(AnalogyShape.values.length)],
        color: AnalogyColor.values[random.nextInt(AnalogyColor.values.length)],
        count: 1 + random.nextInt(3),
      );

  static AnalogyToken _apply(
    AnalogyToken token,
    Map<AnalogyFeature, int> deltas,
  ) {
    final shape = (token.shape.index +
            (deltas[AnalogyFeature.shape] ?? 0)) %
        AnalogyShape.values.length;
    final color =
        (token.color.index + (deltas[AnalogyFeature.color] ?? 0)) %
            AnalogyColor.values.length;
    final countIndex =
        (token.count - 1 + (deltas[AnalogyFeature.count] ?? 0)) % 3;
    return AnalogyToken(
      shape: AnalogyShape.values[shape],
      color: AnalogyColor.values[color],
      count: countIndex + 1,
    );
  }

  static int _modulus(AnalogyFeature feature) => switch (feature) {
        AnalogyFeature.shape => AnalogyShape.values.length,
        AnalogyFeature.color => AnalogyColor.values.length,
        AnalogyFeature.count => 3,
      };
}
