import 'dart:math';

enum PictureMove { moved, completed, blocked, ignored }

/// Restore a small scene by sliding its image fragments into order.
class PictureAssembleEngine {
  PictureAssembleEngine._(this.level, this.tiles);

  static const int side = 3;
  final int level;
  final List<int> tiles;
  int moves = 0;
  bool isCompleted = false;
  int get blank => tiles.indexOf(0);
  int get score => max(100, 1000 - moves * 12).toInt();

  factory PictureAssembleEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final random = Random(safe * 42179 + 151);
    final tiles = [1, 2, 3, 4, 5, 6, 7, 8, 0];
    var previousBlank = -1;
    final shuffleMoves = min(180, 18 + safe * 3).toInt();
    for (var i = 0; i < shuffleMoves; i++) {
      final blank = tiles.indexOf(0);
      final choices = _neighbors(blank).where((cell) => cell != previousBlank).toList();
      final next = choices[random.nextInt(choices.length)];
      tiles[blank] = tiles[next];
      tiles[next] = 0;
      previousBlank = blank;
    }
    if (tiles.every((tile) => tile == 0 || tile == tiles.indexOf(tile) + 1)) {
      final blank = tiles.indexOf(0);
      final next = _neighbors(blank).first;
      tiles[blank] = tiles[next];
      tiles[next] = 0;
    }
    return PictureAssembleEngine._(safe, tiles);
  }

  PictureMove tap(int cell) {
    if (isCompleted || cell < 0 || cell >= tiles.length) return PictureMove.ignored;
    final gap = blank;
    if (!_neighbors(gap).contains(cell)) return PictureMove.blocked;
    tiles[gap] = tiles[cell];
    tiles[cell] = 0;
    moves++;
    isCompleted = true;
    for (var i = 0; i < tiles.length; i++) {
      if (tiles[i] != (i == tiles.length - 1 ? 0 : i + 1)) {
        isCompleted = false;
        break;
      }
    }
    return isCompleted ? PictureMove.completed : PictureMove.moved;
  }

  static List<int> _neighbors(int cell) {
    final row = cell ~/ side, col = cell % side;
    return [
      if (row > 0) cell - side,
      if (col < side - 1) cell + 1,
      if (row < side - 1) cell + side,
      if (col > 0) cell - 1,
    ];
  }
}
