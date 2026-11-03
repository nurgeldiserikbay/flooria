import 'dart:math';

enum DominoMove { placed, completed, blocked, ignored }

class DominoTile {
  const DominoTile({required this.id, required this.left, required this.right});
  final int id;
  final int left;
  final int right;
}

/// Build one continuous line by connecting matching ends of shuffled dominoes.
class DominoChainEngine {
  DominoChainEngine._(this.level, this.startValue, this.tiles)
      : placed = [],
        openValue = startValue;

  final int level;
  final int startValue;
  final List<DominoTile> tiles;
  final List<DominoTile> placed;
  final Set<int> used = {};
  int openValue;
  int mistakes = 0;
  bool isCompleted = false;
  int get score => max(100, 1000 - mistakes * 35 - placed.length * 5).toInt();

  factory DominoChainEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final random = Random(safe * 25153 + 61);
    final count = min(4 + (safe - 1) ~/ 10, 10).toInt();
    final values = [for (var i = 0; i <= count; i++) random.nextInt(6)];
    final tiles = [for (var i = 0; i < count; i++)
      DominoTile(id: i, left: values[i], right: values[i + 1])];
    for (var i = 0; i < tiles.length; i++) {
      if (random.nextBool()) {
        final tile = tiles[i];
        tiles[i] = DominoTile(id: tile.id, left: tile.right, right: tile.left);
      }
    }
    tiles.shuffle(random);
    return DominoChainEngine._(safe, values.first, tiles);
  }

  DominoMove place(int tileId) {
    if (isCompleted || tileId < 0 || tileId >= tiles.length || used.contains(tileId)) {
      return DominoMove.ignored;
    }
    final tile = tiles.firstWhere((item) => item.id == tileId);
    late final DominoTile oriented;
    if (tile.left == openValue) {
      oriented = tile;
      openValue = tile.right;
    } else if (tile.right == openValue) {
      oriented = DominoTile(id: tile.id, left: tile.right, right: tile.left);
      openValue = tile.left;
    } else {
      mistakes++;
      return DominoMove.blocked;
    }
    used.add(tile.id);
    placed.add(oriented);
    if (placed.length == tiles.length) {
      isCompleted = true;
      return DominoMove.completed;
    }
    return DominoMove.placed;
  }
}
