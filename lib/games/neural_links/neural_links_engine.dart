import 'dart:math';

class NeuralPoint {
  const NeuralPoint(this.x, this.y);
  final double x;
  final double y;
}

class NeuralLink {
  const NeuralLink(this.from, this.to);
  final int from;
  final int to;
}

/// Drag neurons until their synapse lines no longer cross. The initial board
/// is a seeded permutation of a known crossing-free layout, so every board is
/// solvable and repeatable from its seed.
class NeuralLinksSession {
  NeuralLinksSession({required this.seed, this.nodeCount = 6})
      : assert(nodeCount >= 5) {
    links = _buildLinks(nodeCount);
    positions = _makeInitialPositions(seed, nodeCount);
    assert(crossingCount > 0);
  }

  final int seed;
  final int nodeCount;
  late final List<NeuralLink> links;
  late List<NeuralPoint> positions;
  int moves = 0;

  bool get finished => crossingCount == 0;

  int get crossingCount {
    var count = 0;
    for (var left = 0; left < links.length; left++) {
      for (var right = left + 1; right < links.length; right++) {
        final first = links[left];
        final second = links[right];
        if (first.from == second.from || first.from == second.to ||
            first.to == second.from || first.to == second.to) {
          continue;
        }
        if (_intersects(
          positions[first.from], positions[first.to],
          positions[second.from], positions[second.to],
        )) {
          count++;
        }
      }
    }
    return count;
  }

  Set<int> get crossingLinkIndices {
    final result = <int>{};
    for (var left = 0; left < links.length; left++) {
      for (var right = left + 1; right < links.length; right++) {
        final first = links[left];
        final second = links[right];
        if (first.from == second.from || first.from == second.to ||
            first.to == second.from || first.to == second.to) {
          continue;
        }
        if (_intersects(
          positions[first.from], positions[first.to],
          positions[second.from], positions[second.to],
        )) {
          result..add(left)..add(right);
        }
      }
    }
    return result;
  }

  bool moveNode(int index, double x, double y) {
    if (finished || index < 0 || index >= nodeCount || !x.isFinite || !y.isFinite) {
      return false;
    }
    final next = NeuralPoint(
      x.clamp(0.04, 0.96).toDouble(),
      y.clamp(0.04, 0.96).toDouble(),
    );
    final current = positions[index];
    if ((current.x - next.x).abs() < 0.001 && (current.y - next.y).abs() < 0.001) {
      return false;
    }
    positions = List<NeuralPoint>.of(positions)..[index] = next;
    moves++;
    return true;
  }

  static List<NeuralLink> _buildLinks(int count) {
    final edges = <NeuralLink>[];
    for (var index = 0; index < count; index++) {
      edges.add(NeuralLink(index, (index + 1) % count));
    }
    // A small fan gives the network a neural-web shape while remaining planar
    // in the known solved layout.
    edges
      ..add(const NeuralLink(0, 2))
      ..add(const NeuralLink(0, 3));
    return List<NeuralLink>.unmodifiable(edges);
  }

  static List<NeuralPoint> _makeInitialPositions(int seed, int count) {
    final random = Random(seed);
    final solved = List<NeuralPoint>.generate(count, (index) {
      final angle = -pi / 2 + 2 * pi * index / count;
      return NeuralPoint(0.5 + 0.37 * cos(angle), 0.5 + 0.37 * sin(angle));
    });
    for (var attempt = 0; attempt < 1000; attempt++) {
      final shuffled = List<NeuralPoint>.of(solved)..shuffle(random);
      if (_countCrossings(shuffled, _buildLinks(count)) > 0) return shuffled;
    }
    final fallback = <NeuralPoint>[
      solved[0], solved[2], solved[1], ...solved.skip(3),
    ];
    return fallback;
  }

  static int _countCrossings(List<NeuralPoint> positions, List<NeuralLink> links) {
    var crossings = 0;
    for (var left = 0; left < links.length; left++) {
      for (var right = left + 1; right < links.length; right++) {
        final a = links[left];
        final b = links[right];
        if (a.from == b.from || a.from == b.to || a.to == b.from || a.to == b.to) continue;
        if (_intersects(positions[a.from], positions[a.to], positions[b.from], positions[b.to])) {
          crossings++;
        }
      }
    }
    return crossings;
  }

  static bool _intersects(NeuralPoint a, NeuralPoint b, NeuralPoint c, NeuralPoint d) {
    const epsilon = 1e-9;
    final abC = _orientation(a, b, c);
    final abD = _orientation(a, b, d);
    final cdA = _orientation(c, d, a);
    final cdB = _orientation(c, d, b);
    final crosses =
        (abC > epsilon && abD < -epsilon || abC < -epsilon && abD > epsilon) &&
        (cdA > epsilon && cdB < -epsilon || cdA < -epsilon && cdB > epsilon);
    if (crosses) return true;
    return abC.abs() <= epsilon && _onSegment(a, b, c, epsilon) ||
        abD.abs() <= epsilon && _onSegment(a, b, d, epsilon) ||
        cdA.abs() <= epsilon && _onSegment(c, d, a, epsilon) ||
        cdB.abs() <= epsilon && _onSegment(c, d, b, epsilon);
  }

  static bool _onSegment(NeuralPoint a, NeuralPoint b, NeuralPoint point, double epsilon) =>
      point.x >= min(a.x, b.x) - epsilon &&
      point.x <= max(a.x, b.x) + epsilon &&
      point.y >= min(a.y, b.y) - epsilon &&
      point.y <= max(a.y, b.y) + epsilon;

  static double _orientation(NeuralPoint a, NeuralPoint b, NeuralPoint c) =>
      (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}
