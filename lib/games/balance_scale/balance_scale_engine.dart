import 'dart:math';

enum BalanceMove { changed, balanced, ignored }

/// Pick a set of weights whose total balances the hidden object on the scale.
class BalanceScaleEngine {
  BalanceScaleEngine._(this.level, this.weights, this.target);

  final int level;
  final List<int> weights;
  final int target;
  final Set<int> selected = {};
  int moves = 0;
  bool isCompleted = false;
  int get total => selected.fold(0, (sum, index) => sum + weights[index]);
  int get difference => (target - total).abs();
  int get score => max(100, 1000 - moves * 28).toInt();

  factory BalanceScaleEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final random = Random(safe * 38183 + 131);
    final weights = [for (var value = 1; value <= 9; value++) value]..shuffle(random);
    final availableCount = min(8, 5 + (safe - 1) ~/ 16).toInt();
    final pieces = weights.take(availableCount).toList();
    final subsetSize = min(4, 2 + random.nextInt(3)).toInt();
    final target = pieces.take(subsetSize).fold(0, (sum, value) => sum + value);
    return BalanceScaleEngine._(safe, pieces, target);
  }

  BalanceMove toggle(int index) {
    if (isCompleted || index < 0 || index >= weights.length) return BalanceMove.ignored;
    if (!selected.add(index)) selected.remove(index);
    moves++;
    return BalanceMove.changed;
  }

  BalanceMove check() {
    if (isCompleted || selected.isEmpty) return BalanceMove.ignored;
    if (total != target) return BalanceMove.changed;
    isCompleted = true;
    return BalanceMove.balanced;
  }
}
