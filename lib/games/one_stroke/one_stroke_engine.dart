import 'dart:math';

/// Trace every graph edge once. All generated graphs have an Euler trail.
class StrokeEdge {
  const StrokeEdge(this.a, this.b);
  final int a;
  final int b;
  bool connects(int x, int y) => (a == x && b == y) || (a == y && b == x);
}

class OneStrokeSession {
  OneStrokeSession({required this.seed, this.roundCount = 3})
      : assert(roundCount > 0) {
    _start();
  }

  final int seed;
  final int roundCount;
  int round = 0;
  int moves = 0;
  int totalMoves = 0;
  int invalidMoves = 0;
  late int nodeCount;
  late List<StrokeEdge> edges;
  late int current;
  late int startingNode;
  final Set<int> visited = {};
  final List<(int, int)> history = [];

  bool get complete => round >= roundCount;
  bool get roundSolved => !complete && visited.length == edges.length;
  int get remaining => complete ? 0 : edges.length - visited.length;

  static bool _neighbors(int a, int b, int n) =>
      (a - b).abs() == 1 || (a == 0 && b == n - 1) ||
      (b == 0 && a == n - 1);

  void _start() {
    if (complete) return;
    final random = Random((seed * 65537 + round * 7919) & 0x7fffffff);
    nodeCount = 5 + round;
    final graph = <StrokeEdge>[
      for (var i = 0; i < nodeCount; i++)
        StrokeEdge(i, (i + 1) % nodeCount),
    ];
    final chords = <(int, int)>[];
    for (var a = 0; a < nodeCount; a++) {
      for (var b = a + 1; b < nodeCount; b++) {
        if (!_neighbors(a, b, nodeCount)) chords.add((a, b));
      }
    }
    chords.shuffle(random);
    if (round < 2) {
      final chord = chords.first;
      graph.add(StrokeEdge(chord.$1, chord.$2));
      startingNode = chord.$1;
    } else {
      final first = chords.first;
      final second = chords.firstWhere((c) =>
          c != first && (c.$1 == first.$1 || c.$2 == first.$1));
      graph.add(StrokeEdge(first.$1, first.$2));
      graph.add(StrokeEdge(second.$1, second.$2));
      startingNode = first.$2;
    }
    edges = List.unmodifiable(graph);
    current = startingNode;
    visited.clear();
    history.clear();
    moves = 0;
    if (solution == null) throw StateError('Missing Euler trail');
  }

  /// Independent depth-first verifier, at most 9 edges per round.
  List<int>? get solution {
    final taken = <int>{};
    final route = <int>[current];
    bool search(int at) {
      if (taken.length == edges.length) return true;
      for (var i = 0; i < edges.length; i++) {
        if (taken.contains(i) || visited.contains(i)) continue;
        final edge = edges[i];
        final next = edge.a == at ? edge.b : edge.b == at ? edge.a : -1;
        if (next < 0) continue;
        taken.add(i);
        route.add(next);
        if (search(next)) return true;
        route.removeLast();
        taken.remove(i);
      }
      return false;
    }
    return search(current) ? route : null;
  }

  /// Tap an adjacent node via an unused edge; invalid actions are inert.
  bool move(int node) {
    if (complete || node < 0 || node >= nodeCount) return false;
    var edgeIndex = -1;
    for (var i = 0; i < edges.length; i++) {
      if (!visited.contains(i) && edges[i].connects(current, node)) {
        edgeIndex = i;
        break;
      }
    }
    if (edgeIndex < 0) {
      invalidMoves++;
      return false;
    }
    history.add((current, edgeIndex));
    visited.add(edgeIndex);
    current = node;
    moves++;
    totalMoves++;
    if (roundSolved) {
      round++;
      _start();
    }
    return true;
  }

  bool undo() {
    if (complete || history.isEmpty) return false;
    final previous = history.removeLast();
    visited.remove(previous.$2);
    current = previous.$1;
    moves--;
    totalMoves--;
    return true;
  }
}
