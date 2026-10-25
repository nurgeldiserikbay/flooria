import 'dart:math';

enum BeadColor { coral, mint, sky, lilac }

class BeadMove {
  const BeadMove(this.from, this.to);
  final int from;
  final int to;

  @override
  bool operator ==(Object other) =>
      other is BeadMove && from == other.from && to == other.to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'BeadMove($from, $to)';
}

/// A tube-sorting puzzle. Every generated state is scrambled from a solved
/// board, and [solutionMoves] records the valid reverse route back to solved.
class BeadSortPuzzle {
  BeadSortPuzzle._({
    required this.tubes,
    required this.solutionMoves,
  });

  static const int capacity = 3;
  static const int colorCount = 4;
  static const int tubeCount = 6;

  final List<List<BeadColor>> tubes;
  final List<BeadMove> solutionMoves;
  int moves = 0;

  bool get solved => tubes.every(
        (tube) =>
            tube.isEmpty ||
            (tube.length == capacity &&
                tube.every((bead) => bead == tube.first)),
      );

  bool canMove(int from, int to) {
    if (from < 0 ||
        from >= tubeCount ||
        to < 0 ||
        to >= tubeCount ||
        from == to) {
      return false;
    }
    final source = tubes[from];
    final destination = tubes[to];
    if (source.isEmpty || destination.length >= capacity) return false;
    return destination.isEmpty || destination.last == source.last;
  }

  bool move(int from, int to) {
    if (solved || !canMove(from, to)) return false;
    tubes[to].add(tubes[from].removeLast());
    moves++;
    return true;
  }

  static BeadSortPuzzle generate({
    required int seed,
    int round = 0,
    int floor = 1,
  }) {
    final random = Random(seed ^ (round * 104729) ^ (floor * 7919));
    final tubes = List<List<BeadColor>>.generate(
      tubeCount,
      (index) => index < colorCount
          ? List<BeadColor>.filled( capacity, BeadColor.values[index])
          : <BeadColor>[],
    );
    final scramble = <BeadMove>[];
    final scrambleLength = 10 + round * 6 + (floor ~/ 8).clamp(0, 5);

    for (var step = 0; step < scrambleLength; step++) {
      final legal = <BeadMove>[];
      for (var from = 0; from < tubeCount; from++) {
        for (var to = 0; to < tubeCount; to++) {
          if (from == to || tubes[from].isEmpty || tubes[to].length >= capacity) {
            continue;
          }
          if (tubes[to].isEmpty || tubes[to].last == tubes[from].last) {
            if (scramble.isNotEmpty &&
                from == scramble.last.to &&
                to == scramble.last.from) {
              continue;
            }
            legal.add(BeadMove(from, to));
          }
        }
      }
      if (legal.isEmpty) break;
      final move = legal[random.nextInt(legal.length)];
      tubes[move.to].add(tubes[move.from].removeLast());
      scramble.add(move);
      final returnedToSolved = tubes.every((tube) =>
          tube.isEmpty ||
          (tube.length == capacity && tube.every((bead) => bead == tube.first)));
      if (returnedToSolved) {
        for (var index = 0; index < tubeCount; index++) {
          tubes[index]
            ..clear()
            ..addAll(index < colorCount
                ? List<BeadColor>.filled(capacity, BeadColor.values[index])
                : <BeadColor>[]);
        }
        scramble.clear();
        break;
      }
    }

    if (tubes.every((tube) =>
        tube.isEmpty ||
        (tube.length == capacity && tube.every((bead) => bead == tube.first)))) {
      final bead = tubes[0].removeLast();
      tubes[4].add(bead);
      scramble.add(const BeadMove(0, 4));
    }

    final solution = scramble.reversed
        .map((move) => BeadMove(move.to, move.from))
        .toList(growable: false);
    return BeadSortPuzzle._(
      tubes: tubes.map((tube) => List<BeadColor>.of(tube)).toList(),
      solutionMoves: List<BeadMove>.unmodifiable(solution),
    );
  }
}

class BeadSortSession {
  BeadSortSession({required this.seed, this.floor = 1}) {
    puzzle = BeadSortPuzzle.generate(seed: seed, floor: floor, round: round);
  }

  static const int totalRounds = 3;
  final int seed;
  final int floor;
  int round = 0;
  late BeadSortPuzzle puzzle;

  bool get complete => round >= totalRounds;
  bool get roundComplete => !complete && puzzle.solved;
  int get totalMoves => _movesAcrossRounds + puzzle.moves;

  int _movesAcrossRounds = 0;

  bool move(int from, int to) {
    if (complete || roundComplete) return false;
    return puzzle.move(from, to);
  }

  bool advance() {
    if (!roundComplete) return false;
    _movesAcrossRounds += puzzle.moves;
    round++;
    if (!complete) {
      puzzle = BeadSortPuzzle.generate(seed: seed, floor: floor, round: round);
    }
    return true;
  }
}
