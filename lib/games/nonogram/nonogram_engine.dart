import 'dart:math';

enum NonogramMark { updated, completed, ignored }

/// Tiny picture-cross puzzle with generated row and column clues.
class NonogramEngine {
  NonogramEngine._(this.level, this.rowClues, this.columnClues, this.marks);

  static const int side = 6;
  static const List<List<String>> _patterns = [
    ['001100', '011110', '111111', '111111', '011110', '001100'],
    ['110011', '111111', '011110', '001100', '011110', '111111'],
    ['001000', '011100', '111110', '011111', '001110', '000100'],
    ['111100', '100100', '111100', '100100', '100100', '111100'],
    ['001100', '011110', '111111', '001100', '001100', '001100'],
    ['100001', '110011', '111111', '011110', '001100', '000000'],
    ['000110', '001110', '011100', '111000', '110000', '100000'],
    ['011110', '110011', '110011', '011110', '001100', '001100'],
  ];

  final int level;
  final List<List<int>> rowClues;
  final List<List<int>> columnClues;
  final List<int> marks;
  int moves = 0;
  bool isCompleted = false;
  int get score => max(100, 1000 - moves * 8).toInt();

  factory NonogramEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final patternIndex = (safe - 1) % _patterns.length;
    final turns = ((safe - 1) ~/ _patterns.length) % 4;
    final flip = ((safe - 1) ~/ (_patterns.length * 4)).isOdd;
    var rows = _patterns[patternIndex].map((line) =>
      line.split('').map((value) => value == '1').toList()).toList();
    for (var turn = 0; turn < turns; turn++) {
      rows = [for (var row = 0; row < side; row++)
        [for (var col = 0; col < side; col++) rows[side - 1 - col][row]]];
    }
    if (flip) rows = rows.map((row) => row.reversed.toList()).toList();
    final rowClues = [for (final row in rows) _lineClues(row)];
    final columnClues = [for (var col = 0; col < side; col++)
      _lineClues([for (var row = 0; row < side; row++) rows[row][col]])];
    return NonogramEngine._(safe, rowClues, columnClues,
      List<int>.filled(side * side, 0));
  }

  NonogramMark tapCell(int cell) {
    if (isCompleted || cell < 0 || cell >= marks.length) return NonogramMark.ignored;
    marks[cell] = (marks[cell] + 1) % 3;
    moves++;
    isCompleted = _matchesAllClues();
    return isCompleted ? NonogramMark.completed : NonogramMark.updated;
  }

  static List<int> _lineClues(Iterable<bool> cells) {
    final clues = <int>[];
    var run = 0;
    for (final filled in cells) {
      if (filled) {
        run++;
      } else if (run > 0) {
        clues.add(run);
        run = 0;
      }
    }
    if (run > 0) clues.add(run);
    return clues.isEmpty ? [0] : clues;
  }

  bool _matchesAllClues() {
    for (var row = 0; row < side; row++) {
      final actual = _lineClues([for (var col = 0; col < side; col++)
        marks[row * side + col] == 1]);
      if (!_same(actual, rowClues[row])) return false;
    }
    for (var col = 0; col < side; col++) {
      final actual = _lineClues([for (var row = 0; row < side; row++)
        marks[row * side + col] == 1]);
      if (!_same(actual, columnClues[col])) return false;
    }
    return true;
  }

  bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
