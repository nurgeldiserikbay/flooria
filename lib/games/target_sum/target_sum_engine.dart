import 'dart:math';

class TargetSumBoard {
  const TargetSumBoard({
    required this.target,
    required this.chooseCount,
    required this.tiles,
  });

  final int target;
  final int chooseCount;
  final List<int> tiles;

  @override
  bool operator ==(Object other) => other is TargetSumBoard &&
      target == other.target &&
      chooseCount == other.chooseCount &&
      _same(tiles, other.tiles);

  @override
  int get hashCode => Object.hash(target, chooseCount, Object.hashAll(tiles));

  static bool _same<T>(List<T> left, List<T> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}

enum SumSubmitResult { invalid, wrong, correct }

/// Select a fixed number of tiles whose values add up to the target.
class TargetSumSession {
  TargetSumSession({required this.seed, int level = 1}) {
    final random = Random(seed);
    final chooseCount = level >= 4 ? 4 : 3;
    final tileCount = chooseCount == 3 ? 6 : 8;
    boards = List<TargetSumBoard>.unmodifiable(List.generate(
      boardCount,
      (_) => _makeBoard(random, chooseCount, tileCount),
    ));
  }

  static const int boardCount = 5;
  static const int passMistakeLimit = 6;

  final int seed;
  late final List<TargetSumBoard> boards;
  final Set<int> _selected = {};
  int boardIndex = 0;
  int mistakes = 0;

  bool get finished => boardIndex >= boardCount;
  bool get passed => finished && mistakes <= passMistakeLimit;
  int get completedBoards => boardIndex;
  double get progress => boardIndex / boardCount;
  TargetSumBoard get current => boards[boardIndex.clamp(0, boardCount - 1).toInt()];
  Set<int> get selected => Set<int>.unmodifiable(_selected);
  int get selectedSum => _selected.fold(0, (sum, index) => sum + current.tiles[index]);

  bool toggle(int tileIndex) {
    if (finished || tileIndex < 0 || tileIndex >= current.tiles.length) return false;
    if (_selected.remove(tileIndex)) return true;
    if (_selected.length >= current.chooseCount) return false;
    _selected.add(tileIndex);
    return true;
  }

  SumSubmitResult submit() {
    if (finished || _selected.length != current.chooseCount) {
      return SumSubmitResult.invalid;
    }
    if (selectedSum != current.target) {
      mistakes++;
      _selected.clear();
      return SumSubmitResult.wrong;
    }
    boardIndex++;
    _selected.clear();
    return SumSubmitResult.correct;
  }

  void clearSelection() => _selected.clear();

  static TargetSumBoard _makeBoard(Random random, int chooseCount, int tileCount) {
    final tiles = List<int>.generate(chooseCount, (_) => 2 + random.nextInt(10));
    final target = tiles.fold<int>(0, (sum, value) => sum + value);
    while (tiles.length < tileCount) {
      tiles.add(1 + random.nextInt(15));
    }
    tiles.shuffle(random);
    return TargetSumBoard(
      target: target,
      chooseCount: chooseCount,
      tiles: List<int>.unmodifiable(tiles),
    );
  }
}
