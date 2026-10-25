import 'dart:math';

enum OrbitMoveResult { invalid, incorrect, roundSolved }

class OrbitRound {
  const OrbitRound({
    required this.size,
    required this.clockwiseTurns,
    required this.targetIndex,
  })  : assert(size > 1),
        assert(clockwiseTurns >= 1 && clockwiseTurns <= 3);

  final int size;
  final int clockwiseTurns;
  final int targetIndex;
  int get cellCount => size * size;

  int get answerIndex {
    for (var index = 0; index < cellCount; index++) {
      if (rotateIndex(index, size, clockwiseTurns) == targetIndex) {
        return index;
      }
    }
    throw StateError('Target is outside the board');
  }

  static int rotateIndex(int index, int size, int clockwiseTurns) {
    if (size <= 0) throw ArgumentError.value(size, 'size');
    if (index < 0 || index >= size * size) {
      throw RangeError.value(index, 'index');
    }
    var row = index ~/ size;
    var column = index % size;
    for (var turn = 0; turn < clockwiseTurns % 4; turn++) {
      final nextRow = column;
      final nextColumn = size - 1 - row;
      row = nextRow;
      column = nextColumn;
    }
    return row * size + column;
  }

  String get turnLabel => switch (clockwiseTurns) {
        1 => '90° clockwise',
        2 => '180° clockwise',
        _ => '270° clockwise',
      };

  String get targetLabel =>
      'row ${targetIndex ~/ size + 1}, column ${targetIndex % size + 1}';
}

class OrbitSession {
  OrbitSession({required this.seed}) {
    final random = Random(seed);
    rounds = List<OrbitRound>.unmodifiable(List.generate(
      roundCount,
      (_) => OrbitRound(
        size: gridSize,
        clockwiseTurns: 1 + random.nextInt(3),
        targetIndex: random.nextInt(gridSize * gridSize),
      ),
    ));
  }

  static const int roundCount = 5;
  static const int gridSize = 4;
  final int seed;
  late final List<OrbitRound> rounds;
  int roundIndex = 0;
  int mistakes = 0;
  int? lastSelection;

  bool get finished => roundIndex >= roundCount;
  int get completedRounds => roundIndex;
  double get progress => completedRounds / roundCount;
  OrbitRound get current =>
      rounds[roundIndex.clamp(0, roundCount - 1).toInt()];

  OrbitMoveResult select(int index) {
    if (finished || index < 0 || index >= current.cellCount) {
      return OrbitMoveResult.invalid;
    }
    lastSelection = index;
    if (index != current.answerIndex) {
      mistakes++;
      return OrbitMoveResult.incorrect;
    }
    roundIndex++;
    lastSelection = null;
    return OrbitMoveResult.roundSolved;
  }
}
