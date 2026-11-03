import 'dart:math';

enum BubbleShot { placed, popped, completed, blocked, ignored }

/// Aim into a column, attach the bubble, and clear connected groups of three.
class BubbleShooterEngine {
  BubbleShooterEngine._(this.level, this.board, this.colorCount,
      this.goal, this._random);

  static const int columns = 7;
  static const int rows = 7;
  final int level;
  final List<int?> board;
  final int colorCount;
  final int goal;
  final Random _random;
  int shots = 0;
  int popped = 0;
  int currentColor = 0;
  bool isCompleted = false;
  int get score => max(100, 1000 + popped * 25 - shots * 12).toInt();
  bool get isFailed => !isCompleted && board.every((bubble) => bubble != null);

  factory BubbleShooterEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final random = Random(safe * 19211 + 41);
    final colors = min(5, 3 + (safe - 1) ~/ 18).toInt();
    final board = List<int?>.filled(rows * columns, null);
    final filledRows = min(5, 3 + (safe - 1) ~/ 12).toInt();
    for (var row = 0; row < filledRows; row++) {
      for (var col = 0; col < columns; col++) {
        board[row * columns + col] = random.nextInt(colors);
      }
    }
    final engine = BubbleShooterEngine._(safe, board, colors,
      min(30, 12 + (safe - 1) ~/ 2).toInt(), random);
    engine.currentColor = random.nextInt(colors);
    return engine;
  }

  BubbleShot shootAt(int column) {
    if (isCompleted || isFailed || column < 0 || column >= columns) {
      return BubbleShot.ignored;
    }
    var cell = -1;
    for (var row = rows - 1; row >= 0; row--) {
      final candidate = row * columns + column;
      if (board[candidate] == null) { cell = candidate; break; }
    }
    if (cell < 0) return BubbleShot.blocked;
    final color = currentColor;
    board[cell] = color;
    shots++;
    currentColor = _random.nextInt(colorCount);
    final group = _connected(cell);
    var poppedNow = false;
    if (group.length >= 3) {
      for (final bubble in group) { board[bubble] = null; }
      popped += group.length;
      poppedNow = true;
      final floating = _notConnectedToCeiling();
      for (final bubble in floating) { board[bubble] = null; }
      popped += floating.length;
    }
    isCompleted = popped >= goal;
    if (isCompleted) return BubbleShot.completed;
    return poppedNow ? BubbleShot.popped : BubbleShot.placed;
  }

  Set<int> _connected(int start) {
    final color = board[start];
    if (color == null) return {};
    final result = <int>{start};
    final queue = <int>[start];
    for (var index = 0; index < queue.length; index++) {
      final cell = queue[index];
      final row = cell ~/ columns, col = cell % columns;
      for (final (dr, dc) in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
        final r = row + dr, c = col + dc;
        if (r < 0 || r >= rows || c < 0 || c >= columns) continue;
        final next = r * columns + c;
        if (board[next] == color && result.add(next)) queue.add(next);
      }
    }
    return result;
  }

  Set<int> _notConnectedToCeiling() {
    final connected = <int>{};
    for (var col = 0; col < columns; col++) {
      final start = col;
      if (board[start] != null) connected.addAll(_connected(start));
    }
    return {for (var cell = 0; cell < board.length; cell++)
      if (board[cell] != null && !connected.contains(cell)) cell};
  }
}
