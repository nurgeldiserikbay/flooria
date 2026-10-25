import 'dart:math';

/// A clover patch is safe; hidden thorns are shown only after a misstep.
class CloverSweepPuzzle {
  CloverSweepPuzzle._({
    required this.mines,
  });

  static const int size = 6;
  static const int cellCount = size * size;
  static const int startCell = 0;

  final Set<int> mines;
  final Set<int> revealedSafeCells = <int>{};
  final Set<int> revealedMines = <int>{};
  final Set<int> flags = <int>{};
  int moves = 0;
  int mineHits = 0;

  int get safeCellCount => cellCount - mines.length;
  int get safeCellsRevealed => revealedSafeCells.length;
  int get remainingSafeCells => safeCellCount - safeCellsRevealed;
  bool get complete => safeCellsRevealed == safeCellCount;

  int adjacentMines(int cell) {
    if (cell < 0 || cell >= cellCount) return 0;
    return neighbors(cell).where(mines.contains).length;
  }

  /// Reveals one cell. Empty cells expand to adjacent safe cells.
  /// A thorn hit is recorded, but the player can keep solving the patch.
  bool reveal(int cell) {
    if (complete ||
        cell < 0 ||
        cell >= cellCount ||
        flags.contains(cell) ||
        revealedSafeCells.contains(cell) ||
        revealedMines.contains(cell)) {
      return false;
    }

    moves++;
    if (mines.contains(cell)) {
      revealedMines.add(cell);
      mineHits++;
      return true;
    }

    final queue = <int>[cell];
    for (var index = 0; index < queue.length; index++) {
      final current = queue[index];
      if (mines.contains(current) ||
          flags.contains(current) ||
          !revealedSafeCells.add(current)) {
        continue;
      }
      if (adjacentMines(current) == 0) {
        for (final next in neighbors(current)) {
          if (!mines.contains(next) &&
              !revealedSafeCells.contains(next) &&
              !flags.contains(next)) {
            queue.add(next);
          }
        }
      }
    }
    return true;
  }

  bool toggleFlag(int cell) {
    if (complete ||
        cell < 0 ||
        cell >= cellCount ||
        revealedSafeCells.contains(cell) ||
        revealedMines.contains(cell)) {
      return false;
    }
    if (!flags.add(cell)) flags.remove(cell);
    moves++;
    return true;
  }

  List<int> neighbors(int cell) {
    if (cell < 0 || cell >= cellCount) return const [];
    final row = cell ~/ size;
    final column = cell % size;
    final result = <int>[];
    for (var rowOffset = -1; rowOffset <= 1; rowOffset++) {
      for (var columnOffset = -1; columnOffset <= 1; columnOffset++) {
        if (rowOffset == 0 && columnOffset == 0) continue;
        final nextRow = row + rowOffset;
        final nextColumn = column + columnOffset;
        if (nextRow >= 0 &&
            nextRow < size &&
            nextColumn >= 0 &&
            nextColumn < size) {
          result.add(nextRow * size + nextColumn);
        }
      }
    }
    return result;
  }

  static CloverSweepPuzzle generate({required int seed, int round = 0}) {
    final random = Random(seed ^ (round * 104729) ^ 0x434C4F56);
    final mineCount = 5 + round * 2;
    final candidates = List<int>.generate(cellCount, (index) => index)
      ..removeWhere((cell) =>
          cell == 0 ||
          cell == 1 ||
          cell == size ||
          cell == size + 1)
      ..shuffle(random);
    return CloverSweepPuzzle._(
      mines: Set<int>.unmodifiable(candidates.take(mineCount)),
    );
  }
}

class CloverSweepSession {
  CloverSweepSession({required this.seed}) {
    puzzle = CloverSweepPuzzle.generate(seed: seed, round: round);
  }

  static const int totalRounds = 3;
  final int seed;
  int round = 0;
  int _mineHitsAcrossRounds = 0;
  late CloverSweepPuzzle puzzle;

  bool get complete => round >= totalRounds;
  bool get roundComplete => !complete && puzzle.complete;
  int get totalMineHits =>
      _mineHitsAcrossRounds + (complete ? 0 : puzzle.mineHits);
  int get totalMoves => _movesAcrossRounds + (complete ? 0 : puzzle.moves);

  int _movesAcrossRounds = 0;

  bool reveal(int cell) {
    if (complete || roundComplete) return false;
    return puzzle.reveal(cell);
  }

  bool toggleFlag(int cell) {
    if (complete || roundComplete) return false;
    return puzzle.toggleFlag(cell);
  }

  bool advance() {
    if (!roundComplete) return false;
    _movesAcrossRounds += puzzle.moves;
    _mineHitsAcrossRounds += puzzle.mineHits;
    round++;
    if (!complete) {
      puzzle = CloverSweepPuzzle.generate(seed: seed, round: round);
    }
    return true;
  }
}
