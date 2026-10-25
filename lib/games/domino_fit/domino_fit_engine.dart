import 'dart:math';

/// A domino tiling puzzle with verifiably solvable 4x4 boards.
/// Obstacles are removed from a complete tiling, so each round has a proof.
class DominoFitSession {
  DominoFitSession({required this.seed, this.roundCount = 3})
      : assert(roundCount > 0) {
    _newRound();
  }

  static const side = 4;
  final int seed;
  final int roundCount;
  int round = 0;
  int moves = 0;
  int removals = 0;
  int? anchor;
  final Set<int> blocked = {};
  final Map<int, int> placed = {};
  final List<(int, int)> solution = [];

  bool get complete => round >= roundCount;
  bool get roundSolved =>
      !complete && placed.length + blocked.length == side * side;
  int get remaining => (side * side - blocked.length - placed.length) ~/ 2;

  bool adjacent(int a, int b) {
    if (a < 0 || b < 0 || a >= 16 || b >= 16) return false;
    final r1 = a ~/ side, c1 = a % side;
    final r2 = b ~/ side, c2 = b % side;
    return (r1 - r2).abs() + (c1 - c2).abs() == 1;
  }

  /// Randomized exact-cover construction. No unbounded retries.
  void _newRound() {
    if (complete) return;
    final random = Random((seed * 65537 + round * 7919) & 0x7fffffff);
    final taken = <int>{};
    final pairs = <(int, int)>[];
    bool build() {
      if (taken.length == 16) return true;
      final first = List<int>.generate(16, (i) => i)
          .firstWhere((i) => !taken.contains(i));
      final neighbors = [
        first - side, first + side, first - 1, first + 1,
      ].where((i) => adjacent(first, i) && !taken.contains(i)).toList()
        ..shuffle(random);
      for (final neighbor in neighbors) {
        taken.add(first);
        taken.add(neighbor);
        pairs.add((first, neighbor));
        if (build()) return true;
        pairs.removeLast();
        taken.remove(first);
        taken.remove(neighbor);
      }
      return false;
    }
    if (!build()) throw StateError('Failed to construct domino board');
    pairs.shuffle(random);
    blocked.clear();
    placed.clear();
    solution.clear();
    anchor = null;
    final blockedPairs = round == 0 ? 0 : round == 1 ? 1 : 2;
    for (var i = 0; i < pairs.length; i++) {
      final pair = pairs[i];
      if (i < blockedPairs) {
        blocked.add(pair.$1);
        blocked.add(pair.$2);
      } else {
        solution.add(pair);
      }
    }
  }

  /// First tap selects a free cell. Second adjacent free cell places
  /// a domino. Tapping an existing domino removes it. Invalid input is inert.
  bool tap(int cell) {
    if (complete || cell < 0 || cell >= 16 || blocked.contains(cell)) {
      return false;
    }
    if (placed.containsKey(cell)) {
      final partner = placed[cell]!;
      placed.remove(cell);
      placed.remove(partner);
      anchor = null;
      moves++;
      removals++;
      return true;
    }
    if (anchor == null) {
      anchor = cell;
      return true;
    }
    if (anchor == cell) {
      anchor = null;
      return true;
    }
    if (!adjacent(anchor!, cell)) {
      anchor = cell; // Allow correction without a separate clear control.
      return true;
    }
    if (placed.containsKey(anchor) || placed.containsKey(cell)) {
      return false;
    }
    placed[anchor!] = cell;
    placed[cell] = anchor!;
    anchor = null;
    moves++;
    if (roundSolved) {
      round++;
      _newRound();
    }
    return true;
  }
}
