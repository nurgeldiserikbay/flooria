import 'dart:collection';
import 'dart:math';

/// Link bits of one tile, clockwise from north.
abstract final class Links {
  static const north = 1;
  static const east = 2;
  static const south = 4;
  static const west = 8;
  static const directions = [north, east, south, west];

  static int opposite(int direction) => switch (direction) {
    north => south,
    east => west,
    south => north,
    _ => east,
  };

  /// Rotates a link mask clockwise by [turns] quarter turns.
  static int rotate(int mask, int turns) {
    var result = mask & 15;
    for (var i = 0; i < turns % 4; i++) {
      result = ((result << 1) & 15) | (result >> 3);
    }
    return result;
  }

  static int degree(int mask) =>
      directions.where((direction) => mask & direction != 0).length;
}

enum SynapseTapResult { ignored, rotated, completed }

/// Rotate tiles until every link meets a matching link and the whole network
/// reaches the source. Boards are random spanning trees, so each one has a
/// solution; any arrangement that satisfies the rules is accepted.
class SynapseLinkEngine {
  SynapseLinkEngine._({
    required this.level,
    required this.columns,
    required this.rows,
    required this.source,
    required List<int> solution,
    required List<int> rotations,
  })  : solution = List<int>.unmodifiable(solution),
        _rotations = rotations,
        _locked = List<bool>.filled(solution.length, false) {
    _par = _computePar();
  }

  final int level;
  final int columns;
  final int rows;
  final int source;

  /// Link masks of the generated network in solved orientation.
  final List<int> solution;
  final List<int> _rotations;
  final List<bool> _locked;
  late final int _par;
  int moves = 0;
  bool _completed = false;

  int get cellCount => columns * rows;
  bool get isCompleted => _completed;

  /// Clockwise taps needed to restore the generated layout.
  int get par => _par;

  int rotationAt(int index) => _rotations[index];
  int maskAt(int index) => Links.rotate(solution[index], _rotations[index]);
  bool isLocked(int index) => _locked[index];
  bool isLeaf(int index) => Links.degree(solution[index]) == 1;

  int get stars => moves <= par ? 3 : moves <= (par * 1.5).ceil() ? 2 : 1;
  int get score => max(100, 1000 - max(0, moves - par) * 25).toInt();
  int get logicMetric => (100 - max(0, moves - par) * 4).clamp(30, 100).toInt();

  static (int, int) sizeForLevel(int level) {
    if (level <= 2) return (3, 3);
    if (level <= 5) return (3, 4);
    if (level <= 12) return (4, 4);
    if (level <= 24) return (4, 5);
    if (level <= 39) return (5, 5);
    if (level <= 59) return (5, 6);
    if (level <= 79) return (6, 6);
    return (6, 7);
  }

  factory SynapseLinkEngine.forLevel(int level, {int? seed}) {
    final safeLevel = max(1, level).toInt();
    final (columns, rows) = sizeForLevel(safeLevel);
    final random = Random(seed ?? safeLevel * 7907 + 11);
    final count = columns * rows;
    final source = (rows ~/ 2) * columns + (columns - 1) ~/ 2;
    final solution = _spanningTree(columns, rows, source, random);

    // Scramble every tile, but keep the board from starting solved.
    final rotations = List<int>.generate(count, (_) => random.nextInt(4));
    final engine = SynapseLinkEngine._(
      level: safeLevel,
      columns: columns,
      rows: rows,
      source: source,
      solution: solution,
      rotations: rotations,
    );
    final turnable = [
      for (var i = 0; i < count; i++)
        if (Links.rotate(solution[i], 1) != solution[i]) i,
    ];
    var misplaced = [
      for (final i in turnable)
        if (engine.maskAt(i) != solution[i]) i,
    ].length;
    final wanted = max(2, (turnable.length * .6).ceil());
    for (final i in turnable) {
      if (misplaced >= wanted && !engine._satisfied()) break;
      if (engine.maskAt(i) == solution[i]) {
        rotations[i] = (rotations[i] + 1) % 4;
        misplaced++;
      }
    }
    return SynapseLinkEngine._(
      level: safeLevel,
      columns: columns,
      rows: rows,
      source: source,
      solution: solution,
      rotations: rotations,
    );
  }

