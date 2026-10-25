import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/river_crossing/river_crossing_engine.dart';

void main() {
  test('every seeded puzzle has a winning BFS route', () {
    for (var seed = -30; seed < 100; seed++) {
      final game = RiverCrossingSession(seed: seed);
      final replay = RiverCrossingSession(seed: seed);
      for (var r = 0; r < 3; r++) {
        expect(game.passengers, replay.passengers);
        expect(game.capacity, replay.capacity);
        expect(game.forbidden, replay.forbidden);
        final path = game.shortestPath();
        expect(path, isNotNull);
        expect(path!.length, game.optimalMoves);
        for (final cargo in path) {
          for (final passenger in cargo) {
            expect(game.toggle(passenger), true);
            expect(replay.toggle(passenger), true);
          }
          expect(game.cross(), true);
          expect(replay.cross(), true);
        }
        expect(game.round, r + 1, reason: 'seed=$seed stage=$r');
      }
      expect(game.complete, true);
      expect(game.cross(), false);
      expect(game.toggle(0), false);
    }
  });

  test('unsafe crossing is rejected without moving the boat', () {
    final game = RiverCrossingSession(seed: 23);
    expect(game.cross(), false); // operator leaves dangerous pair behind
    expect(game.boatBank, 0);
    expect(game.rightMask, 0);
    expect(game.moves, 0);
    expect(game.invalidMoves, 1);
  });

  test('invalid passenger and over-capacity selection do not mutate', () {
    final game = RiverCrossingSession(seed: 5);
    expect(game.toggle(-1), false);
    expect(game.toggle(10), false);
    expect(game.toggle(0), true);
    expect(game.toggle(1), false);
    expect(game.selected, {0});
    expect(game.toggle(0), true);
    expect(game.selected, isEmpty);
    expect(game.moves, 0);
  });

  test('dangerous pairs only matter without the operator', () {
    final game = RiverCrossingSession(seed: 1);
    expect(game.safe(0, 0), true);
    expect(game.safe(0, 1), false);
    final allRight = (1 << game.passengers.length) - 1;
    expect(game.safe(allRight, 1), true);
  });
}
