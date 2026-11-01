import 'dart:math';

class SumRound {
  SumRound({required this.target, required this.picks,
    required List<int> values})
      : values = List<int>.unmodifiable(values);

  final int target;

  /// How many tiles must be combined.
  final int picks;
  final List<int> values;
}

enum SumPhase { picking, wrong, solved }

enum SumResult { ignored, placed, removed, correct, incorrect, completed }

/// Fill every slot with tiles that add up to the target. Each round is built
/// from a hidden solution; any other set with the same total also counts.
class TargetSumEngine {
  TargetSumEngine._({required this.level, required List<SumRound> rounds,
    required this.showRunningTotal})
      : rounds = List<SumRound>.unmodifiable(rounds);

  final int level;
  final List<SumRound> rounds;
  final bool showRunningTotal;

  int _roundIndex = 0;
  final List<int> _slots = [];
  SumPhase phase = SumPhase.picking;
  int mistakes = 0;

  int get roundIndex => _roundIndex;
  SumRound get currentRound => rounds[min(_roundIndex, rounds.length - 1)];
  bool get isCompleted => _roundIndex >= rounds.length;

  /// Tile indices placed into slots, in order.
  List<int> get slots => List<int>.unmodifiable(_slots);
  int get runningTotal =>
      _slots.fold(0, (sum, tile) => sum + currentRound.values[tile]);
  bool isUsed(int tile) => _slots.contains(tile);

  int get stars => mistakes == 0 ? 3 : mistakes <= 2 ? 2 : 1;
  int get score => max(100, rounds.length * 200 - mistakes * 60).toInt();
  int get mathMetric => (100 - mistakes * 12).clamp(30, 100).toInt();

  static ({int tiles, int minPicks, int maxPicks, int low, int high})
      rulesForLevel(int level) {
    if (level <= 4) return (tiles: 6, minPicks: 2, maxPicks: 2, low: 1, high: 9);
    if (level <= 9) return (tiles: 6, minPicks: 2, maxPicks: 3, low: 1, high: 9);
    if (level <= 19) return (tiles: 8, minPicks: 3, maxPicks: 3, low: 2, high: 15);
    if (level <= 34) return (tiles: 8, minPicks: 3, maxPicks: 4, low: 3, high: 25);
    if (level <= 59) return (tiles: 9, minPicks: 3, maxPicks: 4, low: 5, high: 40);
    return (tiles: 9, minPicks: 4, maxPicks: 4, low: 8, high: 60);
  }

  factory TargetSumEngine.forLevel(int level, {int? seed}) {
    final safeLevel = max(1, level).toInt();
    final rules = rulesForLevel(safeLevel);
    final random = Random(seed ?? safeLevel * 5381 + 29);
    final roundCount = safeLevel < 15 ? 5 : safeLevel < 40 ? 6 : 7;
    int pick() => rules.low + random.nextInt(rules.high - rules.low + 1);

    final rounds = <SumRound>[];
    while (rounds.length < roundCount) {
      final picks = rules.minPicks +
          random.nextInt(rules.maxPicks - rules.minPicks + 1);
      final solution = List<int>.generate(picks, (_) => pick());
      final target = solution.reduce((a, b) => a + b);
      final values = [...solution];
      while (values.length < rules.tiles) {
        values.add(pick());
      }
      values.shuffle(random);
      // Skip boards where every combination works; that is no puzzle.
      final solutions = countSolutions(values, picks, target);
      final combinations = _choose(values.length, picks);
      if (solutions * 3 > combinations) continue;
      rounds.add(SumRound(target: target, picks: picks, values: values));
    }
    return TargetSumEngine._(level: safeLevel, rounds: rounds,
      showRunningTotal: safeLevel < 20);
  }

  static int _choose(int n, int k) {
    var result = 1;
    for (var i = 0; i < k; i++) {
      result = result * (n - i) ~/ (i + 1);
    }
    return result;
  }

  /// Number of index sets of size [picks] summing to [target].
  static int countSolutions(List<int> values, int picks, int target) {
    var count = 0;
    void walk(int start, int left, int sum) {
      if (left == 0) {
        if (sum == target) count++;
        return;
      }
      for (var i = start; i <= values.length - left; i++) {
        walk(i + 1, left - 1, sum + values[i]);
      }
    }
    walk(0, picks, 0);
    return count;
  }

  /// Places a tile into the next free slot, or takes it back out.
  SumResult toggle(int tile) {
    if (isCompleted || phase != SumPhase.picking ||
        tile < 0 || tile >= currentRound.values.length) {
      return SumResult.ignored;
    }
    if (_slots.remove(tile)) return SumResult.removed;
    _slots.add(tile);
    if (_slots.length < currentRound.picks) return SumResult.placed;
    if (runningTotal == currentRound.target) {
      phase = SumPhase.solved;
      return _roundIndex == rounds.length - 1
          ? SumResult.completed : SumResult.correct;
    }
    mistakes++;
    phase = SumPhase.wrong;
    return SumResult.incorrect;
  }

  /// Empties the slots after a wrong total was shown.
  void clearWrong() {
    if (phase != SumPhase.wrong) return;
    _slots.clear();
    phase = SumPhase.picking;
  }

  /// Opens the next round after a solved one was shown.
  void advance() {
    if (phase != SumPhase.solved) return;
    _slots.clear();
    _roundIndex++;
    phase = SumPhase.picking;
  }
}
