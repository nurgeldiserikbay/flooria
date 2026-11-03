import 'dart:math';

enum CatchKind { fruit, bomb }
enum CatchMove { moved, ignored }
enum CatchTick { updated, completed, failed, ignored }

class FallingToken {
  const FallingToken({required this.lane, required this.row, required this.kind});
  final int lane;
  final int row;
  final CatchKind kind;
  FallingToken atRow(int nextRow) => FallingToken(lane: lane, row: nextRow, kind: kind);
}

/// Move the basket between lanes to collect fruit and avoid falling bombs.
class ColorCatcherEngine {
  ColorCatcherEngine._(this.level, this.goal, this.intervalMilliseconds,
      this._random, this._bombChance);

  static const int lanes = 5;
  static const int rows = 7;
  final int level;
  final int goal;
  final int intervalMilliseconds;
  final Random _random;
  final int _bombChance;
  final List<FallingToken> tokens = [];
  int basketLane = lanes ~/ 2;
  int caught = 0;
  int strikes = 0;
  bool isCompleted = false;
  bool isFailed = false;
  int get score => max(100, caught * 100 - strikes * 80).toInt();

  factory ColorCatcherEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    return ColorCatcherEngine._(
      safe,
      min(8 + (safe - 1) ~/ 10, 15).toInt(),
      max(260, 760 - (safe - 1) * 5).toInt(),
      Random(safe * 47507 + 83),
      min(15 + (safe - 1) ~/ 3, 35).toInt(),
    );
  }

  CatchMove moveBasket(int delta) {
    if (isCompleted || isFailed || delta == 0) return CatchMove.ignored;
    final next = (basketLane + delta).clamp(0, lanes - 1).toInt();
    if (next == basketLane) return CatchMove.ignored;
    basketLane = next;
    return CatchMove.moved;
  }

  CatchTick tick() {
    if (isCompleted || isFailed) return CatchTick.ignored;
    final remaining = <FallingToken>[];
    for (final token in tokens) {
      final nextRow = token.row + 1;
      if (nextRow >= rows - 1) {
        if (token.lane == basketLane) {
          if (token.kind == CatchKind.fruit) {
            caught++;
          } else {
            strikes++;
          }
        }
      } else {
        remaining.add(token.atRow(nextRow));
      }
    }
    tokens
      ..clear()
      ..addAll(remaining);
    if (caught >= goal) {
      isCompleted = true;
      return CatchTick.completed;
    }
    if (strikes >= 3) {
      isFailed = true;
      return CatchTick.failed;
    }
    final kind = _random.nextInt(100) < _bombChance ? CatchKind.bomb : CatchKind.fruit;
    tokens.add(FallingToken(lane: _random.nextInt(lanes), row: 0, kind: kind));
    return CatchTick.updated;
  }
}
