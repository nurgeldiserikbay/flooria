import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/bridge_islands/bridge_islands_engine.dart';

void main() {
  test('seeded stages have valid connected witness and reproducible clues', () {
    for (var seed = -30; seed < 170; seed++) {
      final game = BridgeIslandsSession(seed: seed);
      final replay = BridgeIslandsSession(seed: seed);
      for (var stage = 0; stage < 3; stage++) {
        expect(game.target, replay.target);
        expect(game.witness, replay.witness);
        expect(BridgeIslandsSession.connected(game.witness), true);
        expect(BridgeIslandsSession.degrees(game.witness), game.target);
        expect(game.solved, false);
        for (var edge = 0; edge < game.witness.length; edge++) {
          for (var count = 0; count < game.witness[edge]; count++) {
            expect(game.tap(edge), true);
            expect(replay.tap(edge), true);
          }
        }
        expect(game.solved, true);
        expect(game.check(), true);
        expect(replay.check(), true);
        expect(game.round, stage + 1, reason: 'seed $seed stage $stage');
      }
      expect(game.complete, true);
      expect(game.tap(0), false);
      expect(game.check(), false);
    }
  });

  test('tap cycles absent, one, two, absent', () {
    final game = BridgeIslandsSession(seed: 2);
    expect(game.tap(0), true);
    expect(game.bridges[0], 1);
    expect(game.tap(0), true);
    expect(game.bridges[0], 2);
    expect(game.tap(0), true);
    expect(game.bridges[0], 0);
    expect(game.taps, 3);
  });

  test('invalid operations leave counts untouched', () {
    final game = BridgeIslandsSession(seed: 12);
    expect(game.tap(-1), false);
    expect(game.tap(7), false);
    expect(game.taps, 0);
    expect(game.bridges.every((count) => count == 0), true);
    expect(() => BridgeIslandsSession.degrees([1, 2]), throwsArgumentError);
    expect(game.check(), false);
    expect(game.wrongChecks, 1);
    expect(game.round, 0);
  });

  test('matching counts without connectivity is not a winning bridge map', () {
    expect(BridgeIslandsSession.connected(List.filled(7, 0)), false);
    expect(BridgeIslandsSession.connected([1, 0, 1, 0, 0, 0, 0]),
        false);
  });
}
