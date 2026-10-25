import 'dart:math';

/// Fold a 6x6 sheet along its central lines and infer punched holes.
/// Every puzzle is a real folded-sheet projection, not a random answer mask.
enum PaperFold { left, right, top, bottom, both }

class PaperFoldSession {
  PaperFoldSession({required this.seed, this.roundCount = 3})
      : assert(roundCount > 0) {
    _newRound();
  }

  static const int size = 6;
  final int seed;
  final int roundCount;

  int round = 0;
  int attempts = 0;
  int mistakes = 0;
  bool get complete => round >= roundCount;

  late PaperFold fold;
  late Set<int> punches;
  late Set<int> solution;
  final Set<int> selected = {};

  int get foldedRows => switch (fold) {
    PaperFold.top || PaperFold.bottom || PaperFold.both => 3,
    _ => 6,
  };
  int get foldedColumns => switch (fold) {
    PaperFold.left || PaperFold.right || PaperFold.both => 3,
    _ => 6,
  };

  /// Flat index into the original, unfolded 6x6 paper.
  static int index(int row, int column) => row * size + column;

  /// Punches are expressed in local coordinates of the visible folded sheet.
  /// The fold direction determines the visible half and mirrored layers.
  Set<int> get visibleCells {
    final cells = <int>{};
    for (var row = 0; row < foldedRows; row++) {
      for (var column = 0; column < foldedColumns; column++) {
        cells.add(row * foldedColumns + column);
      }
    }
    return cells;
  }

  Set<int> unfoldPunch(int localIndex) {
    if (!visibleCells.contains(localIndex)) return {};
    final localRow = localIndex ~/ foldedColumns;
    final localColumn = localIndex % foldedColumns;
    final baseRow = switch (fold) {
      PaperFold.bottom || PaperFold.both => localRow + 3,
      _ => localRow,
    };
    final baseColumn = switch (fold) {
      PaperFold.right || PaperFold.both => localColumn + 3,
      _ => localColumn,
    };
    final vertical = fold == PaperFold.top ||
        fold == PaperFold.bottom || fold == PaperFold.both;
    final horizontal = fold == PaperFold.left ||
        fold == PaperFold.right || fold == PaperFold.both;
    final rows = vertical ? {baseRow, size - 1 - baseRow} : {baseRow};
    final columns = horizontal
        ? {baseColumn, size - 1 - baseColumn}
        : {baseColumn};
    return {
      for (final r in rows)
        for (final c in columns) index(r, c),
    };
  }

  void _newRound() {
    if (complete) return;
    final random = Random((seed * 65537 + round * 1429) & 0x7fffffff);
    fold = PaperFold.values[random.nextInt(PaperFold.values.length)];
    final candidates = visibleCells.toList()..shuffle(random);
    final holeCount = round == 0 ? 1 : round == 1 ? 2 : 3;
    punches = candidates.take(holeCount).toSet();
    solution = {
      for (final punch in punches) ...unfoldPunch(punch),
    };
    selected.clear();
  }

  bool toggle(int cell) {
    if (complete || cell < 0 || cell >= size * size) return false;
    if (!selected.add(cell)) selected.remove(cell);
    return true;
  }

  bool get correct => !complete && selected.length == solution.length &&
      selected.containsAll(solution);

  /// Attempts that miss leave the player's marks in place for correction.
  bool check() {
    if (complete || selected.isEmpty) return false;
    attempts++;
    if (!correct) {
      mistakes++;
      return false;
    }
    round++;
    _newRound();
    return true;
  }
}
