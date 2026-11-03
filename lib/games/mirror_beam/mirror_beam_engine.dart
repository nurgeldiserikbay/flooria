import 'dart:math';

enum MirrorBeamResult { changed, completed, ignored }

/// Route a beam through two rotatable mirrors into the receiver.
class MirrorBeamEngine {
  MirrorBeamEngine._(this.level, this.mirrors);
  static const side = 5;
  static const emitter = 20;
  static const receiver = 14;
  final int level;
  final Map<int, bool> mirrors; // true is /, false is \\
  int rotations = 0;
  bool isCompleted = false;
  int get score => max(100, 1000 - rotations * 90).toInt();

  factory MirrorBeamEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    return MirrorBeamEngine._(safe, {22: false, 12: safe % 3 == 0 ? false : true});
  }

  List<int> get beamCells {
    var row = 4, col = 0, dr = 0, dc = 1;
    final cells = <int>[];
    final visited = <String>{};
    for (var step = 0; step < side * side * 2; step++) {
      row += dr;
      col += dc;
      if (row < 0 || row >= side || col < 0 || col >= side) break;
      final cell = row * side + col;
      cells.add(cell);
      if (cell == receiver) break;
      final state = '$cell:$dr:$dc';
      if (!visited.add(state)) break;
      final slash = mirrors[cell];
      if (slash != null) {
        final oldDr = dr;
        dr = slash ? -dc : dc;
        dc = slash ? -oldDr : oldDr;
      }
    }
    return cells;
  }

  MirrorBeamResult rotate(int cell) {
    if (isCompleted || !mirrors.containsKey(cell)) return MirrorBeamResult.ignored;
    mirrors[cell] = !mirrors[cell]!;
    rotations++;
    if (beamCells.contains(receiver)) {
      isCompleted = true;
      return MirrorBeamResult.completed;
    }
    return MirrorBeamResult.changed;
  }
}
