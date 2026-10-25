import 'dart:math';

enum CubePickResult { invalid, incorrect, correct, complete }

class CubeLayout {
  CubeLayout(Iterable<int> heights)
      : heights = List<int>.unmodifiable(heights) {
    if (this.heights.length != 9 ||
        this.heights.any((height) => height < 0)) {
      throw ArgumentError('A cube layout needs nine non-negative heights.');
    }
  }

  final List<int> heights;

  int heightAt(int row, int column) => heights[row * 3 + column];
  int get totalCubes => heights.fold(0, (sum, height) => sum + height);

  List<int> get frontProfile => List<int>.unmodifiable([
        for (var column = 0; column < 3; column++)
          _max([for (var row = 0; row < 3; row++) heightAt(row, column)]),
      ]);

  List<int> get sideProfile => List<int>.unmodifiable([
        for (var row = 0; row < 3; row++)
          _max([for (var column = 0; column < 3; column++) heightAt(row, column)]),
      ]);

  List<bool> get topFootprint =>
      List<bool>.unmodifiable(heights.map((height) => height > 0));

  static int _max(List<int> values) =>
      values.reduce((first, second) => first > second ? first : second);
}

class CubeClues {
  CubeClues({
    required Iterable<int> front,
    required Iterable<int> side,
    required Iterable<bool> footprint,
  })  : front = List<int>.unmodifiable(front),
        side = List<int>.unmodifiable(side),
        footprint = List<bool>.unmodifiable(footprint);

  factory CubeClues.fromLayout(CubeLayout layout) => CubeClues(
        front: layout.frontProfile,
        side: layout.sideProfile,
        footprint: layout.topFootprint,
      );

  final List<int> front;
  final List<int> side;
  final List<bool> footprint;

  bool matches(CubeLayout layout) =>
      _same(front, layout.frontProfile) &&
      _same(side, layout.sideProfile) &&
      _same(footprint, layout.topFootprint);

  static bool _same<T>(List<T> first, List<T> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }
}

class CubePuzzle {
  CubePuzzle({
    required this.clues,
    required Iterable<CubeLayout> options,
    required this.answerIndex,
  }) : options = List<CubeLayout>.unmodifiable(options);

  final CubeClues clues;
  final List<CubeLayout> options;
  final int answerIndex;
}

/// Seeded 3D block puzzles. Every wrong option contradicts at least one view.
class CubeVistaSession {
  CubeVistaSession({required this.seed}) {
    final random = Random(seed);
    puzzles = List<CubePuzzle>.unmodifiable(List.generate(
      roundCount,
      (round) => _makePuzzle(random, round),
    ));
  }

  static const int roundCount = 6;
  final int seed;
  late final List<CubePuzzle> puzzles;
  int roundIndex = 0;
  int correctAnswers = 0;
  int mistakes = 0;

  bool get finished => roundIndex >= roundCount;
  double get progress => roundIndex / roundCount;
  CubePuzzle get current =>
      puzzles[roundIndex.clamp(0, roundCount - 1).toInt()];

  CubePickResult choose(int optionIndex) {
    if (finished || optionIndex < 0 || optionIndex >= current.options.length) {
      return CubePickResult.invalid;
    }
    if (optionIndex != current.answerIndex) {
      mistakes++;
      return CubePickResult.incorrect;
    }
    correctAnswers++;
    roundIndex++;
    return finished ? CubePickResult.complete : CubePickResult.correct;
  }

  CubePuzzle _makePuzzle(Random random, int round) {
    final maxHeight = 2 + round ~/ 2;
    CubeLayout randomLayout() {
      final heights = List<int>.generate(
        9,
        (_) => random.nextInt(maxHeight + 1),
      );
      if (heights.where((height) => height > 0).length < 3) {
        for (var index = 0; index < 3; index++) {
          heights[index] = 1 + random.nextInt(maxHeight);
        }
      }
      return CubeLayout(heights);
    }

    final answer = randomLayout();
    final clues = CubeClues.fromLayout(answer);
    final distractors = <CubeLayout>[];
    while (distractors.length < 2) {
      final candidate = randomLayout();
      if (clues.matches(candidate) ||
          distractors.any((layout) => _sameHeights(layout, candidate))) {
        continue;
      }
      distractors.add(candidate);
    }

    final options = <CubeLayout>[answer, ...distractors]..shuffle(random);
    return CubePuzzle(
      clues: clues,
      options: options,
      answerIndex: options.indexOf(answer),
    );
  }

  bool _sameHeights(CubeLayout first, CubeLayout second) {
    for (var index = 0; index < first.heights.length; index++) {
      if (first.heights[index] != second.heights[index]) return false;
    }
    return true;
  }
}
