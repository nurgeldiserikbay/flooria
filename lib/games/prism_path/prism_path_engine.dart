import 'dart:math';

/// Direction in which the light ray is travelling.
enum BeamDirection { up, right, down, left }

/// A mirror reflects a ray by 90 degrees.
enum MirrorFace { slash, backslash }

/// A grid coordinate. The engine uses zero-based rows and columns.
class PrismCell {
  const PrismCell(this.row, this.column);

  final int row;
  final int column;

  int get index => row * PrismPuzzle.size + column;

  @override
  bool operator ==(Object other) =>
      other is PrismCell && row == other.row && column == other.column;

  @override
  int get hashCode => Object.hash(row, column);
}

/// One rotatable mirror in a generated board.
class PrismMirror {
  PrismMirror({
    required this.cell,
    required this.requiredFace,
    required this.face,
    this.isDecoy = false,
  });

  final PrismCell cell;
  final MirrorFace requiredFace;
  final bool isDecoy;
  MirrorFace face;

  void rotate() {
    face = face == MirrorFace.slash
        ? MirrorFace.backslash
        : MirrorFace.slash;
  }

  BeamDirection reflect(BeamDirection direction) {
    switch (face) {
      case MirrorFace.slash:
        switch (direction) {
          case BeamDirection.right:
            return BeamDirection.up;
          case BeamDirection.up:
            return BeamDirection.right;
          case BeamDirection.down:
            return BeamDirection.left;
          case BeamDirection.left:
            return BeamDirection.down;
        }
      case MirrorFace.backslash:
        switch (direction) {
          case BeamDirection.right:
            return BeamDirection.down;
          case BeamDirection.down:
            return BeamDirection.right;
          case BeamDirection.up:
            return BeamDirection.left;
          case BeamDirection.left:
            return BeamDirection.up;
        }
    }
  }
}

/// A small reflection puzzle. Every generated board has a guaranteed route:
/// the ray travels right, turns down, then turns left into the goal.
class PrismPuzzle {
  PrismPuzzle._({
    required this.source,
    required this.goal,
    required this.mirrors,
  });

  static const int size = 5;

  final PrismCell source;
  final PrismCell goal;
  final List<PrismMirror> mirrors;

  PrismMirror? mirrorAt(PrismCell cell) {
    for (final mirror in mirrors) {
      if (mirror.cell == cell) return mirror;
    }
    return null;
  }

  /// The ray's visited cells, including source. A repeated direction at a
  /// cell means the ray is looping and has no solution in its current state.
  Set<PrismCell> get beamCells {
    final cells = <PrismCell>{source};
    final visitedStates = <int>{};
    var row = source.row;
    var column = source.column;
    var direction = BeamDirection.right;

    for (var step = 0; step < size * size * 4; step++) {
      if (row == goal.row && column == goal.column) return cells;
      final state = ((row * size + column) * 4) + direction.index;
      if (!visitedStates.add(state)) return cells;

      final mirror = mirrorAt(PrismCell(row, column));
      if (mirror != null) direction = mirror.reflect(direction);

      switch (direction) {
        case BeamDirection.up:
          row--;
        case BeamDirection.right:
          column++;
        case BeamDirection.down:
          row++;
        case BeamDirection.left:
          column--;
      }
      if (!_inside(row, column)) return cells;
      cells.add(PrismCell(row, column));
    }
    return cells;
  }

  bool get solved => beamCells.contains(goal);

  bool rotateAt(PrismCell cell) {
    final mirror = mirrorAt(cell);
    if (mirror == null || solved) return false;
    mirror.rotate();
    return true;
  }

  static PrismPuzzle generate({required int seed, int round = 0}) {
    final random = Random((seed * 7919 + round * 104729) & 0x7fffffff);
    final sourceRow = random.nextInt(2);
    final goalRow = 3 + random.nextInt(2);
    final turnColumn = 2 + random.nextInt(2);
    final firstCell = PrismCell(sourceRow, turnColumn);
    final secondCell = PrismCell(goalRow, turnColumn);
    const firstFace = MirrorFace.backslash;
    const secondFace = MirrorFace.slash;

    final mirrors = <PrismMirror>[
      PrismMirror(
        cell: firstCell,
        requiredFace: firstFace,
        face: MirrorFace.slash,
      ),
      PrismMirror(
        cell: secondCell,
        requiredFace: secondFace,
        face: MirrorFace.backslash,
      ),
      // Decoys sit beyond the intended turning column.
      PrismMirror(
        cell: PrismCell(sourceRow, size - 1),
        requiredFace: MirrorFace.backslash,
        face: random.nextBool() ? MirrorFace.slash : MirrorFace.backslash,
        isDecoy: true,
      ),
      PrismMirror(
        cell: PrismCell(goalRow, size - 1),
        requiredFace: MirrorFace.slash,
        face: random.nextBool() ? MirrorFace.slash : MirrorFace.backslash,
        isDecoy: true,
      ),
    ];

    return PrismPuzzle._(
      source: PrismCell(sourceRow, 0),
      goal: PrismCell(goalRow, 0),
      mirrors: mirrors,
    );
  }

  static bool _inside(int row, int column) =>
      row >= 0 && row < size && column >= 0 && column < size;
}

/// Three seeded boards form one short session. Invalid moves never change the
/// board; a round can advance only after the light reaches its crystal.
class PrismPathSession {
  PrismPathSession({required this.seed});

  final int seed;
  static const int totalRounds = 3;

  int round = 0;
  int moves = 0;
  int mistakes = 0;
  late PrismPuzzle puzzle = PrismPuzzle.generate(seed: seed, round: round);

  bool get complete => round >= totalRounds;
  bool get roundComplete => !complete && puzzle.solved;

  bool rotate(int row, int column) {
    if (complete || roundComplete) return false;
    final cell = PrismCell(row, column);
    final mirror = puzzle.mirrorAt(cell);
    if (mirror == null || !puzzle.rotateAt(cell)) return false;
    moves++;
    if (mirror.isDecoy || mirror.face != mirror.requiredFace) mistakes++;
    return true;
  }

  bool advance() {
    if (!roundComplete) return false;
    round++;
    if (!complete) {
      puzzle = PrismPuzzle.generate(seed: seed, round: round);
    }
    return true;
  }
}
