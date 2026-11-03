import 'dart:math';

enum OrbitAction { clockwise, counterClockwise, switchLane }
enum OrbitMove { moved, collected, completed, hitHazard, ignored }

/// Steer between two orbital lanes to collect all stars and dodge meteors.
class OrbitCatchEngine {
  OrbitCatchEngine._(this.level, this.stars, this.hazards);
  static const sectors = 12;
  final int level;
  final Set<String> stars;
  final Set<String> hazards;
  final Set<String> collected = {};
  int sector = 0;
  int lane = 0;
  int moves = 0;
  bool isCompleted = false;
  bool isFailed = false;
  int get score => max(100, 1000 - moves * 28).toInt();
  String key(int lane, int sector) => '$lane:${sector % sectors}';

  factory OrbitCatchEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final random = Random(safe * 37991 + 19);
    final stars = <String>{};
    final hazards = <String>{};
    final count = min(7, 3 + (safe - 1) ~/ 4).toInt();
    while (stars.length < count) {
      stars.add('${random.nextInt(2)}:${random.nextInt(sectors)}');
    }
    while (hazards.length < min(5, 2 + (safe - 1) ~/ 8) && hazards.length < sectors) {
      final spot = '${random.nextInt(2)}:${random.nextInt(sectors)}';
      if (!stars.contains(spot) && spot != '0:0') hazards.add(spot);
    }
    return OrbitCatchEngine._(safe, stars, hazards);
  }

  OrbitMove act(OrbitAction action) {
    if (isCompleted || isFailed) return OrbitMove.ignored;
    switch (action) {
      case OrbitAction.clockwise: sector = (sector + 1) % sectors;
        break;
      case OrbitAction.counterClockwise: sector = (sector + sectors - 1) % sectors;
        break;
      case OrbitAction.switchLane: lane = 1 - lane;
        break;
    }
    moves++;
    final spot = key(lane, sector);
    if (hazards.contains(spot)) {
      isFailed = true;
      return OrbitMove.hitHazard;
    }
    if (stars.contains(spot)) collected.add(spot);
    isCompleted = collected.length == stars.length;
    if (isCompleted) return OrbitMove.completed;
    return collected.contains(spot) ? OrbitMove.collected : OrbitMove.moved;
  }
}
