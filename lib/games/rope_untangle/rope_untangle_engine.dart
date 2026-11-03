import 'dart:math';

enum RopeMove { moved, completed, ignored }

/// Drag the joints until none of the connecting ropes cross.
class RopeUntangleEngine {
  RopeUntangleEngine._(this.level, this.positions, this.edges) {
    isCompleted = _isSolved();
  }

  final int level;
  final List<Point<double>> positions;
  final List<(int, int)> edges;
  int moves = 0;
  bool isCompleted = false;
  int get crossingCount {
    var count = 0;
    for (var i = 0; i < edges.length; i++) {
      for (var j = i + 1; j < edges.length; j++) {
        final (a, b) = edges[i];
        final (c, d) = edges[j];
        if (a == c || a == d || b == c || b == d) continue;
        if (_cross(positions[a], positions[b], positions[c], positions[d])) count++;
      }
    }
    return count;
  }
  int get score => max(100, 1000 - moves * 12).toInt();

  factory RopeUntangleEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final rimCount = min(5 + (safe - 1) ~/ 12, 10).toInt();
    final random = Random(safe * 8111 + 97);
    final ring = [for (var i = 0; i < rimCount; i++)
      Point<double>(.5 + .34 * cos(2 * pi * i / rimCount),
        .5 + .34 * sin(2 * pi * i / rimCount))];
    var shuffled = List<Point<double>>.of(ring);
    for (var attempt = 0; attempt < 40; attempt++) {
      shuffled = List<Point<double>>.of(ring)..shuffle(random);
      final candidate = [...shuffled, const Point<double>(.5, .5)];
      if (_countCrossings(candidate, _wheelEdges(rimCount)) > 0) break;
    }
    if (_countCrossings([...shuffled, const Point<double>(.5, .5)],
        _wheelEdges(rimCount)) == 0) {
      shuffled = List<Point<double>>.of(ring);
      final first = shuffled[0];
      shuffled[0] = shuffled[2];
      shuffled[2] = first;
    }
    return RopeUntangleEngine._(safe,
      [...shuffled, const Point<double>(.5, .5)], _wheelEdges(rimCount));
  }

  RopeMove moveNode(int node, Point<double> point) {
    if (isCompleted || node < 0 || node >= positions.length) return RopeMove.ignored;
    final clamped = Point<double>(point.x.clamp(.04, .96).toDouble(),
      point.y.clamp(.04, .96).toDouble());
    if (positions[node] == clamped) return RopeMove.ignored;
    positions[node] = clamped;
    moves++;
    isCompleted = _isSolved();
    return isCompleted ? RopeMove.completed : RopeMove.moved;
  }

  bool _isSolved() {
    if (crossingCount > 0) return false;
    for (var i = 0; i < positions.length; i++) {
      for (var j = i + 1; j < positions.length; j++) {
        final dx = positions[i].x - positions[j].x;
        final dy = positions[i].y - positions[j].y;
        if (dx * dx + dy * dy < .055 * .055) return false;
      }
    }
    return true;
  }

  static List<(int, int)> _wheelEdges(int rimCount) => [
    for (var i = 0; i < rimCount; i++) (i, (i + 1) % rimCount),
    for (var i = 0; i < rimCount; i++) (i, rimCount),
  ];

  static int _countCrossings(List<Point<double>> positions,
      List<(int, int)> edges) {
    var count = 0;
    for (var i = 0; i < edges.length; i++) {
      for (var j = i + 1; j < edges.length; j++) {
        final (a, b) = edges[i];
        final (c, d) = edges[j];
        if (a == c || a == d || b == c || b == d) continue;
        if (_cross(positions[a], positions[b], positions[c], positions[d])) count++;
      }
    }
    return count;
  }

  static bool _cross(Point<double> a, Point<double> b,
      Point<double> c, Point<double> d) {
    double orient(Point<double> p, Point<double> q, Point<double> r) =>
      (q.x - p.x) * (r.y - p.y) - (q.y - p.y) * (r.x - p.x);
    final abC = orient(a, b, c), abD = orient(a, b, d);
    final cdA = orient(c, d, a), cdB = orient(c, d, b);
    return abC * abD < 0 && cdA * cdB < 0;
  }
}
