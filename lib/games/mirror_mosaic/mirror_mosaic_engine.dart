import 'dart:math';

enum MirrorAxis { vertical, horizontal }

/// A pattern on one side of an axis and the cells it reflects into.
class MirrorMosaicBoard {
  MirrorMosaicBoard({
    required this.size,
    required this.axis,
    required Iterable<int> sourceCells,
  })  : sourceCells = Set<int>.unmodifiable(sourceCells),
        targetCells = Set<int>.unmodifiable(
          sourceCells.map((index) => _mirror(index, size, axis)),
        );

  final int size;
  final MirrorAxis axis;
  final Set<int> sourceCells;
  final Set<int> targetCells;

  int get cellCount => size * size;
  int get axisIndex => size ~/ 2;
  int get targetCount => targetCells.length;

  bool isPlayable(int index) {
    if (index < 0 || index >= cellCount) return false;
    final row = index ~/ size;
    final column = index % size;
    return axis == MirrorAxis.vertical
        ? column > axisIndex
        : row > axisIndex;
  }

  static int _mirror(int index, int size, MirrorAxis axis) {
    final row = index ~/ size;
    final column = index % size;
    return axis == MirrorAxis.vertical
        ? row * size + (size - 1 - column)
        : (size - 1 - row) * size + column;
  }
}

enum MirrorMosaicMoveResult { invalid, changed, boardSolved }

/// Seeded reflection puzzles with a guaranteed target derived from each source.
class MirrorMosaicSession {
  MirrorMosaicSession({required this.seed}) {
    final random = Random(seed);
    boards = List<MirrorMosaicBoard>.unmodifiable(List.generate(
      boardCount,
      (round) => _makeBoard(random, round),
    ));
  }

  static const int boardCount = 5;
  static const int gridSize = 5;

  final int seed;
  late final List<MirrorMosaicBoard> boards;
  final Set<int> _selected = {};

  int boardIndex = 0;
  int mistakes = 0;

  bool get finished => boardIndex >= boardCount;
  int get completedBoards => boardIndex;
  double get progress => completedBoards / boardCount;
  MirrorMosaicBoard get current =>
      boards[boardIndex.clamp(0, boardCount - 1).toInt()];
  Set<int> get selected => Set<int>.unmodifiable(_selected);

  /// Adds/removes a tile in the reflected half. Invalid locations do nothing.
  MirrorMosaicMoveResult toggle(int index) {
    if (finished || !current.isPlayable(index)) {
      return MirrorMosaicMoveResult.invalid;
    }

    if (_selected.remove(index)) return MirrorMosaicMoveResult.changed;
    _selected.add(index);
    if (!current.targetCells.contains(index)) mistakes++;

    if (_selected.length == current.targetCount &&
        _selected.containsAll(current.targetCells)) {
      boardIndex++;
      _selected.clear();
      return MirrorMosaicMoveResult.boardSolved;
    }
    return MirrorMosaicMoveResult.changed;
  }

  MirrorMosaicBoard _makeBoard(Random random, int round) {
    final axis = random.nextBool() ? MirrorAxis.vertical : MirrorAxis.horizontal;
    final candidates = <int>[
      for (var row = 0; row < gridSize; row++)
        for (var column = 0; column < gridSize; column++)
          if (axis == MirrorAxis.vertical
              ? column < gridSize ~/ 2
              : row < gridSize ~/ 2)
            row * gridSize + column,
    ]..shuffle(random);
    final count = 2 + round ~/ 2;
    return MirrorMosaicBoard(
      size: gridSize,
      axis: axis,
      sourceCells: candidates.take(count),
    );
  }
}
