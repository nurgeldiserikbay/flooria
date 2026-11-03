import 'dart:math';

enum PegMove { selected, moved, blocked, completed, failed, ignored }

/// Cross-board peg solitaire. Puzzles are built backwards from a one-peg goal,
/// so every generated starting board has at least one solution.
class PegSolitaireEngine {
  PegSolitaireEngine._({required this.level, required this.board}) {
    _checkEndState();
  }

  static const int side = 7;
  static const int goalPegs = 1;
  static const List<(int, int)> _directions = [(-2, 0), (2, 0), (0, -2), (0, 2)];
  final int level;
  final List<int> board;
  int? _selected;
  int moves = 0;
  bool isCompleted = false;
  bool isFailed = false;

  int get pegCount => board.where((value) => value == 1).length;
  int? get selectedCell => _selected;
  int get score => max(100, 1000 - moves * 12).toInt();

  static bool isValidCell(int index) {
    final row = index ~/ side, col = index % side;
    return (row >= 2 && row <= 4) || (col >= 2 && col <= 4);
  }

  factory PegSolitaireEngine.forLevel(int level, {int? seed}) {
    final safe = max(1, level).toInt();
    final target = min(8 + safe ~/ 2, 28).toInt();
    final random = Random(seed ?? safe * 7919 + 31);
    List<int>? puzzle;
    for (var attempt = 0; attempt < 80; attempt++) {
      final candidate = List<int>.filled(side * side, 0);
      candidate[3 * side + 3] = 1;
      var count = 1;
      while (count < target) {
        final reverseMoves = <(int, int, int)>[];
        for (var dest = 0; dest < candidate.length; dest++) {
          if (!isValidCell(dest) || candidate[dest] == 0) continue;
          final row = dest ~/ side, col = dest % side;
          for (final (dr, dc) in _directions) {
            final sourceRow = row + dr, sourceCol = col + dc;
            final middleRow = row + dr ~/ 2, middleCol = col + dc ~/ 2;
            if (sourceRow < 0 || sourceCol < 0 || sourceRow >= side || sourceCol >= side) continue;
            final source = sourceRow * side + sourceCol;
            final middle = middleRow * side + middleCol;
            if (!isValidCell(source) || !isValidCell(middle) ||
                candidate[source] != 0 || candidate[middle] != 0) continue;
            reverseMoves.add((source, middle, dest));
          }
        }
        if (reverseMoves.isEmpty) break;
        final (source, middle, dest) = reverseMoves[random.nextInt(reverseMoves.length)];
        candidate[source] = 1;
        candidate[middle] = 1;
        candidate[dest] = 0;
        count++;
      }
      if (count == target) { puzzle = candidate; break; }
    }
    puzzle ??= _standardStartingBoard();
    return PegSolitaireEngine._(level: safe, board: puzzle);
  }

  static List<int> _standardStartingBoard() => [
    for (var i = 0; i < side * side; i++)
      if (isValidCell(i) && i != 3 * side + 3) 1 else 0,
  ];

  PegMove tap(int cell) {
    if (isCompleted || isFailed || cell < 0 || cell >= board.length ||
        !isValidCell(cell)) return PegMove.ignored;
    final source = _selected;
    if (source == null) {
      if (board[cell] == 0) return PegMove.ignored;
      _selected = cell;
      return PegMove.selected;
    }
    if (source == cell) {
      _selected = null;
      return PegMove.ignored;
    }
    final sr = source ~/ side, sc = source % side;
    final tr = cell ~/ side, tc = cell % side;
    if (board[source] == 0 || board[cell] != 0 ||
        !((sr == tr && (sc - tc).abs() == 2) ||
          (sc == tc && (sr - tr).abs() == 2))) {
      return PegMove.blocked;
    }
    final middle = ((sr + tr) ~/ 2) * side + (sc + tc) ~/ 2;
    if (board[middle] == 0) return PegMove.blocked;
    board[source] = 0;
    board[middle] = 0;
    board[cell] = 1;
    _selected = null;
    moves++;
    if (pegCount <= goalPegs) {
      isCompleted = true;
      return PegMove.completed;
    }
    if (!_hasLegalMove()) {
      isFailed = true;
      return PegMove.failed;
    }
    return PegMove.moved;
  }

  void _checkEndState() {
    isCompleted = pegCount <= goalPegs;
  }

  bool _hasLegalMove() {
    for (var source = 0; source < board.length; source++) {
      if (board[source] == 0) continue;
      final row = source ~/ side, col = source % side;
      for (final (dr, dc) in _directions) {
        final nr = row + dr, nc = col + dc;
        if (nr < 0 || nc < 0 || nr >= side || nc >= side) continue;
        final target = nr * side + nc;
        final middle = (row + dr ~/ 2) * side + col + dc ~/ 2;
        if (isValidCell(target) && isValidCell(middle) &&
            board[target] == 0 && board[middle] == 1) return true;
      }
    }
    return false;
  }
}
