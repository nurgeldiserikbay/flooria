import 'dart:math';

/// Disconnect the two terminals by removing the fewest graph edges.
/// The graph is small enough to determine optimal cuts by exhaustive search.
class BridgeCutSession {
  BridgeCutSession({required this.seed, this.roundCount = 3})
      : assert(roundCount > 0) {
    _newRound();
  }

  final int seed;
  final int roundCount;
  int round = 0;
  int moves = 0;
  int mistakes = 0;
  int checks = 0;
  late int nodes;
  late List<(int, int)> edges;
  late Set<int> optimalCut;
  final Set<int> removed = {};

  bool get complete => round >= roundCount;
  int get remaining => optimalCut.length - removed.length;
  int get budget => optimalCut.length;

  static bool connected(int nodeCount, List<(int, int)> edges,
      Set<int> removed, int start, int goal) {
    if (nodeCount < 2 || start < 0 || goal < 0 ||
        start >= nodeCount || goal >= nodeCount) {
      return false;
    }
    final reached = <int>{start};
    final queue = <int>[start];
    for (var i = 0; i < queue.length; i++) {
      final current = queue[i];
      for (var j = 0; j < edges.length; j++) {
        if (removed.contains(j)) continue;
        final edge = edges[j];
        final neighbor = edge.$1 == current ? edge.$2
            : edge.$2 == current ? edge.$1 : -1;
        if (neighbor >= 0 && reached.add(neighbor)) queue.add(neighbor);
      }
    }
    return reached.contains(goal);
  }

  static Set<int>? minimumCut(
      int nodeCount, List<(int, int)> edges, int start, int goal) {
    if (!connected(nodeCount, edges, {}, start, goal)) return null;
    final total = 1 << edges.length;
    Set<int>? best;
    for (var mask = 1; mask < total; mask++) {
      final count = _popcount(mask);
      if (best != null && count >= best.length) continue;
      final cut = <int>{
        for (var i = 0; i < edges.length; i++)
          if ((mask & (1 << i)) != 0) i,
      };
      if (!connected(nodeCount, edges, cut, start, goal)) best = cut;
    }
    return best;
  }

  static int _popcount(int value) {
    var number = value;
    var count = 0;
    while (number != 0) {
      count += number & 1;
      number >>= 1;
    }
    return count;
  }

  void _newRound() {
    if (complete) return;
    final random = Random((seed * 65537 + round * 7919) & 0x7fffffff);
    nodes = 5 + round;
    // The spine ensures connectedness. Extra edges increase the cut size.
    final links = <(int, int)>[
      for (var i = 0; i < nodes - 1; i++) (i, i + 1),
    ];
    final extras = <(int, int)>[];
    for (var i = 0; i < nodes; i++) {
      for (var j = i + 2; j < nodes; j++) {
        extras.add((i, j));
      }
    }
    extras.shuffle(random);
    links.addAll(extras.take(2 + round));
    links.shuffle(random);
    edges = List.unmodifiable(links);
    final best = minimumCut(nodes, edges, 0, nodes - 1);
    if (best == null || best.isEmpty) {
      throw StateError('Generated graph lacks a finite cut');
    }
    optimalCut = Set.unmodifiable(best);
    removed.clear();
  }

  bool get disconnected => !complete &&
      !connected(nodes, edges, removed, 0, nodes - 1);

  /// Toggle edge removal. A budget prohibits accidentally over-cutting.
  bool toggle(int index) {
    if (complete || index < 0 || index >= edges.length) return false;
    if (removed.contains(index)) {
      removed.remove(index);
    } else {
      if (removed.length >= budget) return false;
      removed.add(index);
    }
    moves++;
    return true;
  }

  bool check() {
    if (complete || removed.isEmpty) return false;
    checks++;
    if (!disconnected || removed.length != budget) {
      mistakes++;
      return false;
    }
    round++;
    _newRound();
    return true;
  }
}
