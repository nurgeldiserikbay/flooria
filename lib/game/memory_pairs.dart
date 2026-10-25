import 'dart:math';

/// Pure Dart memory-pair session. No Flutter or navigation dependencies.
class MemoryPairs {
  MemoryPairs({required int seed, int pairCount = 6})
      : assert(pairCount >= 2 && pairCount <= 8),
        _pairCount = pairCount {
    final rng = Random(seed);
    final symbols = List<int>.generate(pairCount, (index) => index);
    values = [...symbols, ...symbols]..shuffle(rng);
  }

  final int _pairCount;
  late final List<int> values;
  final Set<int> matched = {};
  int moves = 0;
  int? firstIndex;
  int? secondIndex;

  int get pairCount => _pairCount;
  int get pairsFound => matched.length ~/ 2;
  bool get isComplete => matched.length == values.length;
  bool get isResolving => secondIndex != null;

  bool isFaceUp(int index) =>
      matched.contains(index) || firstIndex == index || secondIndex == index;

  /// True if the card was accepted. A two-card miss remains visible until hideMismatch.
  bool reveal(int index) {
    if (index < 0 || index >= values.length ||
        matched.contains(index) || isFaceUp(index) || isResolving) {
      return false;
    }
    if (firstIndex == null) {
      firstIndex = index;
      return true;
    }
    secondIndex = index;
    moves++;
    if (values[firstIndex!] == values[index]) {
      matched.add(firstIndex!);
      matched.add(index);
      firstIndex = null;
      secondIndex = null;
    }
    return true;
  }

  void hideMismatch() {
    if (secondIndex == null) return;
    firstIndex = null;
    secondIndex = null;
  }
}
