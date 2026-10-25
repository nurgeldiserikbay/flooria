import 'dart:math';

typedef ShapeCell = (int, int);

class ShapeShiftPuzzle {
  const ShapeShiftPuzzle({
    required this.target,
    required this.options,
    required this.answerIndex,
  });

  /// Normalized row/column coordinates, suitable for drawing on a small grid.
  final List<ShapeCell> target;
  final List<List<ShapeCell>> options;
  final int answerIndex;
}

/// A seeded mental-rotation game. Exactly one option is a rotation of the
/// target silhouette; all other choices have a different cell layout.
class ShapeShiftSession {
  ShapeShiftSession({required this.seed, this.roundCount = 3})
      : assert(roundCount > 0) {
    _loadPuzzle();
  }

  final int seed;
  final int roundCount;
  int round = 0;
  int mistakes = 0;
  int _revision = 0;
  bool finished = false;
  late ShapeShiftPuzzle puzzle;

  double get progress => round / roundCount;

  bool choose(int index) {
    if (finished || index < 0 || index >= puzzle.options.length) return false;
    if (index != puzzle.answerIndex) {
      mistakes++;
      return false;
    }
    round++;
    finished = round >= roundCount;
    if (!finished) _loadPuzzle();
    return true;
  }

  void _loadPuzzle() {
    puzzle = generatePuzzle(seed: seed, round: round, revision: _revision++);
  }

  static ShapeShiftPuzzle generatePuzzle({
    required int seed,
    required int round,
    int revision = 0,
  }) {
    final random = Random(seed ^ (round * 0x27d4eb2d) ^ (revision * 0x165667b1));
    final baseShapes = <List<ShapeCell>>[
      [(0, 0), (1, 0), (2, 0), (2, 1), (2, 2)],
      [(0, 0), (0, 1), (1, 1), (2, 1), (2, 2)],
      [(0, 0), (1, 0), (1, 1), (1, 2), (2, 2), (2, 3)],
      [(0, 1), (1, 1), (2, 0), (2, 1), (2, 2), (3, 2)],
      [(0, 0), (1, 0), (1, 1), (2, 1), (2, 2), (3, 2)],
    ];
    final target = _normalize(baseShapes[random.nextInt(baseShapes.length)]);
    final rotation = 1 + random.nextInt(3);
    final correct = _rotate(target, rotation);
    final options = <List<ShapeCell>>[correct];
    while (options.length < 3) {
      final candidate = _makeDistractor(target, random);
      if (!options.any((existing) => _sameShape(existing, candidate)) &&
          !_isRotationOf(target, candidate)) {
        options.add(candidate);
      }
    }
    options.shuffle(random);
    return ShapeShiftPuzzle(
      target: List.unmodifiable(target),
      options: List.unmodifiable(options.map(List<ShapeCell>.unmodifiable)),
      answerIndex: options.indexWhere((option) => _sameShape(option, correct)),
    );
  }

  static List<ShapeCell> _makeDistractor(List<ShapeCell> target, Random random) {
    final changed = List<ShapeCell>.of(target);
    final removed = changed.removeAt(random.nextInt(changed.length));
    var row = removed.$1;
    var column = removed.$2;
    for (var attempts = 0; attempts < 12; attempts++) {
      row = random.nextInt(5);
      column = random.nextInt(5);
      if (!changed.contains((row, column))) break;
    }
    changed.add((row, column));
    return _normalize(changed);
  }

  static List<ShapeCell> _rotate(List<ShapeCell> shape, int quarterTurns) {
    var result = shape;
    for (var turn = 0; turn < quarterTurns; turn++) {
      result = _normalize(result.map((cell) => (cell.$2, -cell.$1)).toList());
    }
    return result;
  }

  static List<ShapeCell> _normalize(List<ShapeCell> shape) {
    final minRow = shape.map((cell) => cell.$1).reduce(min);
    final minColumn = shape.map((cell) => cell.$2).reduce(min);
    final result = shape
        .map((cell) => (cell.$1 - minRow, cell.$2 - minColumn))
        .toList()
      ..sort((a, b) => a.$1 != b.$1
          ? a.$1.compareTo(b.$1)
          : a.$2.compareTo(b.$2));
    return result;
  }

  static bool _sameShape(List<ShapeCell> a, List<ShapeCell> b) {
    if (a.length != b.length) return false;
    final left = _normalize(a);
    final right = _normalize(b);
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }

  static bool _isRotationOf(List<ShapeCell> shape, List<ShapeCell> candidate) {
    var rotated = shape;
    for (var turn = 0; turn < 4; turn++) {
      if (_sameShape(rotated, candidate)) return true;
      rotated = _rotate(rotated, 1);
    }
    return false;
  }
}
