import 'dart:collection';
import 'dart:math';

enum FloodMove { changed, completed, failed, ignored }

/// Grow a connected colour region until it covers the whole board.
class ColorFloodEngine {
  ColorFloodEngine._(this.level, this.colorCount, this.moveLimit, this._board) {
    _claimColor(_board[0]);
  }

  static const int side = 10;
  final int level;
  final int colorCount;
  final int moveLimit;
  final List<int> _board;
  final Set<int> _claimed = {};
  int moves = 0;
  bool isCompleted = false;
  bool isFailed = false;
  int get currentColor => _board[0];
  int get claimedCount => _claimed.length;
  int colorAt(int cell) => _board[cell];
  List<int> get board => List<int>.unmodifiable(_board);
  int get score => max(100, 1000 - moves * 18).toInt();

  factory ColorFloodEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final colors = min(4 + (safe - 1) ~/ 20, 6).toInt();
    final moveLimit = max(26, 34 - (colors - 4) * 3 - (safe - 1) ~/ 25).toInt();
    final random = Random(safe * 44497 + 41);
    const blocksPerSide = side ~/ 2;
    final blocks = [for (var i = 0; i < blocksPerSide * blocksPerSide; i++)
      random.nextInt(colors)];
    final board = [for (var row = 0; row < side; row++)
      for (var col = 0; col < side; col++)
        blocks[(row ~/ 2) * blocksPerSide + col ~/ 2]];
    return ColorFloodEngine._(safe, colors, moveLimit, board);
  }

  FloodMove chooseColor(int color) {
    if (isCompleted || isFailed || color < 0 || color >= colorCount || color == currentColor) {
      return FloodMove.ignored;
    }
    _claimColor(color);
    for (final cell in _claimed) {
      _board[cell] = color;
    }
    moves++;
    if (_claimed.length == _board.length) {
      isCompleted = true;
      return FloodMove.completed;
    }
    if (moves >= moveLimit) {
      isFailed = true;
      return FloodMove.failed;
    }
    return FloodMove.changed;
  }

  void _claimColor(int color) {
    final queue = Queue<int>();
    if (_claimed.isEmpty) {
      _claimed.add(0);
      queue.add(0);
    } else {
      final seeds = <int>{};
      for (final cell in List<int>.of(_claimed)) {
        for (final neighbor in _neighbors(cell)) {
          if (!_claimed.contains(neighbor) && _board[neighbor] == color) seeds.add(neighbor);
        }
      }
      _claimed.addAll(seeds);
      queue.addAll(seeds);
    }
    while (queue.isNotEmpty) {
      final cell = queue.removeFirst();
      for (final neighbor in _neighbors(cell)) {
        if (!_claimed.contains(neighbor) && _board[neighbor] == color) {
          _claimed.add(neighbor);
          queue.add(neighbor);
        }
      }
    }
  }

  List<int> _neighbors(int cell) {
    final row = cell ~/ side, col = cell % side;
    return [
      if (row > 0) cell - side,
      if (row + 1 < side) cell + side,
      if (col > 0) cell - 1,
      if (col + 1 < side) cell + 1,
    ];
  }
}
