import 'dart:math';

enum CategorySide { left, right }
enum CategoryAnswer { invalid, correct, incorrect }

class CategoryItem {
  const CategoryItem({required this.label, required this.side});

  final String label;
  final CategorySide side;
}

class CategorySortRound {
  const CategorySortRound({
    required this.leftCategory,
    required this.rightCategory,
    required this.items,
  });

  final String leftCategory;
  final String rightCategory;
  final List<CategoryItem> items;
}

/// Seeded semantic sorting session. Each card has one curated category.
class SemanticSortSession {
  SemanticSortSession({required this.seed, int level = 1}) {
    final random = Random(seed);
    final itemCount = level < 4 ? 6 : (level < 10 ? 8 : 10);
    final pairs = List<_CategoryPair>.of(_categoryPairs)..shuffle(random);
    rounds = List<CategorySortRound>.unmodifiable(
      List.generate(
        roundCount,
        (index) => _makeRound(pairs[index], itemCount, random),
      ),
    );
    itemsPerRound = itemCount;
  }

  static const int roundCount = 5;
  static const int passPercent = 80;

  static const _categoryPairs = <_CategoryPair>[
    _CategoryPair('Fruit', 'Tools',
        ['apple', 'pear', 'grape', 'lemon', 'peach'],
        ['hammer', 'saw', 'wrench', 'drill', 'pliers']),
    _CategoryPair('Sea life', 'Farm animals',
        ['shark', 'whale', 'octopus', 'dolphin', 'turtle'],
        ['cow', 'sheep', 'horse', 'pig', 'goat']),
    _CategoryPair('Furniture', 'Transport',
        ['chair', 'table', 'sofa', 'desk', 'bed'],
        ['train', 'bicycle', 'airplane', 'boat', 'scooter']),
    _CategoryPair('Instruments', 'Body parts',
        ['trumpet', 'violin', 'drum', 'flute', 'piano'],
        ['elbow', 'ankle', 'shoulder', 'knee', 'wrist']),
    _CategoryPair('Weather', 'Kitchen items',
        ['cloud', 'rain', 'wind', 'snow', 'fog'],
        ['kettle', 'pan', 'spoon', 'plate', 'oven']),
    _CategoryPair('Wild animals', 'Flowers',
        ['tiger', 'wolf', 'eagle', 'fox', 'bear'],
        ['rose', 'tulip', 'daisy', 'orchid', 'lily']),
    _CategoryPair('Space objects', 'Minerals',
        ['planet', 'comet', 'asteroid', 'moon', 'star'],
        ['ruby', 'opal', 'amber', 'jade', 'quartz']),
  ];

  final int seed;
  late final List<CategorySortRound> rounds;
  late final int itemsPerRound;
  int roundIndex = 0;
  int itemIndex = 0;
  int correctAnswers = 0;
  int mistakes = 0;
  bool _answered = false;

  bool get finished => roundIndex >= roundCount;
  bool get answered => _answered;
  int get totalItems => roundCount * itemsPerRound;
  int get scoreToPass => (totalItems * passPercent + 99) ~/ 100;
  bool get passed => finished && correctAnswers >= scoreToPass;
  double get progress {
    if (finished) return 1;
    return (roundIndex * itemsPerRound + itemIndex) / totalItems;
  }

  CategorySortRound get currentRound =>
      rounds[roundIndex.clamp(0, roundCount - 1).toInt()];
  CategoryItem get currentItem => currentRound.items[itemIndex];

  CategoryAnswer answer(CategorySide side) {
    if (finished || _answered) return CategoryAnswer.invalid;
    _answered = true;
    if (side == currentItem.side) {
      correctAnswers++;
      return CategoryAnswer.correct;
    }
    mistakes++;
    return CategoryAnswer.incorrect;
  }

  bool advance() {
    if (finished || !_answered) return false;
    _answered = false;
    itemIndex++;
    if (itemIndex == itemsPerRound) {
      itemIndex = 0;
      roundIndex++;
    }
    return true;
  }

  static CategorySortRound _makeRound(
    _CategoryPair pair,
    int itemCount,
    Random random,
  ) {
    final left = List<String>.of(pair.leftItems)..shuffle(random);
    final right = List<String>.of(pair.rightItems)..shuffle(random);
    final items = <CategoryItem>[
      for (final label in left.take(itemCount ~/ 2))
        CategoryItem(label: label, side: CategorySide.left),
      for (final label in right.take(itemCount ~/ 2))
        CategoryItem(label: label, side: CategorySide.right),
    ]..shuffle(random);
    return CategorySortRound(
      leftCategory: pair.leftLabel,
      rightCategory: pair.rightLabel,
      items: List<CategoryItem>.unmodifiable(items),
    );
  }
}

class _CategoryPair {
  const _CategoryPair(
    this.leftLabel,
    this.rightLabel,
    this.leftItems,
    this.rightItems,
  );

  final String leftLabel;
  final String rightLabel;
  final List<String> leftItems;
  final List<String> rightItems;
}
