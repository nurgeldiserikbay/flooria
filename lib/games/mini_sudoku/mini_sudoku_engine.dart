import 'dart:math';

/// Compact Sudoku: each row, column and 2x2 box must contain 1,2,3,4.
/// Puzzles are deterministically generated and verified to be unique.
class MiniSudokuSession {
  MiniSudokuSession({required this.seed, this.roundCount = 3})
      : assert(roundCount > 0) {
    _newRound();
  }

  static const side = 4;
  final int seed;
  final int roundCount;
  int round = 0;
  int edits = 0;
  int checks = 0;
  int mistakes = 0;
  late List<int> solution;
  late List<int> clues;
  late List<int> board;

  bool get complete => round >= roundCount;
  bool get filled => board.every((n) => n != 0);

  static bool validPlacement(List<int> cells, int index, int number) {
    if (cells.length != 16 || index < 0 || index >= 16 ||
        number < 1 || number > 4) {
      return false;
    }
    final r = index ~/ 4;
    final c = index % 4;
    for (var i = 0; i < 16; i++) {
      if (i == index || cells[i] != number) continue;
      final otherR = i ~/ 4;
      final otherC = i % 4;
      if (otherR == r || otherC == c ||
          (otherR ~/ 2 == r ~/ 2 && otherC ~/ 2 == c ~/ 2)) {
        return false;
      }
    }
    return true;
  }

  /// Early-exit backtracking counter, capped at [limit] solutions.
  static int countSolutions(List<int> puzzle, {int limit = 2}) {
    if (puzzle.length != 16 || limit < 1 ||
        puzzle.any((n) => n < 0 || n > 4)) {
      throw ArgumentError('Invalid 4x4 Sudoku board or limit');
    }
    final work = List<int>.of(puzzle);
    for (var i = 0; i < 16; i++) {
      if (work[i] == 0) continue;
      final value = work[i];
      work[i] = 0;
      final allowed = validPlacement(work, i, value);
      work[i] = value;
      if (!allowed) return 0;
    }
    var found = 0;
    void search() {
      if (found >= limit) return;
      var choice = -1;
      var best = <int>[];
      for (var i = 0; i < 16; i++) {
        if (work[i] != 0) continue;
        final choices = [
          for (var n = 1; n <= 4; n++)
            if (validPlacement(work, i, n)) n,
        ];
        if (choices.isEmpty) return;
        if (choice == -1 || choices.length < best.length) {
          choice = i;
          best = choices;
        }
      }
      if (choice == -1) {
        found++;
        return;
      }
      for (final value in best) {
        work[choice] = value;
        search();
        work[choice] = 0;
        if (found >= limit) return;
      }
    }
    search();
    return found;
  }

  void _newRound() {
    if (complete) return;
    final random = Random((seed * 65537 + round * 8191) & 0x7fffffff);
    final digits = [1, 2, 3, 4]..shuffle(random);
    final rows = [0, 1, 2, 3];
    final columns = [0, 1, 2, 3];
    if (random.nextBool()) {
      final t = rows[0]; rows[0] = rows[1]; rows[1] = t;
    }
    if (random.nextBool()) {
      final t = rows[2]; rows[2] = rows[3]; rows[3] = t;
    }
    if (random.nextBool()) {
      rows.setAll(0, [...rows.skip(2), ...rows.take(2)]);
    }
    if (random.nextBool()) {
      final t = columns[0]; columns[0] = columns[1]; columns[1] = t;
    }
    if (random.nextBool()) {
      final t = columns[2]; columns[2] = columns[3]; columns[3] = t;
    }
    if (random.nextBool()) {
      columns.setAll(0, [...columns.skip(2), ...columns.take(2)]);
    }
    solution = [
      for (var r = 0; r < 4; r++)
        for (var c = 0; c < 4; c++)
          digits[(rows[r] * 2 + rows[r] ~/ 2 + columns[c]) % 4],
    ];
    clues = List<int>.of(solution);
    final positions = [for (var i = 0; i < 16; i++) i]..shuffle(random);
    final minimum = 8 - round;
    for (final index in positions) {
      if (clues.where((n) => n != 0).length <= minimum) break;
      final value = clues[index];
      clues[index] = 0;
      if (countSolutions(clues) != 1) clues[index] = value;
    }
    board = List<int>.of(clues);
  }

  Set<int> get conflicts {
    final result = <int>{};
    for (var i = 0; i < 16; i++) {
      if (board[i] == 0) continue;
      final value = board[i];
      final temp = List<int>.of(board)..[i] = 0;
      if (!validPlacement(temp, i, value)) result.add(i);
    }
    return result;
  }

  bool get solved => !complete && filled && conflicts.isEmpty;

  /// Empty -> 1 -> 2 -> 3 -> 4 -> empty. Fixed cells stay immutable.
  bool tap(int index) {
    if (complete || index < 0 || index >= 16 || clues[index] != 0) {
      return false;
    }
    board[index] = (board[index] + 1) % 5;
    edits++;
    return true;
  }

  bool check() {
    if (complete || !filled) return false;
    checks++;
    if (!solved) {
      mistakes++;
      return false;
    }
    round++;
    _newRound();
    return true;
  }
}
