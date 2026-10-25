import 'dart:math';

/// Hashiwokakero-inspired island puzzle with six islands on a 2x3 grid.
/// Bridges can have multiplicity 0, 1, or 2. All islands must connect.
class IslandEdge {
  const IslandEdge(this.a, this.b);
  final int a;
  final int b;
}

class BridgeIslandsSession {
  BridgeIslandsSession({required this.seed, this.roundCount = 3})
      : assert(roundCount > 0) {
    _startRound();
  }

  static const islandCount = 6;
  static const edgeList = <IslandEdge>[
    IslandEdge(0, 1), IslandEdge(1, 2),
    IslandEdge(3, 4), IslandEdge(4, 5),
    IslandEdge(0, 3), IslandEdge(1, 4), IslandEdge(2, 5),
  ];

  final int seed;
  final int roundCount;
  int round = 0;
  int taps = 0;
  int wrongChecks = 0;
  int attempts = 0;
  late List<int> target;
  late List<int> witness;
  final List<int> bridges = List.filled(edgeList.length, 0);

  bool get complete => round >= roundCount;

  static List<int> degrees(List<int> counts) {
    if (counts.length != edgeList.length ||
        counts.any((n) => n < 0 || n > 2)) {
      throw ArgumentError('Invalid bridge vector');
    }
    final result = List<int>.filled(islandCount, 0);
    for (var i = 0; i < counts.length; i++) {
      result[edgeList[i].a] += counts[i];
      result[edgeList[i].b] += counts[i];
    }
    return result;
  }

  static bool connected(List<int> counts) {
    if (counts.length != edgeList.length) return false;
    final visited = <int>{0};
    var changed = true;
    while (changed) {
      final before = visited.length;
      for (var i = 0; i < counts.length; i++) {
        if (counts[i] <= 0) continue;
        final edge = edgeList[i];
        if (visited.contains(edge.a)) visited.add(edge.b);
        if (visited.contains(edge.b)) visited.add(edge.a);
      }
      changed = visited.length != before;
    }
    return visited.length == islandCount;
  }

  List<int> get degreeTotals => degrees(bridges);
  bool get solved => !complete &&
      connected(bridges) &&
      _equal(degreeTotals, target);

  static bool _equal(List<int> a, List<int> b) =>
      a.length == b.length &&
      List.generate(a.length, (i) => i).every((i) => a[i] == b[i]);

  void _startRound() {
    if (complete) return;
    final random = Random((seed * 65537 + round * 8191) & 0x7fffffff);
    final order = List<int>.generate(edgeList.length, (i) => i)
      ..shuffle(random);
    final parent = List<int>.generate(islandCount, (i) => i);
    int root(int x) {
      var n = x;
      while (parent[n] != n) {
        n = parent[n];
      }
      return n;
    }

    witness = List.filled(edgeList.length, 0);
    for (final index in order) {
      final edge = edgeList[index];
      final a = root(edge.a), b = root(edge.b);
      if (a == b) continue;
      parent[a] = b;
      witness[index] = 1;
    }
    // Extra bridges increase counting difficulty in later rounds.
    final candidates = order.where((i) => witness[i] == 0).toList();
    for (final i in candidates.take(round)) {
      witness[i] = 1;
    }
    if (round >= 1) {
      final doubled = order.firstWhere((i) => witness[i] == 1);
      witness[doubled] = 2;
    }
    if (round >= 2) {
      final doubled = order.firstWhere((i) => witness[i] == 1);
      witness[doubled] = 2;
    }
    target = degrees(witness);
    for (var i = 0; i < bridges.length; i++) {
      bridges[i] = 0;
    }
  }

  /// Tap an edge to cycle 0 → 1 → 2 → 0 bridges.
  bool tap(int edgeIndex) {
    if (complete || edgeIndex < 0 || edgeIndex >= bridges.length) {
      return false;
    }
    bridges[edgeIndex] = (bridges[edgeIndex] + 1) % 3;
    taps++;
    return true;
  }

  bool check() {
    if (complete) return false;
    attempts++;
    if (!solved) {
      wrongChecks++;
      return false;
    }
    round++;
    _startRound();
    return true;
  }
}
