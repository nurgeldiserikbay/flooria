import 'dart:math';

/// Color a connected graph using three paints. Adjacent nodes may not match.
/// Every generated round has a known solution; no Flutter dependency.
class MapTintsSession {
  MapTintsSession({required this.seed, this.roundCount = 3})
      : assert(roundCount > 0) {
    _startRound();
  }

  static const int paletteSize = 3;
  final int seed;
  final int roundCount;
  int round = 0;
  int taps = 0;
  int checks = 0;
  int mistakes = 0;

  late int nodeCount;
  late List<(int, int)> edges;
  late List<int> witness;
  late Map<int, int> fixed;
  late List<int?> colors;

  bool get complete => round >= roundCount;
  bool get fullyColored => colors.every((color) => color != null);

  static bool validColoring(
      List<int?> assignment, Iterable<(int, int)> edges) {
    if (assignment.any((color) => color == null || color < 0 ||
        color >= paletteSize)) {
      return false;
    }
    for (final edge in edges) {
      if (assignment[edge.$1] == assignment[edge.$2]) return false;
    }
    return true;
  }

  Set<int> get conflicts {
    final conflicting = <int>{};
    for (final edge in edges) {
      final a = colors[edge.$1], b = colors[edge.$2];
      if (a != null && b != null && a == b) {
        conflicting.add(edge.$1);
        conflicting.add(edge.$2);
      }
    }
    return conflicting;
  }

  bool get solved => !complete && fullyColored &&
      validColoring(colors, edges);

  void _startRound() {
    if (complete) return;
    final random = Random((seed * 65537 + round * 104729) & 0x7fffffff);
    nodeCount = 6 + round;
    final shift = random.nextInt(paletteSize);
    witness = [
      for (var i = 0; i < nodeCount; i++) (i + shift) % paletteSize,
    ];
    // The spine guarantees connectedness, extra chords increase deduction.
    final graph = <(int, int)>[
      for (var i = 0; i < nodeCount - 1; i++) (i, i + 1),
    ];
    final candidates = <(int, int)>[];
    for (var a = 0; a < nodeCount; a++) {
      for (var b = a + 2; b < nodeCount; b++) {
        if (witness[a] != witness[b]) candidates.add((a, b));
      }
    }
    candidates.shuffle(random);
    graph.addAll(candidates.take(2 + round * 2));
    edges = List.unmodifiable(graph);
    final indices = List<int>.generate(nodeCount, (i) => i)..shuffle(random);
    fixed = {
      for (final index in indices.take(round == 0 ? 1 : 2))
        index: witness[index],
    };
    colors = [
      for (var i = 0; i < nodeCount; i++) fixed[i],
    ];
  }

  /// Cycle through blank, coral, teal, lavender. Locked nodes are immutable.
  bool tap(int index) {
    if (complete || index < 0 || index >= nodeCount ||
        fixed.containsKey(index)) {
      return false;
    }
    final current = colors[index];
    colors[index] = current == null
        ? 0
        : current == paletteSize - 1 ? null : current + 1;
    taps++;
    return true;
  }

  /// Wrong submissions preserve the current coloring for correction.
  bool check() {
    if (complete || !fullyColored) return false;
    checks++;
    if (!solved) {
      mistakes++;
      return false;
    }
    round++;
    _startRound();
    return true;
  }
}
