import 'dart:math';

/// Three independent attributes, each with values 0, 1, 2.
/// A trio is valid when each attribute is all equal or all distinct.
class PatternCard {
  const PatternCard(this.shape, this.color, this.count);
  final int shape;
  final int color;
  final int count;

  int get code => shape * 9 + color * 3 + count;

  @override
  bool operator ==(Object other) => other is PatternCard &&
      other.shape == shape && other.color == color && other.count == count;
  @override
  int get hashCode => code.hashCode;

  static PatternCard fromCode(int code) {
    if (code < 0 || code >= 27) {
      throw RangeError.range(code, 0, 26, 'code');
    }
    return PatternCard(code ~/ 9, (code ~/ 3) % 3, code % 3);
  }
}

class PatternTrioSession {
  PatternTrioSession({required this.seed, this.roundCount = 3})
      : assert(roundCount > 0) {
    _newRound();
  }

  final int seed;
  final int roundCount;
  int round = 0;
  int mistakes = 0;
  int attempts = 0;
  int totalTaps = 0;
  late List<PatternCard> cards;
  final Set<int> selected = {};
  bool get complete => round >= roundCount;

  static bool _validAttribute(int a, int b, int c) =>
      (a == b && b == c) || (a != b && b != c && a != c);

  static bool isTrio(PatternCard a, PatternCard b, PatternCard c) {
    if (a == b || b == c || a == c) return false;
    return _validAttribute(a.shape, b.shape, c.shape) &&
        _validAttribute(a.color, b.color, c.color) &&
        _validAttribute(a.count, b.count, c.count);
  }

  /// Given two different cards, the third card is uniquely determined.
  static PatternCard complement(PatternCard a, PatternCard b) {
    if (a == b) throw ArgumentError('Cards must be distinct');
    int third(int x, int y) => x == y ? x : 3 - x - y;
    return PatternCard(
      third(a.shape, b.shape),
      third(a.color, b.color),
      third(a.count, b.count),
    );
  }

  List<int>? get exampleTrio {
    for (var i = 0; i < cards.length; i++) {
      for (var j = i + 1; j < cards.length; j++) {
        for (var k = j + 1; k < cards.length; k++) {
          if (isTrio(cards[i], cards[j], cards[k])) return [i, j, k];
        }
      }
    }
    return null;
  }

  void _newRound() {
    if (complete) return;
    final random = Random((seed * 65537 + round * 104729) & 0x7fffffff);
    final pool = [for (var i = 0; i < 27; i++) PatternCard.fromCode(i)]
      ..shuffle(random);
    final first = pool[0];
    final second = pool[1];
    final third = complement(first, second);
    final choices = <PatternCard>[first, second, third];
    for (final card in pool) {
      if (choices.length >= 9) break;
      if (!choices.contains(card)) choices.add(card);
    }
    choices.shuffle(random);
    cards = List.unmodifiable(choices);
    selected.clear();
  }

  /// Third tap checks immediately. Failure clears the selection.
  /// Success moves to the next round. Already-selected card toggles off.
  bool tap(int index) {
    if (complete || index < 0 || index >= cards.length) return false;
    totalTaps++;
    if (!selected.add(index)) {
      selected.remove(index);
      return true;
    }
    if (selected.length == 3) {
      attempts++;
      final indices = selected.toList();
      final correct = isTrio(cards[indices[0]], cards[indices[1]],
          cards[indices[2]]);
      if (correct) {
        round++;
        _newRound();
      } else {
        mistakes++;
        selected.clear();
      }
    }
    return true;
  }
}
