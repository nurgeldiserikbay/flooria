import 'dart:math';

enum MatchMove { selected, swapped, rejected, completed, ignored }

/// Swap adjacent gems to clear the level's target before moves run out.
class MatchThreeEngine {
  MatchThreeEngine._(this.level, this.board, this.moveLimit, this.goal, this._random);

  static const int side = 7;
  static const int colorCount = 5;
  final int level;
  final List<int> board;
  final int moveLimit;
  final int goal;
  final Random _random;
  int moves = 0;
  int cleared = 0;
  int? selected;
  bool isCompleted = false;
  bool get isFailed => !isCompleted && moves >= moveLimit;
  int get movesLeft => moveLimit - moves;
  int get score => max(100, 1000 + cleared * 12 - moves * 18).toInt();

  factory MatchThreeEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final random = Random(safe * 21487 + 53);
    List<int> makeBoard() {
      final result = List<int>.filled(side * side, 0);
      for (var cell = 0; cell < result.length; cell++) {
        var color = random.nextInt(colorCount);
        while ((cell % side >= 2 && result[cell - 1] == color &&
                result[cell - 2] == color) ||
            (cell >= side * 2 && result[cell - side] == color &&
                result[cell - side * 2] == color)) {
          color = random.nextInt(colorCount);
        }
        result[cell] = color;
      }
      return result;
    }
    final board = makeBoard();
    return MatchThreeEngine._(safe, board,
      max(16, 22 - (safe - 1) ~/ 10).toInt(),
      min(40, 14 + (safe - 1) ~/ 3).toInt(), random);
  }

  MatchMove tap(int cell) {
    if (isCompleted || isFailed || cell < 0 || cell >= board.length) {
      return MatchMove.ignored;
    }
    final first = selected;
    if (first == null || !_adjacent(first, cell)) {
      selected = cell;
      return MatchMove.selected;
    }
    selected = null;
    final temp = board[first];
    board[first] = board[cell];
    board[cell] = temp;
    if (_matches().isEmpty) {
      board[cell] = board[first];
      board[first] = temp;
      return MatchMove.rejected;
    }
    moves++;
    _resolve();
    isCompleted = cleared >= goal;
    return isCompleted ? MatchMove.completed : MatchMove.swapped;
  }

  Set<int> _matches() {
    final matched = <int>{};
    for (var row = 0; row < side; row++) {
      var start = 0;
      while (start < side) {
        final color = board[row * side + start];
        var end = start + 1;
        while (end < side && board[row * side + end] == color) { end++; }
        if (end - start >= 3) {
          for (var col = start; col < end; col++) { matched.add(row * side + col); }
        }
        start = end;
      }
    }
    for (var col = 0; col < side; col++) {
      var start = 0;
      while (start < side) {
        final color = board[start * side + col];
        var end = start + 1;
        while (end < side && board[end * side + col] == color) { end++; }
        if (end - start >= 3) {
          for (var row = start; row < end; row++) { matched.add(row * side + col); }
        }
        start = end;
      }
    }
    return matched;
  }

  void _resolve() {
    for (var cascade = 0; cascade < side * side; cascade++) {
      final matched = _matches();
      if (matched.isEmpty) return;
      cleared += matched.length;
      for (final cell in matched) { board[cell] = -1; }
      for (var col = 0; col < side; col++) {
        var writeRow = side - 1;
        for (var row = side - 1; row >= 0; row--) {
          final value = board[row * side + col];
          if (value >= 0) {
            board[writeRow * side + col] = value;
            writeRow--;
          }
        }
        while (writeRow >= 0) { board[writeRow * side + col] = _random.nextInt(colorCount); writeRow--; }
      }
    }
  }

  bool _adjacent(int a, int b) =>
      ((a ~/ side) - (b ~/ side)).abs() + ((a % side) - (b % side)).abs() == 1;
}
