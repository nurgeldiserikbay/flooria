import 'dart:math';

/// One deterministic Lights Out puzzle. Applying [scramble] to an empty board
/// produces [litCells], so every generated board has a known solution.
class GlowGridBoard {
  GlowGridBoard({
    required this.size,
    required Iterable<int> litCells,
    required Iterable<int> scramble,
  })  : litCells = Set<int>.unmodifiable(litCells),
        scramble = List<int>.unmodifiable(scramble);

  final int size;
  final Set<int> litCells;
  final List<int> scramble;

  int get cellCount => size * size;
}

enum GlowGridMoveResult { invalid, changed, boardSolved }

/// Rules and seeded board generation for Glow Grid.
class GlowGridSession {
  GlowGridSession({required this.seed, int level = 1}) {
    final random = Random(seed);
    final size = level <= 2 ? 3 : (level <= 5 ? 4 : 5);
    boards = List<GlowGridBoard>.unmodifiable(List.generate(
      boardCount,
      (index) => _makeBoard(random, size, index),
    ));
    _litCells = Set<int>.from(boards.first.litCells);
  }

  static const int boardCount = 5;

  final int seed;
  late final List<GlowGridBoard> boards;
  late Set<int> _litCells;

  int boardIndex = 0;
  int moves = 0;

  bool get finished => boardIndex >= boardCount;
  int get completedBoards => boardIndex;
  double get progress => completedBoards / boardCount;
  GlowGridBoard get current =>
      boards[boardIndex.clamp(0, boardCount - 1).toInt()];
  Set<int> get litCells => Set<int>.unmodifiable(_litCells);

  /// Toggles a cell and its orthogonal neighbours. Invalid moves do nothing.
  GlowGridMoveResult toggle(int cellIndex) {
    if (finished || cellIndex < 0 || cellIndex >= current.cellCount) {
      return GlowGridMoveResult.invalid;
    }

    _toggleCellAndNeighbours(_litCells, current.size, cellIndex);
    moves++;
    if (_litCells.isNotEmpty) return GlowGridMoveResult.changed;

    boardIndex++;
    if (!finished) {
      _litCells = Set<int>.from(current.litCells);
    }
    return GlowGridMoveResult.boardSolved;
  }

  static GlowGridBoard _makeBoard(Random random, int size, int round) {
    final cellCount = size * size;
    final indexes = List<int>.generate(cellCount, (index) => index)
      ..shuffle(random);
    final moveCount = min(cellCount - 1, size + 1 + round);
    final scramble = indexes.take(moveCount).toList(growable: false);
    final lit = <int>{};
    for (final index in scramble) {
      _toggleCellAndNeighbours(lit, size, index);
    }

    // A small portion of valid scrambles can cancel to an empty board.
    // Add a deterministic valid move so every round begins visibly active.
    if (lit.isEmpty) {
      final fallback = indexes[moveCount];
      scramble.toList(); // keep the original solution immutable
      _toggleCellAndNeighbours(lit, size, fallback);
    }
    return GlowGridBoard(
      size: size,
      litCells: lit,
      scramble: scramble,
    );
  }

  static void _toggleCellAndNeighbours(Set<int> cells, int size, int index) {
    final row = index ~/ size;
    final column = index % size;
    _toggle(cells, index);
    if (row > 0) _toggle(cells, index - size);
    if (row < size - 1) _toggle(cells, index + size);
    if (column > 0) _toggle(cells, index - 1);
    if (column < size - 1) _toggle(cells, index + 1);
  }

  static void _toggle(Set<int> cells, int index) {
    if (!cells.add(index)) cells.remove(index);
  }
}
