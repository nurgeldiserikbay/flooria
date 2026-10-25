import 'dart:math';

enum LoopSymbol { circle, square, triangle, diamond, star }

enum LoopResponseResult { invalid, correct, incorrect, complete }

/// Continuous n-back recognition. The player compares each symbol with the
/// one shown [backSteps] trials earlier and answers before the next appears.
class MindLoopSession {
  MindLoopSession({required this.seed, int level = 1})
      : backSteps = level >= 6 ? 3 : 2 {
    final random = Random(seed);
    const matchesPerSession = 4;
    final matchPositions = List<int>.generate(
      roundCount - backSteps,
      (index) => index + backSteps,
    )..shuffle(random);
    final matches = matchPositions.take(matchesPerSession).toSet();
    final sequence = <LoopSymbol>[];

    for (var index = 0; index < roundCount; index++) {
      if (index < backSteps) {
        sequence.add(LoopSymbol.values[random.nextInt(LoopSymbol.values.length)]);
      } else if (matches.contains(index)) {
        sequence.add(sequence[index - backSteps]);
      } else {
        final options = LoopSymbol.values
            .where((symbol) => symbol != sequence[index - backSteps])
            .toList();
        sequence.add(options[random.nextInt(options.length)]);
      }
    }
    symbols = List<LoopSymbol>.unmodifiable(sequence);
  }

  static const int roundCount = 12;
  static const int passScore = 9;

  final int seed;
  final int backSteps;
  late final List<LoopSymbol> symbols;

  int trialIndex = 0;
  int correctAnswers = 0;
  int mistakes = 0;

  bool get finished => trialIndex >= roundCount;
  bool get passed => finished && correctAnswers >= passScore;
  double get progress => trialIndex / roundCount;
  LoopSymbol get currentSymbol =>
      symbols[trialIndex.clamp(0, roundCount - 1).toInt()];
  bool get currentIsMatch => isMatchAt(trialIndex);

  bool isMatchAt(int index) {
    if (index < 0 || index >= roundCount) {
      throw RangeError.index(index, symbols, 'index');
    }
    return index >= backSteps && symbols[index] == symbols[index - backSteps];
  }

  /// Accepts one answer and advances exactly one trial. Invalid calls after
  /// completion do not change counters.
  LoopResponseResult respond(bool saysMatch) {
    if (finished) return LoopResponseResult.invalid;

    final correct = saysMatch == currentIsMatch;
    if (correct) {
      correctAnswers++;
    } else {
      mistakes++;
    }
    trialIndex++;

    if (finished) return LoopResponseResult.complete;
    return correct
        ? LoopResponseResult.correct
        : LoopResponseResult.incorrect;
  }
}
