import 'dart:math';

typedef _LoopPoint = (int, int);

/// An undirected edge between adjacent vertices on the loop board.
class LoopEdge {
  const LoopEdge(int first, int second)
      : first = first < second ? first : second,
        second = first < second ? second : first;

  final int first;
  final int second;

  static const int vertexCount = LoopLogicPuzzle.size + 1;

  int get id => first * vertexCount + second;
  bool get horizontal => first ~/ vertexCount == second ~/ vertexCount;
  int get row => first ~/ vertexCount;
  int get column => first % vertexCount;

  bool get isValid {
    if (first < 0 ||
        second < 0 ||
        first >= vertexCount * vertexCount ||
        second >= vertexCount * vertexCount) {
      return false;
    }
    final firstRow = first ~/ vertexCount;
    final firstColumn = first % vertexCount;
    final secondRow = second ~/ vertexCount;
    final secondColumn = second % vertexCount;
    return (firstRow == secondRow && (firstColumn - secondColumn).abs() == 1) ||
        (firstColumn == secondColumn && (firstRow - secondRow).abs() == 1);
  }

  @override
  bool operator ==(Object other) =>
      other is LoopEdge && first == other.first && second == other.second;

  @override
  int get hashCode => Object.hash(first, second);
}

/// A Slitherlink-style puzzle on a 4x4 cell board. The generated loop is a
/// single continuous cycle and its edges satisfy every displayed clue.
class LoopLogicPuzzle {
  LoopLogicPuzzle._({
    required this.clues,
    required this.solutionEdges,
  });

  static const int size = 4;
  static const int vertexCount = size + 1;
  static const int totalEdges = size * vertexCount * 2;

  final List<List<int>> clues;
  final Set<LoopEdge> solutionEdges;
  final Set<LoopEdge> selectedEdges = <LoopEdge>{};
  int moves = 0;

  bool get solved => _cluesMatch && _formsSingleLoop;

  bool get _cluesMatch {
    for (var row = 0; row < size; row++) {
      for (var column = 0; column < size; column++) {
        if (_edgesAroundCell(row, column)
                .where(selectedEdges.contains)
                .length !=
            clues[row][column]) {
          return false;
        }
      }
    }
    return true;
  }

  bool get _formsSingleLoop {
    if (selectedEdges.isEmpty) return false;
    final neighbors = <int, List<int>>{};
    for (final edge in selectedEdges) {
      if (!edge.isValid) return false;
      neighbors.putIfAbsent(edge.first, () => <int>[]).add(edge.second);
      neighbors.putIfAbsent(edge.second, () => <int>[]).add(edge.first);
    }
    if (neighbors.values.any((links) => links.length != 2)) return false;

    final visited = <int>{neighbors.keys.first};
    final queue = <int>[visited.first];
    for (var index = 0; index < queue.length; index++) {
      for (final next in neighbors[queue[index]]!) {
        if (visited.add(next)) queue.add(next);
      }
    }
    return visited.length == neighbors.length;
  }

  bool toggleEdge(LoopEdge edge) {
    if (solved || !edge.isValid) return false;
    if (!selectedEdges.add(edge)) selectedEdges.remove(edge);
    moves++;
    return true;
  }

  List<LoopEdge> _edgesAroundCell(int row, int column) => [
        LoopEdge(row * vertexCount + column,
            row * vertexCount + column + 1),
        LoopEdge((row + 1) * vertexCount + column,
            (row + 1) * vertexCount + column + 1),
        LoopEdge(row * vertexCount + column,
            (row + 1) * vertexCount + column),
        LoopEdge(row * vertexCount + column + 1,
            (row + 1) * vertexCount + column + 1),
      ];

  static List<LoopEdge> get allEdges {
    final result = <LoopEdge>[];
    for (var row = 0; row < vertexCount; row++) {
      for (var column = 0; column < size; column++) {
        result.add(LoopEdge(
          row * vertexCount + column,
          row * vertexCount + column + 1,
        ));
      }
    }
    for (var row = 0; row < size; row++) {
      for (var column = 0; column < vertexCount; column++) {
        result.add(LoopEdge(
          row * vertexCount + column,
          (row + 1) * vertexCount + column,
        ));
      }
    }
    return List<LoopEdge>.unmodifiable(result);
  }

