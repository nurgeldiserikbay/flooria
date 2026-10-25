import 'dart:math';

/// A 5x5 picture puzzle described by contiguous filled-cell counts.
class PixelGardenPuzzle {
  PixelGardenPuzzle._({
    required this.targetCells,
    required this.rowClues,
    required this.columnClues,
  });

  static const int size = 5;
  static const int cellCount = size * size;

  final Set<int> targetCells;
  final List<List<int>> rowClues;
  final List<List<int>> columnClues;
  final Set<int> filledCells = <int>{};
  int moves = 0;
  int mistakes = 0;

  bool get solved =>
      filledCells.length == targetCells.length &&
      targetCells.every(filledCells.contains);

  /// Adds or removes a filled square. Invalid cells and solved boards are inert.
  bool toggle(int cell) {
    if (solved || cell < 0 || cell >= cellCount) return false;
    if (filledCells.remove(cell)) {
      moves++;
      return true;
    }
    filledCells.add(cell);
    moves++;
    if (!targetCells.contains(cell)) mistakes++;
    return true;
  }

  static PixelGardenPuzzle generate({required int seed, int round = 0}) {
    final random = Random(seed ^ (round * 104729) ^ 0x50495845);
    for (var attempt = 0; attempt < 256; attempt++) {
      final matrix = List<List<bool>>.generate(
        size,
        (_) => List<bool>.generate(size, (_) => random.nextInt(100) < 46),
      );
      final filledCount = matrix.fold<int>(
        0,
        (sum, row) => sum + row.where((cell) => cell).length,
      );
      if (filledCount < 5 || filledCount > 20) continue;
      final rows = matrix.map(_lineClues).toList(growable: false);
      final columns = List<List<int>>.generate(
        size,
        (column) => _lineClues(
          List<bool>.generate(size, (row) => matrix[row][column]),
        ),
        growable: false,
      );
      if (countSolutions(rowClues: rows, columnClues: columns) != 1) {
        continue;
      }

      final target = <int>{};
      for (var row = 0; row < size; row++) {
        for (var column = 0; column < size; column++) {
          if (matrix[row][column]) target.add(row * size + column);
        }
      }
      return _create(target, rows, columns);
    }

    // A known uniquely solvable pattern keeps generation bounded even if a
    // future random implementation produces an unusual sequence.
    const fallback = <List<bool>>[
      [true, true, false, false, true],
      [true, false, false, true, false],
      [true, true, false, false, true],
      [false, false, true, false, false],
      [true, true, true, true, true],
    ];
    final rows = fallback.map(_lineClues).toList(growable: false);
    final columns = List<List<int>>.generate(
      size,
      (column) => _lineClues(
        List<bool>.generate(size, (row) => fallback[row][column]),
      ),
      growable: false,
    );
    final target = <int>{
      for (var row = 0; row < size; row++)
        for (var column = 0; column < size; column++)
          if (fallback[row][column]) row * size + column,
    };
    return _create(target, rows, columns);
  }

  static PixelGardenPuzzle _create(
    Set<int> target,
    List<List<int>> rows,
    List<List<int>> columns,
  ) =>
      PixelGardenPuzzle._(
        targetCells: Set<int>.unmodifiable(target),
        rowClues: List<List<int>>.unmodifiable(
          rows.map(List<int>.unmodifiable),
        ),
        columnClues: List<List<int>>.unmodifiable(
          columns.map(List<int>.unmodifiable),
        ),
      );

  /// Counts solutions up to two; useful for validating generated clues.
  static int countSolutions({
    required List<List<int>> rowClues,
    required List<List<int>> columnClues,
  }) {
    if (rowClues.length != size || columnClues.length != size) return 0;
    final rowOptions = rowClues.map((clues) {
      return List<List<bool>>.generate(1 << size, (mask) {
        return List<bool>.generate(
          size,
          (column) => (mask & (1 << column)) != 0,
        );
      }).where((line) => _sameClues(_lineClues(line), clues)).toList();
    }).toList();

    var solutions = 0;
    final chosenRows = <List<bool>>[];

    void search(int row) {
      if (solutions >= 2) return;
      if (row == size) {
        for (var column = 0; column < size; column++) {
          final line = List<bool>.generate(
            size,
            (index) => chosenRows[index][column],
          );
          if (!_sameClues(_lineClues(line), columnClues[column])) return;
        }
        solutions++;
        return;
      }

      for (final option in rowOptions[row]) {
        chosenRows.add(option);
        search(row + 1);
        chosenRows.removeLast();
        if (solutions >= 2) return;
      }
    }

    search(0);
    return solutions;
  }

  static List<int> _lineClues(List<bool> line) {
    final result = <int>[];
    var run = 0;
    for (final filled in line) {
      if (filled) {
        run++;
      } else if (run > 0) {
        result.add(run);
        run = 0;
      }
    }
    if (run > 0) result.add(run);
    return result;
  }

  static bool _sameClues(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}

class PixelGardenSession {
  PixelGardenSession({required this.seed}) {
    puzzle = PixelGardenPuzzle.generate(seed: seed, round: round);
  }

  static const int totalRounds = 3;
  final int seed;
  int round = 0;
  int _movesAcrossRounds = 0;
  int _mistakesAcrossRounds = 0;
  late PixelGardenPuzzle puzzle;

  bool get complete => round >= totalRounds;
  bool get roundComplete => !complete && puzzle.solved;
  int get totalMoves => _movesAcrossRounds + (complete ? 0 : puzzle.moves);
  int get totalMistakes =>
      _mistakesAcrossRounds + (complete ? 0 : puzzle.mistakes);

  bool toggle(int cell) {
    if (complete || roundComplete) return false;
    return puzzle.toggle(cell);
  }

  bool advance() {
    if (!roundComplete) return false;
    _movesAcrossRounds += puzzle.moves;
    _mistakesAcrossRounds += puzzle.mistakes;
    round++;
    if (!complete) {
      puzzle = PixelGardenPuzzle.generate(seed: seed, round: round);
    }
    return true;
  }
}
