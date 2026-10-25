import 'dart:math';

enum SearchShape { circle, square, triangle, diamond }

enum SearchColor { coral, blue, yellow, green, purple }

enum SearchPickResult { invalid, incorrect, correct, complete }

class SearchToken {
  const SearchToken({required this.shape, required this.color});

  final SearchShape shape;
  final SearchColor color;

  bool matches(SearchToken other) =>
      shape == other.shape && color == other.color;

  @override
  bool operator ==(Object other) =>
      other is SearchToken && shape == other.shape && color == other.color;

  @override
  int get hashCode => Object.hash(shape, color);
}

class FocusSearchRound {
  FocusSearchRound({
    required this.target,
    required this.columns,
    required this.targetIndex,
    required Iterable<SearchToken> tokens,
  }) : tokens = List<SearchToken>.unmodifiable(tokens) {
    if (columns < 1 || tokens.isEmpty || targetIndex < 0 ||
        targetIndex >= tokens.length ||
        tokens.where((token) => token.matches(target)).length != 1 ||
        !this.tokens[targetIndex].matches(target)) {
      throw ArgumentError('A search round must contain exactly one target.');
    }
  }

  final SearchToken target;
  final int columns;
  final int targetIndex;
  final List<SearchToken> tokens;

  int get rows => (tokens.length / columns).ceil();
}

class FocusFinderSession {
  FocusFinderSession({required this.seed, int level = 1}) {
    final random = Random(seed);
    final extra = (level - 1).clamp(0, 3).toInt();
    rounds = List<FocusSearchRound>.unmodifiable(
      List.generate(roundCount, (index) {
        final cellCount = _cellCounts[index] + extra * 2;
        return _makeRound(random, index, cellCount);
      }),
    );
  }

  static const int roundCount = 5;
  static const List<int> _cellCounts = [9, 12, 16, 16, 20];

  final int seed;
  late final List<FocusSearchRound> rounds;
  int round = 0;
  int correctFinds = 0;
  int mistakes = 0;

  bool get finished => round >= roundCount;
  double get progress => round / roundCount;
  FocusSearchRound get current =>
      rounds[round.clamp(0, roundCount - 1).toInt()];

  SearchPickResult choose(int cellIndex) {
    if (finished || cellIndex < 0 || cellIndex >= current.tokens.length) {
      return SearchPickResult.invalid;
    }
    if (cellIndex != current.targetIndex) {
      mistakes++;
      return SearchPickResult.incorrect;
    }

    correctFinds++;
    round++;
    return finished ? SearchPickResult.complete : SearchPickResult.correct;
  }

  FocusSearchRound _makeRound(Random random, int roundIndex, int cellCount) {
    final colors = SearchColor.values;
    final shapes = SearchShape.values;
    final target = SearchToken(
      color: colors[random.nextInt(colors.length)],
      shape: shapes[random.nextInt(shapes.length)],
    );
    final targetIndex = random.nextInt(cellCount);
    final tokens = <SearchToken>[];

    for (var index = 0; index < cellCount; index++) {
      if (index == targetIndex) {
        tokens.add(target);
        continue;
      }

      // Alternate between items sharing one target feature and items sharing
      // the other, so players must compare both color and shape.
      if ((index + roundIndex).isEven) {
        var color = colors[random.nextInt(colors.length)];
        while (color == target.color) {
          color = colors[random.nextInt(colors.length)];
        }
        tokens.add(SearchToken(shape: target.shape, color: color));
      } else {
        var shape = shapes[random.nextInt(shapes.length)];
        while (shape == target.shape) {
          shape = shapes[random.nextInt(shapes.length)];
        }
        tokens.add(SearchToken(shape: shape, color: target.color));
      }
    }

    return FocusSearchRound(
      target: target,
      columns: cellCount <= 9 ? 3 : 4,
      targetIndex: targetIndex,
      tokens: tokens,
    );
  }
}
