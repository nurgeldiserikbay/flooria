import 'dart:math';

enum OrderClueKind { before, immediatelyBefore, first, last }

class OrderClue {
  const OrderClue(this.kind, this.a, [this.b]);
  final OrderClueKind kind;
  final int a;
  final int? b;

  bool holds(List<int> order) {
    final pos = order.indexOf(a);
    final other = b == null ? -1 : order.indexOf(b!);
    return switch (kind) {
      OrderClueKind.before => pos < other,
      OrderClueKind.immediatelyBefore => other == pos + 1,
      OrderClueKind.first => pos == 0,
      OrderClueKind.last => pos == order.length - 1,
    };
  }

  String describe() {
    final firstName = String.fromCharCode(65 + a);
    final secondName = b == null ? '' : String.fromCharCode(65 + b!);
    return switch (kind) {
      OrderClueKind.before => '$firstName comes before $secondName',
      OrderClueKind.immediatelyBefore =>
        '$firstName is directly before $secondName',
      OrderClueKind.first => '$firstName is first',
      OrderClueKind.last => '$firstName is last',
    };
  }
}

/// Reorder symbols to satisfy a uniquely solvable set of logical clues.
class OrderLabSession {
  OrderLabSession({required this.seed, this.roundCount = 3})
      : assert(roundCount > 0) {
    _newRound();
  }

  final int seed;
  final int roundCount;
  int round = 0;
  int swaps = 0;
  int checks = 0;
  int mistakes = 0;
  int? selected;
  late List<int> answer;
  late List<int> order;
  late List<OrderClue> clues;
  bool get complete => round >= roundCount;

  static List<List<int>> permutations(int count) {
    final results = <List<int>>[];
    void visit(List<int> prefix, Set<int> used) {
      if (prefix.length == count) {
        results.add(List.of(prefix));
        return;
      }
      for (var i = 0; i < count; i++) {
        if (used.contains(i)) continue;
        prefix.add(i);
        used.add(i);
        visit(prefix, used);
        prefix.removeLast();
        used.remove(i);
      }
    }
    visit([], {});
    return results;
  }

  static bool matches(List<int> candidate, List<OrderClue> rules) =>
      rules.every((clue) => clue.holds(candidate));

  List<List<int>> get solutions => permutations(answer.length)
      .where((candidate) => matches(candidate, clues)).toList();

  void _newRound() {
    if (complete) return;
    final random = Random((seed * 65537 + round * 104729) & 0x7fffffff);
    final count = round == 0 ? 4 : 5;
    answer = List.generate(count, (i) => i)..shuffle(random);
    final candidates = <OrderClue>[];
    for (var i = 0; i < count; i++) {
      for (var j = i + 1; j < count; j++) {
        candidates.add(OrderClue(OrderClueKind.before, answer[i], answer[j]));
        if (j == i + 1) {
          candidates.add(OrderClue(
              OrderClueKind.immediatelyBefore, answer[i], answer[j]));
        }
      }
    }
    candidates.add(OrderClue(OrderClueKind.first, answer.first));
    candidates.add(OrderClue(OrderClueKind.last, answer.last));
    candidates.shuffle(random);
    final possible = permutations(count);
    var remaining = possible;
    final chosen = <OrderClue>[];
    while (remaining.length > 1) {
      OrderClue? best;
      var bestCount = remaining.length;
      for (final clue in candidates) {
        if (chosen.contains(clue)) continue;
        final length = remaining.where((p) => clue.holds(p)).length;
        if (length < bestCount) {
          best = clue;
          bestCount = length;
        }
      }
      if (best == null) throw StateError('Unable to identify unique order');
      chosen.add(best);
      remaining = remaining.where((p) => best!.holds(p)).toList();
    }
    clues = List.unmodifiable(chosen);
    order = List.of(answer);
    // Rotate to a wrong but deterministic initial permutation.
    final offset = 1 + random.nextInt(count - 1);
    order = List.generate(count, (i) => answer[(i + offset) % count]);
    selected = null;
  }

  bool get solved => !complete && matches(order, clues);

  /// Tap one symbol to select, another to exchange their positions.
  bool tap(int position) {
    if (complete || position < 0 || position >= order.length) return false;
    if (selected == null) {
      selected = position;
      return true;
    }
    if (selected == position) {
      selected = null;
      return true;
    }
    final previous = order[selected!];
    order[selected!] = order[position];
    order[position] = previous;
    selected = null;
    swaps++;
    return true;
  }

  bool check() {
    if (complete) return false;
    checks++;
    if (!solved) {
      mistakes++;
      return false;
    }
    round++;
    _newRound();
    return true;
  }
}
