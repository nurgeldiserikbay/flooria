import 'dart:math';

/// A grid cell of a polyomino as (row, column).
typedef Cell = (int, int);

/// Shape helpers. Shapes are normalised so their top-left bound is (0, 0).
abstract final class Shapes {
  static List<Cell> normalise(Iterable<Cell> cells) {
    final list = cells.toList();
    final minRow = list.map((c) => c.$1).reduce(min);
    final minColumn = list.map((c) => c.$2).reduce(min);
    return [for (final c in list) (c.$1 - minRow, c.$2 - minColumn)]
      ..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
  }

  /// Rotates a shape clockwise by [turns] quarter turns.
  static List<Cell> rotate(List<Cell> shape, int turns) {
    var cells = shape;
    for (var i = 0; i < turns % 4; i++) {
      cells = normalise([for (final c in cells) (c.$2, -c.$1)]);
    }
    return normalise(cells);
  }

  static List<Cell> mirror(List<Cell> shape) =>
      normalise([for (final c in shape) (c.$1, -c.$2)]);

  static String key(List<Cell> shape) =>
      normalise(shape).map((c) => '${c.$1}.${c.$2}').join('|');

  /// The same key for every rotation of a shape.
  static String rotationClass(List<Cell> shape) =>
      ([for (var t = 0; t < 4; t++) key(rotate(shape, t))]..sort()).first;

  static bool isChiral(List<Cell> shape) =>
      rotationClass(shape) != rotationClass(mirror(shape));

  static bool isConnected(List<Cell> shape) {
    final cells = shape.toSet();
    final seen = <Cell>{shape.first};
    final stack = [shape.first];
    while (stack.isNotEmpty) {
      final (r, c) = stack.removeLast();
      for (final next in [(r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)]) {
        if (cells.contains(next) && seen.add(next)) stack.add(next);
      }
    }
    return seen.length == cells.length;
  }

  static List<Cell> grow(int size, Random random) {
    final cells = <Cell>{(0, 0)};
    while (cells.length < size) {
      final from = cells.elementAt(random.nextInt(cells.length));
      const steps = [(-1, 0), (1, 0), (0, -1), (0, 1)];
      final step = steps[random.nextInt(4)];
      cells.add((from.$1 + step.$1, from.$2 + step.$2));
    }
    return normalise(cells);
  }
}

enum OptionKind { rotation, mirror, altered }

class ShapeOption {
  const ShapeOption({required this.base, required this.turns,
    required this.kind});

  /// Shape drawn upright; the page rotates it by [turns] quarter turns.
  final List<Cell> base;
  final int turns;
  final OptionKind kind;

  bool get correct => kind == OptionKind.rotation;
  List<Cell> get displayed => Shapes.rotate(base, turns);
}

class ShapeRound {
  const ShapeRound({required this.target, required this.options});
  final List<Cell> target;
  final List<ShapeOption> options;
  int get answer => options.indexWhere((option) => option.correct);
}

enum ShapeAnswer { ignored, correct, incorrect, completed, failed }

/// Mental rotation: exactly one option is the target turned, the others are
/// mirror images or one-cell changes that no rotation can produce.
class ShapeTurnEngine {
  ShapeTurnEngine._({required this.level, required List<ShapeRound> rounds,
    required this.allowedMistakes})
      : rounds = List<ShapeRound>.unmodifiable(rounds);

  final int level;
  final List<ShapeRound> rounds;
  final int allowedMistakes;

  int _roundIndex = 0;
  int? _chosen;
  int mistakes = 0;
  int correct = 0;
  final Set<int> missedRounds = {};

  int get roundIndex => _roundIndex;
  ShapeRound get currentRound => rounds[min(_roundIndex, rounds.length - 1)];

  /// The option picked in the current round, until [advance] is called.
  int? get chosen => _chosen;
  bool get awaitingAdvance => _chosen != null;
  bool get isFailed => mistakes > allowedMistakes;
  bool get isCompleted => !isFailed && _roundIndex >= rounds.length;

  int get stars => mistakes == 0 ? 3 : mistakes == 1 ? 2 : 1;
  int get score => max(100, correct * 150 - mistakes * 50).toInt();
  int get spatialMetric => (correct * 100 / rounds.length).round();

