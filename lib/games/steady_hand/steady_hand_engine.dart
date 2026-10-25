import 'dart:math';

class TrailPoint {
  const TrailPoint(this.x, this.y);

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is TrailPoint && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

class SteadyHandRound {
  const SteadyHandRound({
    required this.points,
    required this.halfWidth,
  });

  static const double startX = .08;
  static const double finishX = .92;

  final List<TrailPoint> points;
  final double halfWidth;

  /// Returns the lane center at a normalized horizontal position.
  double centerYAt(double x) {
    final position = ((x - startX) / (finishX - startX) * (points.length - 1))
        .clamp(0.0, (points.length - 1).toDouble())
        .toDouble();
    final left = min(position.floor(), points.length - 2);
    final fraction = position - left;
    return points[left].y + (points[left + 1].y - points[left].y) * fraction;
  }
}

enum TrailMoveResult { ignored, tracking, leftLane }

/// Drag a point from the left gate to the right gate while staying inside a
/// seeded lane. Each round is a valid continuous path through normalized space.
class SteadyHandSession {
  SteadyHandSession({required this.seed, int level = 1}) {
    final random = Random(seed);
    final difficulty =
        (max(0, level - 1) * .0012).clamp(0.0, .035).toDouble();
    rounds = List<SteadyHandRound>.unmodifiable(
      List.generate(roundCount, (index) {
        final halfWidth =
            (.13 - index * .012 - difficulty).clamp(.065, .13).toDouble();
        return _makeRound(random, index, halfWidth);
      }),
    );
  }

  static const int roundCount = 5;
  static const int maxAttemptsPerRound = 3;
  static const int passScore = 4;
  static const double _backtrackTolerance = .04;
  static const double _startTolerance = .09;

  final int seed;
  late final List<SteadyHandRound> rounds;
  int round = 0;
  int completed = 0;
  int mistakes = 0;
  int _attemptsInRound = 0;
  bool active = false;
  double progress = SteadyHandRound.startX;
  TrailPoint? cursor;

  bool get finished => round >= roundCount;
  bool get passed => finished && completed >= passScore;
  double get completion => (progress - SteadyHandRound.startX) /
      (SteadyHandRound.finishX - SteadyHandRound.startX);
  int get attemptsLeft => maxAttemptsPerRound - _attemptsInRound;
  SteadyHandRound get current => rounds[round.clamp(0, roundCount - 1).toInt()];

  /// Starts only from the left gate. Invalid starts leave the session unchanged.
  bool begin(double x, double y) {
    if (finished || active || !x.isFinite || !y.isFinite ||
        x < SteadyHandRound.startX - _startTolerance ||
        x > SteadyHandRound.startX + _startTolerance ||
        y < 0 || y > 1 ||
        (y - current.centerYAt(
                  x.clamp(SteadyHandRound.startX, SteadyHandRound.startX + _startTolerance)
                      .toDouble(),
                ))
                .abs() >
            current.halfWidth) {
      return false;
    }
    active = true;
    progress = x.clamp(SteadyHandRound.startX, SteadyHandRound.finishX).toDouble();
    cursor = TrailPoint(progress, y);
    return true;
  }

  TrailMoveResult move(double x, double y) {
    if (!active || !x.isFinite || !y.isFinite || x < 0 || x > 1 || y < 0 || y > 1 ||
        x < progress - _backtrackTolerance ||
        x > SteadyHandRound.finishX + _startTolerance) {
      return TrailMoveResult.ignored;
    }
    final checkedX =
        x.clamp(SteadyHandRound.startX, SteadyHandRound.finishX).toDouble();
    if ((y - current.centerYAt(checkedX)).abs() > current.halfWidth) {
      _leaveLane();
      return TrailMoveResult.leftLane;
    }
    progress = max(progress, checkedX).toDouble();
    cursor = TrailPoint(checkedX, y);
    return TrailMoveResult.tracking;
  }

  /// Ends the current drag. Incomplete traces count as an attempt and can retry.
  bool end() {
    if (!active) return false;
    active = false;
    if (progress < SteadyHandRound.finishX - .015) {
      _leaveLane();
      return false;
    }
    completed++;
    round++;
    _attemptsInRound = 0;
    progress = SteadyHandRound.startX;
    cursor = null;
    return true;
  }

  void retry() {
    if (finished || active) return;
    progress = SteadyHandRound.startX;
    cursor = null;
  }

  static SteadyHandRound _makeRound(Random random, int index, double halfWidth) {
    const pointCount = 7;
    final amplitude = .12 + index * .025;
    final points = List<TrailPoint>.generate(pointCount, (pointIndex) {
      final x = SteadyHandRound.startX +
          (SteadyHandRound.finishX - SteadyHandRound.startX) *
              pointIndex / (pointCount - 1);
      if (pointIndex == 0 || pointIndex == pointCount - 1) {
        return TrailPoint(x, .5);
      }
      final y = (.5 + (random.nextDouble() * 2 - 1) * amplitude)
          .clamp(.22, .78)
          .toDouble();
      return TrailPoint(x, y);
    });
    return SteadyHandRound(
      points: List<TrailPoint>.unmodifiable(points),
      halfWidth: halfWidth,
    );
  }

  void _leaveLane() {
    active = false;
    mistakes++;
    _attemptsInRound++;
    progress = SteadyHandRound.startX;
    cursor = null;
    if (_attemptsInRound >= maxAttemptsPerRound) {
      round++;
      _attemptsInRound = 0;
    }
  }
}