  /// Randomised Prim growth from the source. Branch-heavy trees make better
  /// puzzles than long corridors from a depth-first walk.
  static List<int> _spanningTree(int columns, int rows, int source,
      Random random) {
    final masks = List<int>.filled(columns * rows, 0);
    final visited = <int>{source};
    final frontier = <(int, int, int)>[];

    void addEdges(int cell) {
      final row = cell ~/ columns;
      final column = cell % columns;
      for (final direction in Links.directions) {
        final next = _neighbour(row, column, direction, columns, rows);
        if (next != null && !visited.contains(next)) {
          frontier.add((cell, next, direction));
        }
      }
    }

    addEdges(source);
    while (visited.length < masks.length) {
      final pick = frontier.removeAt(random.nextInt(frontier.length));
      final (from, to, direction) = pick;
      if (visited.contains(to)) continue;
      // Crossroads carry no decision, so avoid them where possible.
      if (Links.degree(masks[from]) >= 3 &&
          frontier.any((edge) => !visited.contains(edge.$2) &&
              Links.degree(masks[edge.$1]) < 3)) {
        frontier.add(pick);
        continue;
      }
      masks[from] |= direction;
      masks[to] |= Links.opposite(direction);
      visited.add(to);
      addEdges(to);
    }
    return masks;
  }

  static int? _neighbour(int row, int column, int direction, int columns,
      int rows) {
    switch (direction) {
      case Links.north:
        return row > 0 ? (row - 1) * columns + column : null;
      case Links.east:
        return column < columns - 1 ? row * columns + column + 1 : null;
      case Links.south:
        return row < rows - 1 ? (row + 1) * columns + column : null;
      default:
        return column > 0 ? row * columns + column - 1 : null;
    }
  }

  int? neighbour(int index, int direction) =>
      _neighbour(index ~/ columns, index % columns, direction, columns, rows);

  int _computePar() {
    var total = 0;
    for (var i = 0; i < cellCount; i++) {
      for (var turns = 0; turns < 4; turns++) {
        if (Links.rotate(maskAt(i), turns) == solution[i]) {
          total += turns;
          break;
        }
      }
    }
    return total;
  }

  /// True when a link from [index] in [direction] meets a returning link.
  bool isMatched(int index, int direction) {
    if (maskAt(index) & direction == 0) return false;
    final next = neighbour(index, direction);
    return next != null && maskAt(next) & Links.opposite(direction) != 0;
  }

  /// Cells reached from the source through matched links.
  Set<int> get litCells {
    final lit = <int>{source};
    final queue = Queue<int>()..add(source);
    while (queue.isNotEmpty) {
      final cell = queue.removeFirst();
      for (final direction in Links.directions) {
        if (!isMatched(cell, direction)) continue;
        final next = neighbour(cell, direction)!;
        if (lit.add(next)) queue.add(next);
      }
    }
    return lit;
  }

  bool _satisfied() {
    for (var i = 0; i < cellCount; i++) {
      for (final direction in Links.directions) {
        if (maskAt(i) & direction != 0 && !isMatched(i, direction)) {
          return false;
        }
      }
    }
    return litCells.length == cellCount;
  }

  SynapseTapResult rotate(int index) {
    if (_completed || index < 0 || index >= cellCount || _locked[index]) {
      return SynapseTapResult.ignored;
    }
    _rotations[index] = (_rotations[index] + 1) % 4;
    moves++;
    if (_satisfied()) {
      _completed = true;
      return SynapseTapResult.completed;
    }
    return SynapseTapResult.rotated;
  }

  /// Pins a tile the player is sure about. Locked tiles ignore taps.
  bool toggleLock(int index) {
    if (_completed || index < 0 || index >= cellCount) return false;
    _locked[index] = !_locked[index];
    return true;
  }
}
