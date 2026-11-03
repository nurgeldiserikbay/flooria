import 'dart:math';

enum SnakeDirection { up, right, down, left }
enum SnakeStep { moved, ateFood, completed, crashed, ignored }

/// Grid-based snake rules. The first cell in [body] is always the head.
class SnakeEngine {
  SnakeEngine._({required this.level, required this.size, required this.goalLength,
    required int seed}) : _random = Random(seed) {
    final row = size ~/ 2;
    final col = size ~/ 2;
    _body = [row * size + col, row * size + col - 1, row * size + col - 2];
    _spawnFood();
  }

  final int level;
  final int size;
  final int goalLength;
  final Random _random;
  late List<int> _body;
  List<int> get body => List.unmodifiable(_body);
  SnakeDirection direction = SnakeDirection.right;
  late int food;
  bool isCompleted = false;
  bool isFailed = false;

  int get length => _body.length;
  int get score => max(0, (length - 3) * 100).toInt();
  int get stepMilliseconds => max(120, 310 - (level - 1) * 2).toInt();

  factory SnakeEngine.forLevel(int level, {int? seed}) {
    final safeLevel = max(1, level).toInt();
    final goal = min(6 + safeLevel ~/ 4, 22).toInt();
    return SnakeEngine._(level: safeLevel, size: 12, goalLength: goal,
      seed: seed ?? safeLevel * 3571 + 23);
  }

  bool turn(SnakeDirection next) {
    final opposite = switch (direction) {
      SnakeDirection.up => SnakeDirection.down,
      SnakeDirection.right => SnakeDirection.left,
      SnakeDirection.down => SnakeDirection.up,
      SnakeDirection.left => SnakeDirection.right,
    };
    if (next == opposite || isFailed || isCompleted) return false;
    direction = next;
    return true;
  }

  SnakeStep step() {
    if (isFailed || isCompleted) return SnakeStep.ignored;
    final head = _body.first;
    final row = head ~/ size;
    final col = head % size;
    final next = switch (direction) {
      SnakeDirection.up => row == 0 ? -1 : head - size,
      SnakeDirection.right => col == size - 1 ? -1 : head + 1,
      SnakeDirection.down => row == size - 1 ? -1 : head + size,
      SnakeDirection.left => col == 0 ? -1 : head - 1,
    };
    if (next < 0) {
      isFailed = true;
      return SnakeStep.crashed;
    }
    final eating = next == food;
    final collisionBody = eating ? _body : _body.take(_body.length - 1);
    if (collisionBody.contains(next)) {
      isFailed = true;
      return SnakeStep.crashed;
    }
    _body = [next, ..._body];
    if (!eating) _body.removeLast();
    if (eating) {
      if (_body.length >= goalLength) {
        isCompleted = true;
        return SnakeStep.completed;
      }
      _spawnFood();
      return SnakeStep.ateFood;
    }
    return SnakeStep.moved;
  }

  void _spawnFood() {
    final free = [for (var i = 0; i < size * size; i++) if (!_body.contains(i)) i];
    if (free.isEmpty) {
      isCompleted = true;
      food = -1;
      return;
    }
    food = free[_random.nextInt(free.length)];
  }
}
