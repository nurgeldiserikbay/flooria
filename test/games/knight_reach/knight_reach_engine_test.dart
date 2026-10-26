import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/knight_reach/knight_reach_engine.dart';

void main() {
  test('every seeded round has a safe shortest solution', () {
    for (var seed = -30; seed < 160; seed++) {
      final game = KnightReachSession(seed: seed);
      final replay = KnightReachSession(seed: seed);
      for (var round = 0; round < 3; round++) {
        expect(game.start, replay.start);
        expect(game.goal, replay.goal);
        expect(game.blocked, replay.blocked);
        expect(game.position, game.start);
        final path = KnightReachSession.shortestPath(
            game.start, game.goal, game.blocked);
        expect(path, isNotNull);
        expect(path!.length - 1, game.optimalMoves);
        expect(path.length, greaterThanOrEqualTo(3));
        expect(game.blocked.contains(game.goal), false);
        for (final cell in path.skip(1)) {
          expect(game.legalMoves.contains(cell), true);
          expect(game.move(cell), true);
          expect(replay.move(cell), true);
        }
        expect(game.round, round + 1, reason: 'seed=$seed round=$round');
      }
      expect(game.complete, true);
      expect(game.legalMoves, isEmpty);
      expect(game.move(0), false);
      expect(game.invalidMoves, 0);
    }
  });

  test('knight geometry never wraps around rows or accepts other hops', () {
    expect(KnightReachSession.isKnightMove(0, 7), true);
    expect(KnightReachSession.isKnightMove(0, 11), true);
    expect(KnightReachSession.isKnightMove(0, 4), false);
    expect(KnightReachSession.isKnightMove(4, 5), false);
    expect(KnightReachSession.isKnightMove(-1, 7), false);
    expect(KnightReachSession.isKnightMove(0, 25), false);
  });

  test('invalid coordinates and obstacles cannot mutate the board', () {
    final game = KnightReachSession(seed: 8);
    final before = game.position;
    expect(game.move(-1), false);
    expect(game.move(25), false);
    expect(game.move(before), false);
    expect(game.moves, 0);
    expect(game.totalMoves, 0);
    expect(game.position, before);
    expect(KnightReachSession.shortestPath(0, 2, {0}), null);
  });

  test('shortest path handles identical, blocked and disconnected cells', () {
    expect(KnightReachSession.shortestPath(0, 0, {}), [0]);
    expect(KnightReachSession.shortestPath(0, 2, {2}), null);
    expect(KnightReachSession.shortestPath(0, 24,
        {7, 11}), null);
  });
}
