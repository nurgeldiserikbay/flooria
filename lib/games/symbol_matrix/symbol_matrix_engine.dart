import 'dart:math';

/// A tile in the abstract matrix: symbol, color, count, and quarter-turns.
class MatrixSymbol {
  const MatrixSymbol({
    required this.shape,
    required this.color,
    required this.count,
    required this.rotation,
  });

  final int shape;
  final int color;
  final int count;
  final int rotation;

  int valueAt(int attribute) => switch (attribute) {
        0 => shape,
        1 => color,
        2 => count,
        3 => rotation,
        _ => throw RangeError.range(attribute, 0, 3, 'attribute'),
      };

  MatrixSymbol withValue(int attribute, int value) => switch (attribute) {
        0 => MatrixSymbol(
            shape: value,
            color: color,
            count: count,
            rotation: rotation,
          ),
        1 => MatrixSymbol(
            shape: shape,
            color: value,
            count: count,
            rotation: rotation,
          ),
        2 => MatrixSymbol(
            shape: shape,
            color: color,
            count: value,
            rotation: rotation,
          ),
        3 => MatrixSymbol(
            shape: shape,
            color: color,
            count: count,
            rotation: value,
          ),
        _ => throw RangeError.range(attribute, 0, 3, 'attribute'),
      };

  @override
  bool operator ==(Object other) =>
      other is MatrixSymbol &&
      other.shape == shape &&
      other.color == color &&
      other.count == count &&
      other.rotation == rotation;

  @override
  int get hashCode => Object.hash(shape, color, count, rotation);
}

enum MatrixAnswerResult { invalid, correct, incorrect, sessionComplete }

/// Seeded abstract-reasoning session with one missing matrix tile per round.
class SymbolMatrixSession {
  SymbolMatrixSession({required this.seed}) {
    _newRound();
  }

  static const int roundCount = 6;
  static const int passScore = 4;
  static const int optionCount = 4;
  static const List<int> _domains = [4, 4, 3, 4];

  final int seed;

  int round = 0;
  int correctAnswers = 0;
  int mistakes = 0;
  int attempts = 0;
  int? selectedOption;
  bool? lastAnswerCorrect;
  late List<MatrixSymbol?> cells;
  late List<MatrixSymbol> options;
  late int answerIndex;

  bool get complete => round >= roundCount;
  bool get roundComplete => !complete && selectedOption != null;
  bool get passed => complete && correctAnswers >= passScore;

  /// Submit one answer. Invalid options and repeated submissions are ignored.
  MatrixAnswerResult answer(int optionIndex) {
    if (complete || roundComplete || optionIndex < 0 ||
        optionIndex >= options.length) {
      return MatrixAnswerResult.invalid;
    }

    attempts++;
    selectedOption = optionIndex;
    lastAnswerCorrect = optionIndex == answerIndex;
    if (lastAnswerCorrect!) {
      correctAnswers++;
    } else {
      mistakes++;
    }

    if (round == roundCount - 1) {
      round++;
      return MatrixAnswerResult.sessionComplete;
    }
    return lastAnswerCorrect!
        ? MatrixAnswerResult.correct
        : MatrixAnswerResult.incorrect;
  }

  /// Continue after a checked answer; returns false when the round is active
  /// or the session has ended.
  bool nextRound() {
    if (!roundComplete) return false;
    round++;
    selectedOption = null;
    lastAnswerCorrect = null;
    _newRound();
    return true;
  }

  void _newRound() {
    if (complete) return;
    final random = Random((seed * 65537 + round * 104729) & 0x7fffffff);
    final bases = List<int>.generate(
      _domains.length,
      (attribute) => random.nextInt(_domains[attribute]),
    );
    final rowSteps = List<int>.generate(
      _domains.length,
      (attribute) => 1 + random.nextInt(_domains[attribute] - 1),
    );
    final columnSteps = List<int>.generate(
      _domains.length,
      (attribute) => 1 + random.nextInt(_domains[attribute] - 1),
    );

    MatrixSymbol at(int row, int column) {
      final values = List<int>.generate(_domains.length, (attribute) {
        final value = bases[attribute] +
            row * rowSteps[attribute] +
            column * columnSteps[attribute];
        return value % _domains[attribute];
      });
      return MatrixSymbol(
        shape: values[0],
        color: values[1],
        count: values[2] + 1,
        rotation: values[3],
      );
    }

    final target = at(2, 2);
    final generatedCells = <MatrixSymbol?>[
      for (var row = 0; row < 3; row++)
        for (var column = 0; column < 3; column++)
          if (row == 2 && column == 2) null else at(row, column),
    ];
    cells = List<MatrixSymbol?>.unmodifiable(generatedCells);

    final changedAttributes = [0, 1, 2, 3]..shuffle(random);
    final distractors = <MatrixSymbol>[];
    for (final attribute in changedAttributes.take(optionCount - 1)) {
      final domain = _domains[attribute];
      final delta = 1 + random.nextInt(domain - 1);
      final replacement = (target.valueAt(attribute) + delta) % domain;
      distractors.add(target.withValue(attribute, replacement));
    }

    options = <MatrixSymbol>[target, ...distractors]..shuffle(random);
    options = List<MatrixSymbol>.unmodifiable(options);
    answerIndex = options.indexOf(target);
  }
}
