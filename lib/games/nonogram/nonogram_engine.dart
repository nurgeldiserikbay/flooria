/// Nonogram (picture logic) puzzles with an exact row/column-clue solution.
///
/// Base patterns have been checked for unique solutions. Rotations and
/// transpositions preserve uniqueness, so every seeded stage is fair.
class NonogramSession {
  NonogramSession({required this.seed, this.roundCount = 3})
      : assert(roundCount > 0) {
    _beginRound();
  }

  static const size = 5;
  static const List<List<String>> _patterns = [
    ['01010', '11111', '11111', '01110', '00100'],
    ['00100', '01110', '11111', '01110', '00100'],
    ['10001', '11011', '11111', '01110', '00100'],
    ['00100', '01110', '10101', '00100', '00100'],
    ['11111', '10001', '10101', '10001', '11111'],
    ['00100', '01110', '11111', '00100', '00100'],
    ['11011', '11011', '00000', '11011', '11011'],
  ];

  final int seed;
  final int roundCount;
  int round = 0;
  int checks = 0;
  int mistakes = 0;
  late List<bool> solution;
  late List<int> cells; // 0: unknown, 1: filled, 2: marked empty
  late List<List<int>> rowClues;
  late List<List<int>> columnClues;

  bool get finished => round >= roundCount;
  int get filledCount => cells.where((c) => c == 1).length;

  void _beginRound() {
    if (finished) return;
    final pattern = _patterns[((seed % _patterns.length) +
        (round % _patterns.length) + _patterns.length) % _patterns.length];
    var matrix = [
      for (final row in pattern)
        [for (final symbol in row.split('')) symbol == '1'],
    ];
    final quarterTurns = ((seed ~/ _patterns.length) + round) & 3;
    for (var turn = 0; turn < quarterTurns; turn++) {
      final original = matrix;
      matrix = [
        for (var y = 0; y < size; y++)
          [for (var x = 0; x < size; x++) original[size - 1 - x][y]],
      ];
    }
    solution = [for (final row in matrix) ...row];
    cells = List<int>.filled(size * size, 0);
    rowClues = [
      for (var y = 0; y < size; y++)
        runs([for (var x = 0; x < size; x++) solution[y * size + x]]),
    ];
    columnClues = [
      for (var x = 0; x < size; x++)
        runs([for (var y = 0; y < size; y++) solution[y * size + x]]),
    ];
  }

  static List<int> runs(List<bool> values) {
    final result = <int>[];
    var streak = 0;
    for (final filled in [...values, false]) {
      if (filled) {
        streak++;
      } else if (streak != 0) {
        result.add(streak);
        streak = 0;
      }
    }
    return result.isEmpty ? [0] : result;
  }

  /// Cycling tap: unknown -> colored -> crossed-out -> unknown.
  bool toggle(int index) {
    if (finished || index < 0 || index >= size * size) return false;
    cells[index] = (cells[index] + 1) % 3;
    return true;
  }

  bool get solved => !finished && List.generate(size * size, (i) => i)
      .every((i) => (cells[i] == 1) == solution[i]);

  /// Returns true when the submitted board completes its stage.
  /// A failed check leaves the board editable and increments mistakes.
  bool check() {
    if (finished || filledCount == 0) return false;
    checks++;
    if (!solved) {
      mistakes++;
      return false;
    }
    round++;
    if (!finished) _beginRound();
    return true;
  }
}
