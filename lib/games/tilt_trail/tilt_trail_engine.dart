import 'dart:math';

/// Direction used to tilt the board.
enum TiltDirection { up, right, down, left }

/// A zero-based board coordinate.
class TiltCell {
  const TiltCell(this.row, this.column);

  final int row;
  final int column;

  @override
  bool operator ==(Object other) =>
      other is TiltCell && row == other.row && column == other.column;

  @override
  int get hashCode => Object.hash(row, column);
}

/// A seeded sliding puzzle. The marble travels until it reaches a wall or edge.
class TiltPuzzle {
  TiltPuzzle._({
    required this.start,
    required this.goal,
    required this.walls,
    required this.solution,
  }) : position = start;

  static const int size = 5;

  final TiltCell start;
  final TiltCell goal;
  final Set<TiltCell> walls;

  /// A known solution generated alongside the board.
  final List<TiltDirection> solution;

  TiltCell position;
  int moves = 0;

  bool get solved => position == goal;

  /// Slide the marble in one direction. A blocked tilt is ignored.
  bool tilt(TiltDirection direction) {
    if (solved) return false;
    final destination = _slideFrom(position, direction, walls);
    if (destination == null) return false;
    position = destination;
    moves++;
    return true;
  }

  static TiltPuzzle generate({required int seed, int round = 0}) {
    final random = Random((seed * 65537 + round * 104729) & 0x7fffffff);

    for (var attempt = 0; attempt < 240; attempt++) {
      final start = TiltCell(1 + random.nextInt(3), 1 + random.nextInt(3));
      final corners = <TiltCell>[
        const TiltCell(0, 0),
        const TiltCell(0, size - 1),
        const TiltCell(size - 1, 0),
        const TiltCell(size - 1, size - 1),
      ];
      final goal = corners[random.nextInt(corners.length)];
      final walls = <TiltCell>{};

      for (var row = 0; row < size; row++) {
        for (var column = 0; column < size; column++) {
          final cell = TiltCell(row, column);
          if (cell == start || cell == goal) continue;
          if (random.nextDouble() < .19) walls.add(cell);
        }
      }

      final solution = _findSolution(start, goal, walls);
      if (solution != null && solution.length >= 3 && solution.length <= 9) {
        return TiltPuzzle._(
          start: start,
          goal: goal,
          walls: walls,
          solution: solution,
        );
      }
    }

    // Deterministic fallback route: right, down, right, down.
    return TiltPuzzle._(
      start: const TiltCell(1, 1),
      goal: const TiltCell(size - 1, size - 1),
      walls: const {
        TiltCell(1, 3),
        TiltCell(4, 2),
      },
      solution: const [
        TiltDirection.right,
        TiltDirection.down,
        TiltDirection.right,
        TiltDirection.down,
      ],
    );
  }

  static List<TiltDirection>? _findSolution(
    TiltCell start,
    TiltCell goal,
    Set<TiltCell> walls,
  ) {
    final paths = <TiltCell, List<TiltDirection>>{start: const []};
    final queue = <TiltCell>[start];
    var readIndex = 0;

    while (readIndex < queue.length) {
      final current = queue[readIndex++];
      final path = paths[current]!;
      for (final direction in TiltDirection.values) {
        final next = _slideFrom(current, direction, walls);
        if (next == null || paths.containsKey(next)) continue;
        final nextPath = [...path, direction];
        if (next == goal) return nextPath;
        paths[next] = nextPath;
        queue.add(next);
      }
    }
    return null;
  }

  static TiltCell? _slideFrom(
    TiltCell from,
    TiltDirection direction,
    Set<TiltCell> walls,
  ) {
    var row = from.row;
    var column = from.column;
    while (true) {
      switch (direction) {
        case TiltDirection.up:
          row--;
          break;
        case TiltDirection.right:
          column++;
          break;
        case TiltDirection.down:
          row++;
          break;
        case TiltDirection.left:
          column--;
          break;
      }

      if (row < 0 || row >= size || column < 0 || column >= size) {
        break;
      }
      if (walls.contains(TiltCell(row, column))) break;
    }

    final destination = TiltCell(
      row - _rowDelta(direction),
      column - _columnDelta(direction),
    );
    return destination == from ? null : destination;
  }

  static int _rowDelta(TiltDirection direction) {
    switch (direction) {
      case TiltDirection.up:
        return -1;
      case TiltDirection.right:
      case TiltDirection.left:
        return 0;
      case TiltDirection.down:
        return 1;
    }
  }

  static int _columnDelta(TiltDirection direction) {
    switch (direction) {
      case TiltDirection.up:
      case TiltDirection.down:
        return 0;
      case TiltDirection.right:
        return 1;
      case TiltDirection.left:
        return -1;
    }
  }
}

/// Three short seeded boards make a complete Tilt Trail session.
class TiltTrailSession {
  TiltTrailSession({required this.seed})
      : puzzle = TiltPuzzle.generate(seed: seed, round: 0);

  final int seed;
  static const int totalRounds = 3;

  int round = 0;
  int moves = 0;
  late TiltPuzzle puzzle;

  bool get complete => round >= totalRounds;
  bool get roundComplete => !complete && puzzle.solved;

  bool tilt(TiltDirection direction) {
    if (complete || roundComplete) return false;
    if (!puzzle.tilt(direction)) return false;
    moves++;
    return true;
  }

  bool advance() {
    if (!roundComplete) return false;
    round++;
    if (!complete) {
      puzzle = TiltPuzzle.generate(seed: seed, round: round);
    }
    return true;
  }
}