  static LoopLogicPuzzle generate({required int seed, int round = 0}) {
    final random = Random(seed ^ (round * 104729) ^ 0x4C4F4F50);
    final polygon = _makePolygon(random, round);
    final route = <LoopEdge>{};

    for (var index = 0; index < polygon.length; index++) {
      var row = polygon[index].$1;
      var column = polygon[index].$2;
      final next = polygon[(index + 1) % polygon.length];
      final rowDelta = next.$1 - row;
      final columnDelta = next.$2 - column;
      final rowStep = rowDelta == 0 ? 0 : rowDelta > 0 ? 1 : -1;
      final columnStep =
          columnDelta == 0 ? 0 : columnDelta > 0 ? 1 : -1;
      while (row != next.$1 || column != next.$2) {
        final nextRow = row + rowStep;
        final nextColumn = column + columnStep;
        route.add(LoopEdge(
          row * vertexCount + column,
          nextRow * vertexCount + nextColumn,
        ));
        row = nextRow;
        column = nextColumn;
      }
    }

    final clues = List<List<int>>.generate(size, (row) =>
        List<int>.generate(size, (column) {
          final top = LoopEdge(row * vertexCount + column,
              row * vertexCount + column + 1);
          final bottom = LoopEdge((row + 1) * vertexCount + column,
              (row + 1) * vertexCount + column + 1);
          final left = LoopEdge(row * vertexCount + column,
              (row + 1) * vertexCount + column);
          final right = LoopEdge(row * vertexCount + column + 1,
              (row + 1) * vertexCount + column + 1);
          return [top, bottom, left, right]
              .where(route.contains)
              .length;
        }));

    return LoopLogicPuzzle._(
      clues: List<List<int>>.unmodifiable(
        clues.map(List<int>.unmodifiable),
      ),
      solutionEdges: Set<LoopEdge>.unmodifiable(route),
    );
  }

  static List<_LoopPoint> _makePolygon(Random random, int round) {
    final templates = <List<_LoopPoint>>[
      [(0, 0), (3, 0), (3, 1), (1, 1), (1, 3), (0, 3)],
      [(0, 0), (3, 0), (3, 1), (2, 1), (2, 3), (1, 3), (1, 1), (0, 1)],
    ];
    final template = templates[(round + random.nextInt(templates.length)) %
        templates.length];
    final turns = random.nextInt(4);
    var rotated = template;
    for (var turn = 0; turn < turns; turn++) {
      rotated = rotated.map((point) => (point.$2, -point.$1)).toList();
    }
    final minRow = rotated.map((point) => point.$1).reduce(min);
    final minColumn = rotated.map((point) => point.$2).reduce(min);
    final normalized = rotated
        .map((point) => (point.$1 - minRow, point.$2 - minColumn))
        .toList();
    final height = normalized.map((point) => point.$1).reduce(max);
    final width = normalized.map((point) => point.$2).reduce(max);
    final rowOffset = random.nextInt(vertexCount - height);
    final columnOffset = random.nextInt(vertexCount - width);

    return normalized
        .map((point) => (point.$1 + rowOffset, point.$2 + columnOffset))
        .toList(growable: false);
  }
}

class LoopLogicSession {
  LoopLogicSession({required this.seed}) {
    puzzle = LoopLogicPuzzle.generate(seed: seed, round: round);
  }

  static const int totalRounds = 3;
  final int seed;
  int round = 0;
  int _movesAcrossRounds = 0;
  late LoopLogicPuzzle puzzle;

  bool get complete => round >= totalRounds;
  bool get roundComplete => !complete && puzzle.solved;
  int get totalMoves => _movesAcrossRounds + (complete ? 0 : puzzle.moves);

  bool toggle(LoopEdge edge) {
    if (complete || roundComplete) return false;
    return puzzle.toggleEdge(edge);
  }

  bool advance() {
    if (!roundComplete) return false;
    _movesAcrossRounds += puzzle.moves;
    round++;
    if (!complete) {
      puzzle = LoopLogicPuzzle.generate(seed: seed, round: round);
    }
    return true;
  }
}
