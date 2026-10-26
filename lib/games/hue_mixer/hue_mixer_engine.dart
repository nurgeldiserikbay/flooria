import 'dart:math';

enum HueAnswerResult { invalid, correct, incorrect }

class HueColor {
  const HueColor({
    required this.name,
    required this.red,
    required this.green,
    required this.blue,
  });

  final String name;
  final int red;
  final int green;
  final int blue;

  static HueColor blend(HueColor first, HueColor second, int firstPercent) {
    final secondPercent = 100 - firstPercent;
    return HueColor(
      name: 'Blend',
      red: (first.red * firstPercent + second.red * secondPercent + 50) ~/ 100,
      green:
          (first.green * firstPercent + second.green * secondPercent + 50) ~/
              100,
      blue: (first.blue * firstPercent + second.blue * secondPercent + 50) ~/
          100,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HueColor &&
      other.red == red &&
      other.green == green &&
      other.blue == blue;

  @override
  int get hashCode => Object.hash(red, green, blue);
}

class HueBlendRound {
  const HueBlendRound({
    required this.firstColor,
    required this.secondColor,
    required this.targetColor,
    required this.targetFirstPercent,
    required this.ratioChoices,
  });

  final HueColor firstColor;
  final HueColor secondColor;
  final HueColor targetColor;
  final int targetFirstPercent;
  final List<int> ratioChoices;
}

/// A seeded visual color-composition challenge.
class HueMixerSession {
  HueMixerSession({required this.seed, int level = 1}) {
    final random = Random(seed);
    final clampedLevel = level.clamp(1, 20).toInt();
    final pairCount = clampedLevel < 4 ? 3 : (clampedLevel < 10 ? 5 : 7);
    final offsets = clampedLevel < 4
        ? const [-20, 0, 20]
        : (clampedLevel < 10
            ? const [-20, -10, 0, 10, 20]
            : const [-15, -10, -5, 0, 5, 10, 15]);
    final pairs = List<_HuePair>.of(_pairs)..shuffle(random);

    rounds = List<HueBlendRound>.unmodifiable(
      List.generate(roundCount, (index) {
        final pair = pairs[index % pairs.length];
        final target = clampedLevel < 4
            ? const [30, 50, 70][random.nextInt(3)]
            : 25 + random.nextInt(11) * 5;
        final choices = offsets.map((offset) => target + offset).toList()
          ..shuffle(random);
        return HueBlendRound(
          firstColor: pair.first,
          secondColor: pair.second,
          targetColor: HueColor.blend(pair.first, pair.second, target),
          targetFirstPercent: target,
          ratioChoices: List<int>.unmodifiable(choices),
        );
      }),
    );
    ratioChoiceCount = pairCount;
  }

  static const int roundCount = 5;
  static const int passScore = 4;

  static const _pairs = <_HuePair>[
    _HuePair(_red, _blue),
    _HuePair(_yellow, _blue),
    _HuePair(_red, _green),
    _HuePair(_cyan, _magenta),
    _HuePair(_yellow, _violet),
    _HuePair(_cyan, _red),
    _HuePair(_green, _violet),
  ];

  static const _red = HueColor(
    name: 'Coral red',
    red: 245,
    green: 72,
    blue: 78,
  );
  static const _yellow = HueColor(
    name: 'Sun yellow',
    red: 250,
    green: 205,
    blue: 58,
  );
  static const _green = HueColor(
    name: 'Leaf green',
    red: 70,
    green: 180,
    blue: 105,
  );
  static const _blue = HueColor(
    name: 'Ocean blue',
    red: 60,
    green: 115,
    blue: 220,
  );
  static const _cyan = HueColor(
    name: 'Aqua',
    red: 35,
    green: 190,
    blue: 190,
  );
  static const _magenta = HueColor(
    name: 'Berry pink',
    red: 215,
    green: 65,
    blue: 165,
  );
  static const _violet = HueColor(
    name: 'Soft violet',
    red: 145,
    green: 95,
    blue: 205,
  );

  final int seed;
  late final List<HueBlendRound> rounds;
  late final int ratioChoiceCount;
  int roundIndex = 0;
  int correctAnswers = 0;
  int mistakes = 0;
  bool _answered = false;

  bool get finished => roundIndex >= roundCount;
  bool get answered => _answered;
  bool get passed => finished && correctAnswers >= passScore;
  double get progress => finished ? 1 : roundIndex / roundCount;
  HueBlendRound get current =>
      rounds[roundIndex.clamp(0, roundCount - 1).toInt()];

  HueAnswerResult submit(int firstPercent) {
    if (finished || _answered || !current.ratioChoices.contains(firstPercent)) {
      return HueAnswerResult.invalid;
    }
    _answered = true;
    if (firstPercent == current.targetFirstPercent) {
      correctAnswers++;
      return HueAnswerResult.correct;
    }
    mistakes++;
    return HueAnswerResult.incorrect;
  }

  bool advance() {
    if (finished || !_answered) return false;
    _answered = false;
    roundIndex++;
    return true;
  }
}

class _HuePair {
  const _HuePair(this.first, this.second);
  final HueColor first;
  final HueColor second;
}
