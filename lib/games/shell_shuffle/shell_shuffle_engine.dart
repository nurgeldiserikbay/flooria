import 'dart:math';

enum ShellPickResult { invalid, incorrect, correct, complete }

class ShellSwap {
  const ShellSwap(this.firstSlot, this.secondSlot)
      : assert(firstSlot != secondSlot);

  final int firstSlot;
  final int secondSlot;
}

class ShellRound {
  ShellRound({
    required this.cupCount,
    required this.starCup,
    required Iterable<ShellSwap> swaps,
  }) : swaps = List<ShellSwap>.unmodifiable(swaps);

  final int cupCount;
  final int starCup;
  final List<ShellSwap> swaps;

  int get answerSlot {
    var slot = starCup;
    for (final swap in swaps) {
      if (slot == swap.firstSlot) {
        slot = swap.secondSlot;
      } else if (slot == swap.secondSlot) {
        slot = swap.firstSlot;
      }
    }
    return slot;
  }
}

/// A seeded visual-tracking session. Every shuffle is a reversible swap list.
class ShellShuffleSession {
  ShellShuffleSession({required this.seed}) {
    final random = Random(seed);
    rounds = List<ShellRound>.unmodifiable(List.generate(
      roundCount,
      (round) {
        final cupCount = min(3 + round ~/ 2, 5);
        final swaps = <ShellSwap>[];
        for (var index = 0; index < 3 + round; index++) {
          final first = random.nextInt(cupCount);
          var second = random.nextInt(cupCount - 1);
          if (second >= first) second++;
          swaps.add(ShellSwap(first, second));
        }
        return ShellRound(
          cupCount: cupCount,
          starCup: random.nextInt(cupCount),
          swaps: swaps,
        );
      },
    ));
  }

  static const int roundCount = 5;
  final int seed;
  late final List<ShellRound> rounds;
  int roundIndex = 0;
  int mistakes = 0;
  int correctAnswers = 0;

  bool get finished => roundIndex >= roundCount;
  double get progress => roundIndex / roundCount;
  ShellRound get current =>
      rounds[roundIndex.clamp(0, roundCount - 1).toInt()];

  ShellPickResult choose(int slot) {
    if (finished || slot < 0 || slot >= current.cupCount) {
      return ShellPickResult.invalid;
    }
    if (slot != current.answerSlot) {
      mistakes++;
      return ShellPickResult.incorrect;
    }
    correctAnswers++;
    roundIndex++;
    return finished ? ShellPickResult.complete : ShellPickResult.correct;
  }
}
