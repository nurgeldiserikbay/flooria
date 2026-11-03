import 'dart:math';

enum SetMove { selected, invalid, found, completed, ignored }

class MatchCard {
  const MatchCard(this.color, this.shape, this.count, this.fill);
  final int color;
  final int shape;
  final int count;
  final int fill;
}

/// Find triples where every card attribute is all the same or all different.
class SetMatchEngine {
  SetMatchEngine._(this.level, this.cards, this.goalSets);

  final int level;
  final List<MatchCard?> cards;
  final int goalSets;
  final Set<int> selected = {};
  int setsFound = 0;
  int moves = 0;
  bool isCompleted = false;
  int get score => max(100, 1000 + setsFound * 180 - moves * 8).toInt();

  factory SetMatchEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final random = Random(safe * 31741 + 107);
    final guaranteed = <MatchCard>[
      const MatchCard(0, 0, 1, 0), const MatchCard(1, 1, 2, 1),
      const MatchCard(2, 2, 3, 2),
      const MatchCard(0, 1, 2, 0), const MatchCard(1, 2, 3, 1),
      const MatchCard(2, 0, 1, 2),
    ];
    final remaining = <MatchCard>[
      for (var color = 0; color < 3; color++)
        for (var shape = 0; shape < 3; shape++)
          for (var count = 1; count <= 3; count++)
            for (var fill = 0; fill < 3; fill++)
              if (!guaranteed.any((card) => card.color == color &&
                  card.shape == shape && card.count == count && card.fill == fill))
                MatchCard(color, shape, count, fill),
    ]..shuffle(random);
    final deck = [...guaranteed, ...remaining.take(6)]..shuffle(random);
    return SetMatchEngine._(safe, List<MatchCard?>.of(deck), 2);
  }

  SetMove tap(int index) {
    if (isCompleted || index < 0 || index >= cards.length || cards[index] == null) {
      return SetMove.ignored;
    }
    if (!selected.add(index)) {
      selected.remove(index);
      return SetMove.selected;
    }
    if (selected.length < 3) return SetMove.selected;
    moves++;
    final triple = selected.map((cell) => cards[cell]!).toList();
    if (_isSet(triple)) {
      for (final cell in selected) { cards[cell] = null; }
      selected.clear();
      setsFound++;
      isCompleted = setsFound >= goalSets;
      return isCompleted ? SetMove.completed : SetMove.found;
    }
    final last = index;
    selected
      ..clear()
      ..add(last);
    return SetMove.invalid;
  }

  static bool _isSet(List<MatchCard> cards) {
    bool valid(List<int> values) {
      final distinct = values.toSet().length;
      return distinct == 1 || distinct == 3;
    }
    return valid(cards.map((card) => card.color).toList()) &&
        valid(cards.map((card) => card.shape).toList()) &&
        valid(cards.map((card) => card.count).toList()) &&
        valid(cards.map((card) => card.fill).toList());
  }
}
