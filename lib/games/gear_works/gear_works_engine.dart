import 'dart:math';

/// A 5x5 orthogonal gear train. The driver at (row 2, col 0) must
/// transmit motion to the receiver at (row 2, col 4).
///
/// Every generated board is solvable: its initial layout is derived from a
/// path between driver and receiver, then some path gears are removed.
class GearWorksSession {
  GearWorksSession({required this.seed, this.size = 5})
      : assert(size >= 5 && size.isOdd),
        driver = (size ~/ 2) * size,
        receiver = (size ~/ 2) * size + size - 1 {
    _generate();
  }

  final int seed;
  final int size;
  final int driver;
  final int receiver;
  final Set<int> fixedGears = {};
  final Set<int> blockers = {};
  final Set<int> placedGears = {};
  final Set<int> solutionGears = {};
  late final int inventory;
  int moves = 0;

  void _generate() {
    final random = Random(seed);
    final row = size ~/ 2;
    final path = <int>[driver];
    var currentRow = row;
    for (var col = 1; col < size; col++) {
      final delta = col == size - 1 ? row - currentRow
          : random.nextInt(3) - 1;
      final nextRow = (currentRow + delta).clamp(1, size - 2);
      while (currentRow != nextRow) {
        currentRow += currentRow < nextRow ? 1 : -1;
        path.add(currentRow * size + col - 1);
      }
      path.add(currentRow * size + col);
    }
    // Final horizontal move always enters the receiver at center row.
    // Solution gears are every intermediate cell of this proven route.
    solutionGears.addAll(path.where((cell) =>
        cell != driver && cell != receiver));
    final candidates = solutionGears.toList()..shuffle(random);
    if (candidates.isNotEmpty) fixedGears.add(candidates.first);
    if (candidates.length > 3) fixedGears.add(candidates[1]);
    inventory = solutionGears.length - fixedGears.length;

    final freeCells = List<int>.generate(size * size, (i) => i)
        .where((cell) => !path.contains(cell)).toList()..shuffle(random);
    blockers.addAll(freeCells.take(size ~/ 2));
  }

  bool get complete => powered.contains(receiver);
  int get remaining => inventory - placedGears.length;

  bool get isValidSolution => solutionGears.every((cell) =>
      fixedGears.contains(cell) || placedGears.contains(cell));

  Set<int> get occupied => {
    driver, receiver, ...fixedGears, ...placedGears,
  };

  Iterable<int> neighbors(int cell) sync* {
    final row = cell ~/ size;
    final col = cell % size;
    if (row > 0) yield cell - size;
    if (col < size - 1) yield cell + 1;
    if (row < size - 1) yield cell + size;
    if (col > 0) yield cell - 1;
  }

  /// Connected gears rotate, alternating direction for every engagement.
  Map<int, int> get spinDirections {
    final cells = occupied;
    final rotations = <int, int>{driver: 1};
    final queue = <int>[driver];
    for (var index = 0; index < queue.length; index++) {
      final current = queue[index];
      for (final next in neighbors(current)) {
        if (!cells.contains(next) || rotations.containsKey(next)) continue;
        rotations[next] = -rotations[current]!;
        queue.add(next);
      }
    }
    return rotations;
  }

  Set<int> get powered => spinDirections.keys.toSet();

  /// Toggle an optional gear. Illegal moves and edits after victory are inert.
  bool toggle(int cell) {
    if (complete || cell < 0 || cell >= size * size ||
        cell == driver || cell == receiver || fixedGears.contains(cell) ||
        blockers.contains(cell)) {
      return false;
    }
    if (placedGears.contains(cell)) {
      placedGears.remove(cell);
    } else if (remaining > 0) {
      placedGears.add(cell);
    } else {
      return false;
    }
    moves++;
    return true;
  }
}
