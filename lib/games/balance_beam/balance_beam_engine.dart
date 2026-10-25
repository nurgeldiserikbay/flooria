import 'dart:math';

class BalancePuzzle {
  const BalancePuzzle({
    required this.targetWeight,
    required this.weights,
    required this.solutionIndices,
  });

  final int targetWeight;
  final List<int> weights;
  final Set<int> solutionIndices;

  bool get hasSolution => solutionIndices.fold<int>(
        0,
        (sum, index) => sum + weights[index],
      ) == targetWeight;
}

/// Three short, seeded balance puzzles. The player places weights on the
/// empty pan; invalid placements leave the puzzle unchanged.
class BalanceBeamSession {
  BalanceBeamSession({required this.seed, this.roundCount = 3})
      : assert(roundCount > 0) {
    _loadRound();
  }

  final int seed;
  final int roundCount;
  int round = 0;
  int moves = 0;
  int mistakes = 0;
  int _revision = 0;
  late BalancePuzzle puzzle;
  final Set<int> placedIndices = <int>{};

  int get placedWeight => placedIndices.fold<int>(
        0,
        (sum, index) => sum + puzzle.weights[index],
      );
  int get remainingWeight => puzzle.targetWeight - placedWeight;
  bool get balanced => placedWeight == puzzle.targetWeight;
  bool get finished => round >= roundCount;
  double get progress => round / roundCount;

  bool place(int index) {
    if (finished || index < 0 || index >= puzzle.weights.length ||
        placedIndices.contains(index)) {
      return false;
    }
    final nextWeight = placedWeight + puzzle.weights[index];
    if (nextWeight > puzzle.targetWeight) {
      mistakes++;
      return false;
    }
    placedIndices.add(index);
    moves++;
    return true;
  }

  bool remove(int index) {
    if (finished || !placedIndices.remove(index)) return false;
    moves++;
    return true;
  }

  /// Advances only from an exactly balanced state. The final round ends the
  /// session and repeated advance calls cannot change the result.
  bool advance() {
    if (finished || !balanced) return false;
    round++;
    if (!finished) _loadRound();
    return true;
  }

  void _loadRound() {
    placedIndices.clear();
    puzzle = _generatePuzzle(seed: seed, round: round, revision: _revision++);
  }

  static BalancePuzzle _generatePuzzle({
    required int seed,
    required int round,
    required int revision,
  }) {
    final random = Random(seed ^ (round * 0x45d9f3b) ^ (revision * 0x119de1f3));
    final target = 9 + round * 3 + random.nextInt(5);
    final solutionLength = 2 + random.nextInt(3);
    final solution = <int>[];
    var remainder = target;
    for (var i = 0; i < solutionLength - 1; i++) {
      final slotsLeft = solutionLength - i - 1;
      final value = 1 + random.nextInt(min(8, remainder - slotsLeft));
      solution.add(value);
      remainder -= value;
    }
    solution.add(remainder);

    final weights = <int>[...solution];
    while (weights.length < 6) {
      final candidate = 1 + random.nextInt(10);
      // Keep distractors unique from the chosen solution values when possible.
      if (!weights.contains(candidate)) weights.add(candidate);
    }
    weights.shuffle(random);
    final solutionValues = <int>[...solution];
    final solutionIndices = <int>{};
    for (var i = 0; i < weights.length; i++) {
      final solutionIndex = solutionValues.indexOf(weights[i]);
      if (solutionIndex >= 0) {
        solutionIndices.add(i);
        solutionValues.removeAt(solutionIndex);
      }
    }
    return BalancePuzzle(
      targetWeight: target,
      weights: List<int>.unmodifiable(weights),
      solutionIndices: Set<int>.unmodifiable(solutionIndices),
    );
  }
}
