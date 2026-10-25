import 'dart:math';

/// Weight-selection puzzle. The left pan has a fixed target weight; the
/// player fills the right pan from five distinct weights. Every round has
/// at least one solution using 2-3 available weights.
class BalanceScaleSession {
  BalanceScaleSession({required this.seed, this.roundCount = 3})
      : assert(roundCount > 0);

  final int seed;
  final int roundCount;
  int round = 0;
  int attempts = 0;
  final Set<int> selected = {};

  bool get complete => round == roundCount;

  List<int> get weights {
    if (complete) return const [];
    final random = Random((seed * 131071 + round * 8191) & 0x7fffffff);
    final pool = List<int>.generate(10, (i) => i + 1)..shuffle(random);
    return pool.take(5).toList();
  }

  List<int> get solutionIndices {
    if (complete) return const [];
    final random = Random((seed * 8191 + round * 65537) & 0x7fffffff);
    final indices = [0, 1, 2, 3, 4]..shuffle(random);
    return indices.take(round == 0 ? 2 : 3).toList();
  }

  int get target {
    final items = weights;
    return solutionIndices.fold<int>(0, (sum, index) => sum + items[index]);
  }

  int get placedWeight {
    final items = weights;
    return selected.fold<int>(0, (sum, index) => sum + items[index]);
  }

  bool get balanced => !complete && placedWeight == target;

  /// Returns false for invalid taps or a completed session.
  bool toggle(int index) {
    if (complete || index < 0 || index >= weights.length) return false;
    if (!selected.add(index)) selected.remove(index);
    return true;
  }

  /// A valid attempt with the correct total advances the round.
  /// Incorrect submissions retain selected weights so the player can adjust.
  bool submit() {
    if (complete || selected.isEmpty) return false;
    attempts++;
    if (!balanced) return false;
    round++;
    selected.clear();
    return true;
  }
}
