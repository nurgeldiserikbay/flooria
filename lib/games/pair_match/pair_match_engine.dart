import 'dart:math';

enum PairTap { flipped, mismatch, matched, completed, ignored }

/// Memory matching rules. Symbols are stable integer IDs, independent of UI.
class PairMatchEngine {
  PairMatchEngine._({required this.level, required this.pairCount,
    required List<int> symbols}) : symbols = List.unmodifiable(symbols);

  final int level;
  final int pairCount;
  final List<int> symbols;
  final Set<int> matched = {};
  final Set<int> revealed = {};
  int? _first;
  int attempts = 0;
  bool isCompleted = false;

  int get pairsFound => matched.length ~/ 2;
  int get score => max(100, pairCount * 120 - max(0, attempts - pairCount) * 18).toInt();

  factory PairMatchEngine.forLevel(int level, {int? seed}) {
    final safe = max(1, level).toInt();
    final pairs = safe < 5 ? 6 : 8;
    final values = [for (var i = 0; i < pairs; i++) ...[i, i]];
    values.shuffle(Random(seed ?? safe * 104729 + 5));
    return PairMatchEngine._(level: safe, pairCount: pairs, symbols: values);
  }

  PairTap tap(int index) {
    if (isCompleted || index < 0 || index >= symbols.length ||
        matched.contains(index) || revealed.contains(index)) {
      return PairTap.ignored;
    }
    revealed.add(index);
    final first = _first;
    if (first == null) {
      _first = index;
      return PairTap.flipped;
    }
    attempts++;
    _first = null;
    if (symbols[first] == symbols[index]) {
      matched.addAll([first, index]);
      revealed.clear();
      if (matched.length == symbols.length) {
        isCompleted = true;
        return PairTap.completed;
      }
      return PairTap.matched;
    }
    return PairTap.mismatch;
  }

  void hideMismatch() {
    if (revealed.length == 2 && _first == null) revealed.clear();
  }
}
