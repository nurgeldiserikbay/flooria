import 'dart:math';

enum StopResult { hit, early, late, completed, ignored }

/// Three target-time trials. Timing error is recorded explicitly as precision.
class PrecisionStopEngine {
  PrecisionStopEngine(this.level) {
    final shift = ((level - 1) % 7) * .07;
    targets = [1.25 + shift, 1.85 + shift, 2.45 + shift];
  }

  final int level;
  late final List<double> targets;
  int round = 0;
  int misses = 0;
  double totalError = 0;
  bool isCompleted = false;

  double get targetSeconds => targets[min(round, targets.length - 1)];
  double get tolerance => max(.08, .24 - (level - 1) * .0015);
  int get score => max(100, 1000 - totalError * 220 - misses * 25).toInt();
  int get precisionMetric =>
      (100 - totalError * 85 - misses * 8).clamp(0, 100).toInt();

  StopResult stopAt(double elapsedSeconds) {
    if (isCompleted || elapsedSeconds < 0) return StopResult.ignored;
    final difference = elapsedSeconds - targetSeconds;
    final error = difference.abs();
    if (error <= tolerance) {
      totalError += error;
      round++;
      if (round >= targets.length) {
        isCompleted = true;
        return StopResult.completed;
      }
      return StopResult.hit;
    }
    misses++;
    return difference < 0 ? StopResult.early : StopResult.late;
  }
}
