import 'dart:math';

/// The six hues used by the word and by its ink.
enum InkHue { coral, blue, violet, mint, amber, teal }

class InkSwitchRound {
  const InkSwitchRound({
    required this.wordHue,
    required this.inkHue,
    required this.options,
  });

  /// The color named by the displayed word.
  final InkHue wordHue;

  /// The actual color used to draw that word.
  final InkHue inkHue;

  /// Four color names, shuffled for the answer buttons.
  final List<InkHue> options;

  int get correctIndex => options.indexOf(inkHue);
}

/// Stroop-style word/color conflict rounds with deterministic generation.
class InkSwitchSession {
  InkSwitchSession({required int seed}) : rounds = _makeRounds(seed);

  static const int roundCount = 10;
  static const int passScore = 7;

  final List<InkSwitchRound> rounds;
  int round = 0;
  int correct = 0;
  int mistakes = 0;

  bool get finished => round >= roundCount;
  bool get passed => finished && correct >= passScore;
  InkSwitchRound get current => rounds[round.clamp(0, roundCount - 1).toInt()];

  /// Records one of the shown answers. Invalid indices leave state unchanged.
  bool answer(int optionIndex) {
    if (finished || optionIndex < 0 || optionIndex >= current.options.length) {
      return false;
    }
    if (current.options[optionIndex] == current.inkHue) {
      correct++;
    } else {
      mistakes++;
    }
    round++;
    return true;
  }

  static List<InkSwitchRound> _makeRounds(int seed) {
    final random = Random((seed * 65537 + 86028121) & 0x7fffffff);
    return List<InkSwitchRound>.unmodifiable(List.generate(roundCount, (_) {
      final wordHue = InkHue.values[random.nextInt(InkHue.values.length)];
      final possibleInks = InkHue.values.where((hue) => hue != wordHue).toList();
      final inkHue = possibleInks[random.nextInt(possibleInks.length)];
      final options = <InkHue>{inkHue, wordHue};
      while (options.length < 4) {
        options.add(InkHue.values[random.nextInt(InkHue.values.length)]);
      }
      final shuffled = options.toList()..shuffle(random);
      return InkSwitchRound(
        wordHue: wordHue,
        inkHue: inkHue,
        options: List<InkHue>.unmodifiable(shuffled),
      );
    }));
  }
}
