import 'dart:math';

/// Pure Dart sliding-tile puzzle. Every initial board is produced by legal
/// movements from a solved state, so an impossible permutation is never shown.
class FifteenSession {
  FifteenSession({required int seed, int scrambleSteps = 24}) {
    final random = Random(seed);
    int previousBlank = -1;
    for (var step = 0; step < scrambleSteps; step++) {
      final options = movableIndices.where((index) => index != previousBlank)
          .toList();
      final candidates = options.isEmpty ? movableIndices : options;
      final from = candidates[random.nextInt(candidates.length)];
      previousBlank = blankIndex;
      _swap(from);
    }
    // Zero-move sessions and rare scramble loops must never start completed.
    if (isSolved) _swap(movableIndices.first);
  }

  final List<int> tiles = List<int>.generate(16, (i) => (i + 1) % 16);
  int moves = 0;

  int get blankIndex => tiles.indexOf(0);

  List<int> get movableIndices {
    final empty = blankIndex;
    return List<int>.generate(16, (i) => i).where((i) {
      final rowDistance = (i ~/ 4 - empty ~/ 4).abs();
      final colDistance = (i % 4 - empty % 4).abs();
      return rowDistance + colDistance == 1;
    }).toList();
  }

  bool get isSolved {
    for (var i = 0; i < 15; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return tiles[15] == 0;
  }

  void _swap(int index) {
    final empty = blankIndex;
    tiles[empty] = tiles[index];
    tiles[index] = 0;
  }

  bool move(int index) {
    if (isSolved || !movableIndices.contains(index)) return false;
    _swap(index);
    moves++;
    return true;
  }
}
