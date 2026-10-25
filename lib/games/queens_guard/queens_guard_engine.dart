import 'dart:math';

/// A 5x5 non-attacking queens puzzle with seeded fixed queens and obstacles.
///
/// Every round starts from a valid complete N-Queens arrangement; a locked
/// queen and blocked squares are then sampled without blocking that proof.
class QueensGuardSession {
  QueensGuardSession({required this.seed, this.roundCount = 3})
      : assert(roundCount > 0) {
    _startRound();
  }

  static const size = 5;
  final int seed;
  final int roundCount;
  int round = 0;
  int checks = 0;
  int mistakes = 0;
  int placements = 0;
  late final List<List<int>> _solutions = _enumerateSolutions();

  final Set<int> queens = {};
  final Set<int> blocked = {};
  late int fixedQueen;
  late Set<int> exampleSolution;

  bool get complete => round >= roundCount;
  bool get solved => !complete && queens.length == size &&
      conflicts.isEmpty && queens.contains(fixedQueen);

  static List<List<int>> _enumerateSolutions() {
    final results = <List<int>>[];
    final columns = <int>[];
    void search(int row) {
      if (row == size) {
        results.add(List.of(columns));
        return;
      }
      for (var col = 0; col < size; col++) {
        if (columns.asMap().entries.any((entry) =>
          entry.value == col ||
          (entry.key - row).abs() == (entry.value - col).abs())) {
          continue;
        }
        columns.add(col);
        search(row + 1);
        columns.removeLast();
      }
    }
    search(0);
    return results;
  }

  void _startRound() {
    if (complete) return;
    final random = Random((seed * 65537 + round * 8191) & 0x7fffffff);
    final solution = _solutions[random.nextInt(_solutions.length)];
    exampleSolution = {
      for (var row = 0; row < size; row++) row * size + solution[row],
    };
    fixedQueen = exampleSolution.toList()[random.nextInt(size)];
    queens
      ..clear()
      ..add(fixedQueen);
    blocked.clear();
    final candidates = [
      for (var i = 0; i < size * size; i++)
        if (!exampleSolution.contains(i)) i,
    ]..shuffle(random);
    blocked.addAll(candidates.take(1 + round * 2));
  }

  static bool attack(int a, int b) {
    if (a == b || a < 0 || b < 0 || a >= size * size || b >= size * size) {
      return false;
    }
    final rowA = a ~/ size, colA = a % size;
    final rowB = b ~/ size, colB = b % size;
    return rowA == rowB || colA == colB ||
        (rowA - rowB).abs() == (colA - colB).abs();
  }

  /// All queens participating in a collision, for live UI feedback.
  Set<int> get conflicts {
    final result = <int>{};
    for (final a in queens) {
      for (final b in queens) {
        if (attack(a, b)) {
          result.add(a);
          result.add(b);
        }
      }
    }
    return result;
  }

  bool toggle(int cell) {
    if (complete || cell < 0 || cell >= size * size ||
        blocked.contains(cell) || cell == fixedQueen) return false;
    if (!queens.remove(cell)) {
      if (queens.length >= size) return false;
      queens.add(cell);
    }
    placements++;
    return true;
  }

  /// Wrong submissions keep the board editable; a success starts next round.
  bool check() {
    if (complete || queens.length < size) return false;
    checks++;
    if (!solved) {
      mistakes++;
      return false;
    }
    round++;
    _startRound();
    return true;
  }
}
