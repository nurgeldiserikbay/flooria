import 'dart:math';

enum TargetAction { hit, completed, advanced, missed, failed, ignored }

/// Tap each highlighted target before it moves; three misses end the round.
class WhackTargetEngine {
  WhackTargetEngine._(this.level, this.goal, this.windowMilliseconds, this._random) {
    _nextTarget();
  }

  final int level;
  final int goal;
  final int windowMilliseconds;
  final Random _random;
  int target = -1;
  int hits = 0;
  int misses = 0;
  bool hitThisWindow = false;
  bool isCompleted = false;
  bool isFailed = false;
  int get score => max(100, 1000 - misses * 140 + hits * 15).toInt();

  factory WhackTargetEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    return WhackTargetEngine._(safe,
      min(6 + (safe - 1) ~/ 6, 14).toInt(),
      max(420, 1150 - (safe - 1) * 7).toInt(),
      Random(safe * 6151 + 71));
  }

  TargetAction tap(int cell) {
    if (isCompleted || isFailed || cell != target || hitThisWindow) {
      return TargetAction.ignored;
    }
    hitThisWindow = true;
    hits++;
    if (hits >= goal) {
      isCompleted = true;
      return TargetAction.completed;
    }
    return TargetAction.hit;
  }

  TargetAction elapse() {
    if (isCompleted || isFailed) return TargetAction.ignored;
    final wasHit = hitThisWindow;
    if (!wasHit) {
      misses++;
      if (misses >= 3) {
        isFailed = true;
        return TargetAction.failed;
      }
    }
    _nextTarget();
    return wasHit ? TargetAction.advanced : TargetAction.missed;
  }

  void _nextTarget() {
    final previous = target;
    do {
      target = _random.nextInt(9);
    } while (target == previous);
    hitThisWindow = false;
  }
}
