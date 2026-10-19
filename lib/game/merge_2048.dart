import 'dart:math';

enum MoveDirection { left, right, up, down }

/// UI-free deterministic 2048 rules, reusable in standalone apps.
class Merge2048 {
  final Random random;
  final List<int> cells = List.filled(16, 0);
  int score = 0;
  int moves = 0;

  Merge2048({int? seed}) : random = Random(seed) {
    spawn();
    spawn();
  }

  bool get canMove {
    if (cells.any((v) => v == 0)) return true;
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        final i = r * 4 + c;
        if (c < 3 && cells[i] == cells[i + 1]) return true;
        if (r < 3 && cells[i] == cells[i + 4]) return true;
      }
    }
    return false;
  }

  int get highest => cells.reduce(max);

  void spawn() {
    final empty = <int>[];
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] == 0) empty.add(i);
    }
    if (empty.isEmpty) return;
    cells[empty[random.nextInt(empty.length)]] = random.nextDouble() < .9 ? 2 : 4;
  }

  List<int> _mergeLine(List<int> line) {
    final values = line.where((v) => v != 0).toList();
    final result = <int>[];
    for (var i = 0; i < values.length; i++) {
      if (i + 1 < values.length && values[i] == values[i + 1]) {
        final combined = values[i] * 2;
        score += combined;
        result.add(combined);
        i++;
      } else {
        result.add(values[i]);
      }
    }
    while (result.length < 4) {
      result.add(0);
    }
    return result;
  }

  bool move(MoveDirection direction) {
    final old = List<int>.from(cells);
    for (var index = 0; index < 4; index++) {
      final positions = <int>[];
      for (var offset = 0; offset < 4; offset++) {
        switch (direction) {
          case MoveDirection.left:
            positions.add(index * 4 + offset);
          case MoveDirection.right:
            positions.add(index * 4 + 3 - offset);
          case MoveDirection.up:
            positions.add(offset * 4 + index);
          case MoveDirection.down:
            positions.add((3 - offset) * 4 + index);
        }
      }
      final merged = _mergeLine(positions.map((p) => cells[p]).toList());
      for (var i = 0; i < 4; i++) {
        cells[positions[i]] = merged[i];
      }
    }
    if (_same(old, cells)) return false;
    moves++;
    spawn();
    return true;
  }

  bool _same(List<int> a, List<int> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
