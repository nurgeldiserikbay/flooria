import 'dart:math';

enum MagnetDirection { up, right, down, left }
enum MagnetMove { moved, completed, blocked, ignored }

/// A pulse pushes the charged core one cell; metal plates amplify the pulse.
class MagneticRoomEngine {
  MagneticRoomEngine._(this.level, this.walls, this.metal, this.position, this.goal);
  static const side = 6;
  final int level;
  final Set<int> walls;
  final Set<int> metal;
  final int goal;
  int position;
  int pulses = 0;
  bool isCompleted = false;
  int get score => max(100, 1000 - pulses * 35).toInt();

  factory MagneticRoomEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final walls = <int>{7, 10, 19, 22, 24, 25, 28, 18, 12, 6};
    if (safe > 2) walls.addAll([9, 27]);
    return MagneticRoomEngine._(safe, walls, {14, 15, 20, 21, 32}, 30, 5);
  }

  MagnetMove pulse(MagnetDirection direction) {
    if (isCompleted) return MagnetMove.ignored;
    final (dr, dc) = switch (direction) {
      MagnetDirection.up => (-1, 0), MagnetDirection.right => (0, 1),
      MagnetDirection.down => (1, 0), MagnetDirection.left => (0, -1),
    };
    final steps = metal.contains(position) ? 2 : 1;
    var row = position ~/ side, col = position % side;
    var moved = false;
    for (var i = 0; i < steps; i++) {
      final nr = row + dr, nc = col + dc;
      if (nr < 0 || nr >= side || nc < 0 || nc >= side || walls.contains(nr * side + nc)) break;
      row = nr; col = nc; moved = true;
    }
    if (!moved) return MagnetMove.blocked;
    position = row * side + col;
    pulses++;
    isCompleted = position == goal;
    return isCompleted ? MagnetMove.completed : MagnetMove.moved;
  }
}
