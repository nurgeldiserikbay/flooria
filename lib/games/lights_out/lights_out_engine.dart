import 'dart:math';

enum LightMove { changed, completed, ignored }

/// Pressing one light toggles it and its orthogonal neighbours.
class LightsOutEngine {
  LightsOutEngine._(this.level, this.lights);

  static const int side = 5;
  final int level;
  final List<bool> lights;
  int moves = 0;
  bool isCompleted = false;
  int get litCount => lights.where((lit) => lit).length;
  int get score => max(100, 1000 - moves * 20).toInt();

  factory LightsOutEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final random = Random(safe * 65699 + 17);
    final board = List<bool>.filled(side * side, false);
    final scrambleMoves = min(4 + safe, 24).toInt();
    for (var i = 0; i < scrambleMoves; i++) {
      _toggle(board, random.nextInt(side * side));
    }
    if (board.every((lit) => !lit)) _toggle(board, random.nextInt(side * side));
    return LightsOutEngine._(safe, board);
  }

  LightMove press(int cell) {
    if (isCompleted || cell < 0 || cell >= lights.length) return LightMove.ignored;
    _toggle(lights, cell);
    moves++;
    isCompleted = lights.every((lit) => !lit);
    return isCompleted ? LightMove.completed : LightMove.changed;
  }

  static void _toggle(List<bool> board, int cell) {
    final row = cell ~/ side, col = cell % side;
    for (final (dr, dc) in const [(0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)]) {
      final r = row + dr, c = col + dc;
      if (r >= 0 && r < side && c >= 0 && c < side) {
        final index = r * side + c;
        board[index] = !board[index];
      }
    }
  }
}
