import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/game/floor_engine.dart';

void main() {
  test('alternates game types across tower floors', () {
    const engine = FloorEngine();
    for (var floor = 1; floor < 30; floor++) {
      expect(engine.challengeFor(floor).gameId,
          isNot(engine.challengeFor(floor + 1).gameId));
    }
  });

  test('floor challenge is reproducible', () {
    const engine = FloorEngine();
    expect(engine.challengeFor(12).gameId, engine.challengeFor(12).gameId);
    expect(engine.seedFor(12, 'merge2048'), engine.seedFor(12, 'merge2048'));
  });
}
