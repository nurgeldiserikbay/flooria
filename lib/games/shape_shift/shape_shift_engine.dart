import 'dart:math';

enum ShiftShape { circle, square, triangle }
enum ShapeShiftResult { correct, wrong, completed, ignored }

/// Change form at each gate to pass its matching opening.
class ShapeShiftEngine {
  ShapeShiftEngine._(this.level, this.gates, this.allowedMistakes);
  final int level;
  final List<ShiftShape> gates;
  final int allowedMistakes;
  int index = 0;
  int mistakes = 0;
  bool isCompleted = false;
  bool get isFailed => !isCompleted && mistakes >= allowedMistakes;
  int get score => max(100, 1000 - mistakes * 180 - index * 18).toInt();
  ShiftShape get current => gates[index];

  factory ShapeShiftEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final random = Random(safe * 29009 + 3);
    final count = min(12, 5 + (safe - 1) ~/ 3).toInt();
    final shapes = ShiftShape.values;
    return ShapeShiftEngine._(safe,
      List.generate(count, (_) => shapes[random.nextInt(shapes.length)]),
      max(2, 4 - (safe - 1) ~/ 15).toInt());
  }

  ShapeShiftResult choose(ShiftShape shape) {
    if (isCompleted || isFailed) return ShapeShiftResult.ignored;
    if (shape != current) {
      mistakes++;
      return isFailed ? ShapeShiftResult.wrong : ShapeShiftResult.wrong;
    }
    index++;
    if (index == gates.length) {
      isCompleted = true;
      return ShapeShiftResult.completed;
    }
    return ShapeShiftResult.correct;
  }
}
