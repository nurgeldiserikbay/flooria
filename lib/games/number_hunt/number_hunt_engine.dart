import 'dart:math';

enum NumberHuntTapResult { ignored, correct, incorrect, completed }

/// One board asks the player to locate a single number among distractors.
class NumberHuntRound {
  NumberHuntRound({
    required this.target,
    required List<int> numbers,
    required this.targetIndex,
  }) : numbers = List<int>.unmodifiable(numbers);

  final int target;
  final List<int> numbers;
  final int targetIndex;
}

/// Rules for the single-player number search game.
class NumberHuntEngine {
  NumberHuntEngine._({
    required this.level,
    required this.columns,
    required this.rows,
    required List<NumberHuntRound> rounds,
  }) : rounds = List<NumberHuntRound>.unmodifiable(rounds);

  static const int baseRoundsPerLevel = 5;
  static const int maxGridColumns = 6;
  static const int maxGridRows = 7;

  final int level;
  final int columns;
  final int rows;
  final List<NumberHuntRound> rounds;

  int _roundIndex = 0;
  int mistakes = 0;

  int get roundIndex => _roundIndex;
  int get cellCount => columns * rows;
  bool get isCompleted => _roundIndex >= rounds.length;
  int get roundsCompleted => _roundIndex;
  int get score => max(0, roundsCompleted * 100 - mistakes * 10).toInt();
  NumberHuntRound get currentRound => rounds[min(_roundIndex, rounds.length - 1)];

  factory NumberHuntEngine.forLevel(int level, {int? seed}) {
    final safeLevel = max(1, level).toInt();
    final columns = min(4 + (safeLevel - 1) ~/ 8, maxGridColumns).toInt();
    final rows = min(4 + (safeLevel - 1) ~/ 5, maxGridRows).toInt();
    final roundCount = min(baseRoundsPerLevel + (safeLevel - 1) ~/ 12, 9).toInt();
    final random = Random(seed ?? safeLevel * 104729);
    final cellCount = columns * rows;
    final rounds = <NumberHuntRound>[];
    int? previousTarget;

    for (var round = 0; round < roundCount; round++) {
      var target = random.nextInt(10);
      if (target == previousTarget) {
        target = (target + 1 + random.nextInt(9)) % 10;
      }
      previousTarget = target;
      final targetIndex = random.nextInt(cellCount);
      final numbers = List<int>.generate(cellCount, (_) {
        final distractor = random.nextInt(9);
        return distractor >= target ? distractor + 1 : distractor;
      });
      numbers[targetIndex] = target;
      rounds.add(NumberHuntRound(
        target: target,
        numbers: numbers,
        targetIndex: targetIndex,
      ));
    }

    return NumberHuntEngine._(
      level: safeLevel,
      columns: columns,
      rows: rows,
      rounds: rounds,
    );
  }

  NumberHuntTapResult tap(int index) {
    if (isCompleted || index < 0 || index >= cellCount) {
      return NumberHuntTapResult.ignored;
    }
    if (index != currentRound.targetIndex) {
      mistakes++;
      return NumberHuntTapResult.incorrect;
    }
    _roundIndex++;
    return isCompleted
        ? NumberHuntTapResult.completed
        : NumberHuntTapResult.correct;
  }
}
