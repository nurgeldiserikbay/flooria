import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/disk_towers/disk_towers_engine.dart';

void main() {
  test('every seeded round has a legal, optimal route', () {
    for (var seed = -20; seed < 140; seed++) {
      final game = DiskTowersSession(seed: seed);
      final replay = DiskTowersSession(seed: seed);
      for (var round = 0; round < 3; round++) {
        expect(game.startPeg, replay.startPeg);
        expect(game.goalPeg, replay.goalPeg);
        expect(game.diskCount, replay.diskCount);
        final path = game.optimalRoute();
        expect(path.length, game.optimalMoves);
        for (final move in path) {
          expect(game.tapPeg(move.$1), true);
          expect(game.tapPeg(move.$2), true);
          expect(replay.tapPeg(move.$1), true);
          expect(replay.tapPeg(move.$2), true);
        }
        expect(game.round, round + 1, reason: 'seed $seed, round $round');
      }
      expect(game.complete, true);
      expect(game.totalMoves, 29);
      expect(game.tapPeg(0), false);
    }
  });

  test('invalid and empty selections cannot move disks', () {
    final game = DiskTowersSession(seed: 3);
    expect(game.tapPeg(-1), false);
    expect(game.tapPeg(3), false);
    final emptyPeg = (game.startPeg + 1) % 3;
    expect(game.tapPeg(emptyPeg), false);
    expect(game.totalMoves, 0);
    expect(game.selectedPeg, null);
    expect(game.tapPeg(game.startPeg), true);
    expect(game.tapPeg(game.startPeg), true);
    expect(game.selectedPeg, null);
    expect(game.totalMoves, 0);
  });

  test('larger disks cannot be placed on a smaller disk', () {
    final game = DiskTowersSession(seed: 6);
    final spare = ({0, 1, 2}..remove(game.startPeg)).first;
    final remaining = ({0, 1, 2}..removeAll({game.startPeg, spare})).single;
    expect(game.tapPeg(game.startPeg), true);
    expect(game.tapPeg(spare), true);
    expect(game.tapPeg(game.startPeg), true);
    expect(game.tapPeg(remaining), true);
    expect(game.tapPeg(remaining), true);
    expect(game.tapPeg(spare), false);
    expect(game.invalidMoves, 1);
    expect(game.selectedPeg, remaining);
    expect(game.pegs[spare], [1]);
    expect(game.pegs[remaining], [2]);
  });

  test('goal is a complete tower, not merely a moved disk', () {
    final game = DiskTowersSession(seed: 9);
    expect(game.remainingDisks, game.diskCount);
    final route = game.optimalRoute();
    for (var i = 0; i < route.length - 1; i++) {
      final move = route[i];
      game.tapPeg(move.$1);
      game.tapPeg(move.$2);
      expect(game.round, 0);
    }
    game.tapPeg(route.last.$1);
    game.tapPeg(route.last.$2);
    expect(game.round, 1);
  });
}
