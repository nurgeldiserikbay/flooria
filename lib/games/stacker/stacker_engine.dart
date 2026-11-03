import 'dart:math';

enum StackDrop { placed, completed, failed, ignored }

class StackLayer {
  const StackLayer({required this.left, required this.width, required this.colorIndex});
  final double left;
  final double width;
  final int colorIndex;
}

/// Time each drop to keep the moving block aligned with the stack.
class StackerEngine {
  StackerEngine._(this.level, this.targetLayers, this.speed)
      : layers = [const StackLayer(left: 0, width: 1, colorIndex: 0)];

  final int level;
  final int targetLayers;
  final double speed;
  final List<StackLayer> layers;
  double movingLeft = 0;
  double _direction = 1;
  bool isCompleted = false;
  bool isFailed = false;
  int get placed => layers.length - 1;
  int get score => max(100, 1000 - (1 - layers.last.width) * 500).toInt();

  factory StackerEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    return StackerEngine._(safe,
      min(8 + (safe - 1) ~/ 6, 18).toInt(),
      min(.027, .010 + (safe - 1) * .00016).toDouble());
  }

  bool tick() {
    if (isCompleted || isFailed) return false;
    final maxLeft = 1 - layers.last.width;
    movingLeft += speed * _direction;
    if (movingLeft <= 0) { movingLeft = 0; _direction = 1; }
    if (movingLeft >= maxLeft) { movingLeft = maxLeft; _direction = -1; }
    return true;
  }

  StackDrop drop() {
    if (isCompleted || isFailed) return StackDrop.ignored;
    final base = layers.last;
    final left = max(base.left, movingLeft).toDouble();
    final right = min(base.left + base.width, movingLeft + base.width).toDouble();
    final overlap = right - left;
    if (overlap < .035) {
      isFailed = true;
      return StackDrop.failed;
    }
    layers.add(StackLayer(left: left, width: overlap,
      colorIndex: layers.length % 7));
    if (placed >= targetLayers) {
      isCompleted = true;
      return StackDrop.completed;
    }
    movingLeft = _direction > 0 ? 0 : 1 - overlap;
    return StackDrop.placed;
  }
}
