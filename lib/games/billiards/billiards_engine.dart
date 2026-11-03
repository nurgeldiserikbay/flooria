import 'dart:math';

enum BilliardShot { potted, completed, missed, ignored }
enum BilliardDirection { up, upRight, right, downRight, down, downLeft, left, upLeft }

class BilliardTarget {
  const BilliardTarget(this.number, this.direction);
  final int number;
  final BilliardDirection direction;
}

/// Pocket numbered balls in sequence by choosing the matching bank direction.
class BilliardsEngine {
  BilliardsEngine._(this.level, this.targets, this.maxMisses);

  final int level;
  final List<BilliardTarget> targets;
  final int maxMisses;
  final Set<BilliardDirection> pocketed = {};
  int nextNumber = 1;
  int misses = 0;
  bool isCompleted = false;
  bool get isFailed => !isCompleted && misses >= maxMisses;
  List<BilliardTarget> get remaining =>
      targets.where((ball) => !pocketed.contains(ball.direction)).toList();
  int get score => max(100, 1000 - misses * 160 - (nextNumber - 1) * 25).toInt();

  factory BilliardsEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final random = Random(safe * 23011 + 71);
    final count = min(8, 4 + (safe - 1) ~/ 10).toInt();
    final directions = BilliardDirection.values.toList()..shuffle(random);
    return BilliardsEngine._(safe,
      [for (var i = 0; i < count; i++) BilliardTarget(i + 1, directions[i])],
      max(3, 5 - (safe - 1) ~/ 20).toInt());
  }

  BilliardShot shoot(BilliardDirection direction) {
    if (isCompleted || isFailed) return BilliardShot.ignored;
    BilliardTarget? target;
    for (final ball in targets) {
      if (ball.direction == direction && !pocketed.contains(direction)) {
        target = ball;
        break;
      }
    }
    if (target != null && target.number == nextNumber) {
      pocketed.add(direction);
      nextNumber++;
      if (nextNumber > targets.length) {
        isCompleted = true;
        return BilliardShot.completed;
      }
      return BilliardShot.potted;
    }
    misses++;
    return BilliardShot.missed;
  }
}
