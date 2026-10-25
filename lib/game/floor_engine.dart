import 'dart:math';

/// Pure Dart tower scheduling. Game modules never depend on floor numbers.
class FloorChallenge {
  final int floor;
  final String gameId;
  final int difficulty;
  const FloorChallenge(this.floor, this.gameId, this.difficulty);
}

class FloorEngine {
  static const gameIds = ['merge2048', 'numberSequence', 'memory'];
  const FloorEngine();

  FloorChallenge challengeFor(int floor) {
    final index = (floor - 1) % gameIds.length;
    return FloorChallenge(floor, gameIds[index], 1 + (floor - 1) ~/ 6);
  }

  int seedFor(int floor, String gameId) =>
      (floor * 104729 + gameId.codeUnits.fold<int>(0, (a, b) => a * 31 + b)) & 0x7fffffff;

  int sequenceAnswer(int floor, int step) {
    final random = Random(seedFor(floor, 'numberSequence'));
    final start = random.nextInt(10) + 1;
    final delta = random.nextInt(4) + 2 + min<int>(5, floor ~/ 15);
    return start + delta * step;
  }
}
