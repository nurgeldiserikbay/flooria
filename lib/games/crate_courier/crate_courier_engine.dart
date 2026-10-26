import 'dart:math';

enum CourierDirection { up, right, down, left }

extension CourierDirectionMovement on CourierDirection {
  BoardPoint get offset => switch (this) {
        CourierDirection.up => const BoardPoint(-1, 0),
        CourierDirection.right => const BoardPoint(0, 1),
        CourierDirection.down => const BoardPoint(1, 0),
        CourierDirection.left => const BoardPoint(0, -1),
      };
}

enum CourierMoveResult { blocked, moved, pushed, solved }

class BoardPoint {
  const BoardPoint(this.row, this.col);

  final int row;
  final int col;

  BoardPoint operator +(BoardPoint other) =>
      BoardPoint(row + other.row, col + other.col);

  @override
  bool operator ==(Object other) =>
      other is BoardPoint && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row,$col)';
}

class CrateBoard {
  CrateBoard({
    required this.size,
    required this.playerStart,
    required List<BoardPoint> crateStarts,
    required Set<BoardPoint> targets,
    required Set<BoardPoint> walls,
  })  : _player = playerStart,
        _crates = List<BoardPoint>.of(crateStarts),
        targets = Set<BoardPoint>.unmodifiable(targets),
        walls = Set<BoardPoint>.unmodifiable(walls);

  final int size;
  final BoardPoint playerStart;
  final Set<BoardPoint> targets;
  final Set<BoardPoint> walls;
  BoardPoint _player;
  final List<BoardPoint> _crates;
  int _moves = 0;
  int _pushes = 0;

  BoardPoint get player => _player;
  List<BoardPoint> get crates => List<BoardPoint>.unmodifiable(_crates);
  int get moves => _moves;
  int get pushes => _pushes;
  bool get solved => _crates.every(targets.contains);

  CourierMoveResult move(CourierDirection direction) {
    if (solved) return CourierMoveResult.blocked;
    final next = _player + direction.offset;
    if (_isBlocked(next)) return CourierMoveResult.blocked;

    final crateIndex = _crates.indexOf(next);
    if (crateIndex >= 0) {
      final beyond = next + direction.offset;
      if (_isBlocked(beyond) || _crates.contains(beyond)) {
        return CourierMoveResult.blocked;
      }
      _crates[crateIndex] = beyond;
      _player = next;
      _moves++;
      _pushes++;
      return solved ? CourierMoveResult.solved : CourierMoveResult.pushed;
    }

    _player = next;
    _moves++;
    return CourierMoveResult.moved;
  }

  bool _isBlocked(BoardPoint point) =>
      point.row <= 0 ||
      point.col <= 0 ||
      point.row >= size - 1 ||
      point.col >= size - 1 ||
      walls.contains(point);
}

class CrateCourierRound {
  const CrateCourierRound({
    required this.board,
    required this.solutionPar,
  });

  final CrateBoard board;
  final int solutionPar;
}

/// Seeded Sokoban-style puzzle session. Each target set is captured from a
/// legal scramble walk, so every board has a known route to completion.
class CrateCourierSession {
  CrateCourierSession({required this.seed, int level = 1}) {
    final random = Random(seed);
    final clampedLevel = level.clamp(1, 20).toInt();
    final crateCount = clampedLevel < 5 ? 1 : (clampedLevel < 12 ? 2 : 3);
    rounds = List<CrateCourierRound>.unmodifiable(
      List.generate(
        roundCount,
        (_) => _generateRound(random, clampedLevel, crateCount),
      ),
    );
  }

  static const int roundCount = 3;
  static const int passScore = 3;
  static const int boardSize = 7;

  final int seed;
  late final List<CrateCourierRound> rounds;
  int roundIndex = 0;

  CrateBoard get currentBoard =>
      rounds[roundIndex.clamp(0, roundCount - 1).toInt()].board;
  bool get finished => roundIndex >= roundCount;
  bool get passed => finished && solvedCount >= passScore;
  int get solvedCount => rounds.where((round) => round.board.solved).length;
  double get progress => finished ? 1 : roundIndex / roundCount;
  int get totalMoves =>
      rounds.fold(0, (sum, round) => sum + round.board.moves);
  int get totalPushes =>
      rounds.fold(0, (sum, round) => sum + round.board.pushes);

  bool advanceRound() {
    if (finished || !currentBoard.solved) return false;
    roundIndex++;
    return true;
  }

  static CrateCourierRound _generateRound(
    Random random,
    int level,
    int crateCount,
  ) {
    const size = boardSize;
    final starts = <BoardPoint>[
      const BoardPoint(2, 2),
      const BoardPoint(2, 4),
      const BoardPoint(4, 2),
    ].take(crateCount).toList();
    const playerStart = BoardPoint(5, 4);
    final minimumPushes = crateCount + (level >= 8 ? 3 : 1);
    CrateCourierRound? fallback;

    for (var attempt = 0; attempt < 200; attempt++) {
      var player = playerStart;
      final crates = List<BoardPoint>.of(starts);
      final movedCrates = <int>{};
      var pushes = 0;
      final walkLength = 24 + level * 3;

      for (var step = 0; step < walkLength; step++) {
        final legal = CourierDirection.values.where((direction) {
          final next = player + direction.offset;
          if (_isWall(next, size)) return false;
          final crateIndex = crates.indexOf(next);
          if (crateIndex < 0) return true;
          final beyond = next + direction.offset;
          return !_isWall(beyond, size) && !crates.contains(beyond);
        }).toList()
          ..shuffle(random);
        if (legal.isEmpty) continue;

        final direction = legal.first;
        final next = player + direction.offset;
        final crateIndex = crates.indexOf(next);
        if (crateIndex >= 0) {
          crates[crateIndex] = next + direction.offset;
          movedCrates.add(crateIndex);
          pushes++;
        }
        player = next;
      }

      if (pushes < minimumPushes || _samePositions(starts, crates)) continue;
      final board = CrateBoard(
        size: size,
        playerStart: playerStart,
        crateStarts: starts,
        targets: crates.toSet(),
        walls: const {},
      );
      final candidate = CrateCourierRound(board: board, solutionPar: pushes);
      fallback ??= candidate;
      if (movedCrates.length == crateCount) return candidate;
    }

    if (fallback != null) return fallback;
    // A deterministic fallback keeps generation total even for unusual seeds.
    final targets = starts
        .map((point) => BoardPoint(point.row, point.col + 1))
        .toSet();
    return CrateCourierRound(
      board: CrateBoard(
        size: size,
        playerStart: playerStart,
        crateStarts: starts,
        targets: targets,
        walls: const {},
      ),
      solutionPar: crateCount,
    );
  }

  static bool _samePositions(List<BoardPoint> a, List<BoardPoint> b) {
    if (a.length != b.length) return false;
    return a.toSet().containsAll(b) && b.toSet().containsAll(a);
  }

  static bool _isWall(BoardPoint point, int size) =>
      point.row <= 0 ||
      point.col <= 0 ||
      point.row >= size - 1 ||
      point.col >= size - 1;
}
