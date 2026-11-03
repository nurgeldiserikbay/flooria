import 'dart:math';

enum ShadowMove { moved, switched, completed, blocked, ignored }

/// Walk a dark bridge that appears on alternating cells as the lamp turns.
class ShadowBridgeEngine {
  ShadowBridgeEngine._(this.level, this.bridgeCells, this.walls, this.position);
  static const side = 5;
  final int level;
  final Set<int> bridgeCells;
  final Set<int> walls;
  int position;
  int lightPhase = 0;
  int moves = 0;
  bool isCompleted = false;
  bool isFailed = false;
  int get score => max(100, 1000 - moves * 38).toInt();
  static const goal = 2;
  static const voidCells = {1, 2, 3, 6, 7, 8, 11, 12, 13};

  factory ShadowBridgeEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final engine = ShadowBridgeEngine._(safe,
      {1, 2, 3, 6, 7, 8, 11, 12, 13},
      <int>{}, 10);
    engine.lightPhase = safe.isEven ? 1 : 0;
    return engine;
  }

  bool get canStand => !voidCells.contains(position) || _shadowAt(position);
  bool _shadowAt(int cell) => bridgeCells.contains(cell) &&
      ((lightPhase == 0 && cell.isEven) || (lightPhase == 1 && cell.isOdd));

  ShadowMove turnLamp() {
    if (isCompleted || isFailed) return ShadowMove.ignored;
    lightPhase = 1 - lightPhase;
    moves++;
    if (!canStand) return ShadowMove.blocked;
    return ShadowMove.switched;
  }

  ShadowMove step(int dr, int dc) {
    if (isCompleted || isFailed) return ShadowMove.ignored;
    final row = position ~/ side + dr, col = position % side + dc;
    if (row < 0 || row >= side || col < 0 || col >= side) return ShadowMove.blocked;
    final next = row * side + col;
    if (walls.contains(next) || (voidCells.contains(next) && !_shadowAt(next))) return ShadowMove.blocked;
    position = next;
    moves++;
    isCompleted = position == goal;
    return isCompleted ? ShadowMove.completed : ShadowMove.moved;
  }
}