  static int cellsForLevel(int level) =>
      level <= 5 ? 5 : level <= 20 ? 6 : level <= 45 ? 7 : 8;

  factory ShapeTurnEngine.forLevel(int level, {int? seed}) {
    final safeLevel = max(1, level).toInt();
    final random = Random(seed ?? safeLevel * 3001 + 7);
    final size = cellsForLevel(safeLevel);
    final roundCount = safeLevel < 10 ? 5 : safeLevel < 30 ? 6 : 8;
    final mirrors = safeLevel < 15 ? 1 : safeLevel < 40 ? 2 : 3;
    final rounds = <ShapeRound>[];
    final used = <String>{};

    while (rounds.length < roundCount) {
      final target = Shapes.grow(size, random);
      final targetClass = Shapes.rotationClass(target);
      if (!Shapes.isChiral(target) || used.contains(targetClass)) continue;
      final mirrorBase = Shapes.mirror(target);
      final mirrorClass = Shapes.rotationClass(mirrorBase);
      // Symmetric shapes can look upright after a half turn; skip such turns.
      final visibleTurns = [
        for (var t = 1; t < 4; t++)
          if (Shapes.key(Shapes.rotate(target, t)) != Shapes.key(target)) t,
      ];
      final options = <ShapeOption>[
        ShapeOption(base: target,
          turns: visibleTurns[random.nextInt(visibleTurns.length)],
          kind: OptionKind.rotation),
      ];
      // Mirror copies must look different from each other on screen.
      final mirrorTurns = [0, 1, 2, 3]..shuffle(random);
      final shownMirrors = <String>{};
      for (final turns in mirrorTurns) {
        if (shownMirrors.length == mirrors) break;
        if (!shownMirrors.add(Shapes.key(Shapes.rotate(mirrorBase, turns)))) {
          continue;
        }
        options.add(ShapeOption(base: mirrorBase, turns: turns,
          kind: OptionKind.mirror));
      }
      final seen = <String>{targetClass, mirrorClass};
      var guard = 0;
      while (options.length < 4 && guard++ < 200) {
        final altered = _alter(target, random);
        if (altered == null) continue;
        final alteredClass = Shapes.rotationClass(altered);
        if (!seen.add(alteredClass)) continue;
        // The mirror of an altered shape must not be the target either.
        if (Shapes.rotationClass(Shapes.mirror(altered)) == targetClass) continue;
        options.add(ShapeOption(base: altered, turns: random.nextInt(4),
          kind: OptionKind.altered));
      }
      if (options.length < 4) continue;
      options.shuffle(random);
      used.add(targetClass);
      rounds.add(ShapeRound(target: target, options: options));
    }
    return ShapeTurnEngine._(level: safeLevel, rounds: rounds,
      allowedMistakes: safeLevel < 10 ? 2 : 1);
  }

  /// Moves one cell to a new spot, keeping the shape connected.
  static List<Cell>? _alter(List<Cell> shape, Random random) {
    final cells = shape.toList();
    final removed = cells.removeAt(random.nextInt(cells.length));
    if (!Shapes.isConnected(cells)) return null;
    final spots = <Cell>{
      for (final (r, c) in cells)
        for (final next in [(r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)])
          if (!cells.contains(next) && next != removed) next,
    }.toList()
      ..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
    if (spots.isEmpty) return null;
    return Shapes.normalise([...cells, spots[random.nextInt(spots.length)]]);
  }

  ShapeAnswer answer(int option) {
    if (isFailed || isCompleted || awaitingAdvance ||
        option < 0 || option >= currentRound.options.length) {
      return ShapeAnswer.ignored;
    }
    _chosen = option;
    if (currentRound.options[option].correct) {
      correct++;
      return _roundIndex == rounds.length - 1
          ? ShapeAnswer.completed : ShapeAnswer.correct;
    }
    mistakes++;
    missedRounds.add(_roundIndex);
    if (isFailed) return ShapeAnswer.failed;
    return _roundIndex == rounds.length - 1
        ? ShapeAnswer.completed : ShapeAnswer.incorrect;
  }

  /// Moves on after the page has shown the answer feedback.
  void advance() {
    if (!awaitingAdvance || isFailed) return;
    _chosen = null;
    _roundIndex++;
  }
}
