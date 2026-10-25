import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/bridge_cut/bridge_cut_engine.dart';

void main() {
  test('every seeded round has a minimal disconnecting cut', () {
    for (var seed = -20; seed < 130; seed++) {
      final game = BridgeCutSession(seed: seed);
      final replay = BridgeCutSession(seed: seed);
      for (var stage = 0; stage < 3; stage++) {
        expect(game.edges, replay.edges);
        expect(game.optimalCut, replay.optimalCut);
        expect(game.nodes, 5 + stage);
        expect(BridgeCutSession.connected(
          game.nodes, game.edges, {}, 0, game.nodes - 1), true);
        expect(BridgeCutSession.connected(game.nodes,
          game.edges, game.optimalCut, 0, game.nodes - 1), false);
        for (var index = 0; index < game.edges.length; index++) {
          if (game.optimalCut.contains(index)) continue;
          // Subsets smaller by one than the optimum cannot disconnect.
          for (final deleted in game.optimalCut) {
            final subset = {...game.optimalCut}..remove(deleted);
            expect(BridgeCutSession.connected(game.nodes, game.edges,
              subset, 0, game.nodes - 1), true);
          }
          break;
        }
        for (final index in game.optimalCut) {
          expect(game.toggle(index), true);
          expect(replay.toggle(index), true);
        }
        expect(game.disconnected, true);
        expect(game.check(), true);
        expect(replay.check(), true);
        expect(game.round, stage + 1);
      }
      expect(game.complete, true);
      expect(game.toggle(0), false);
      expect(game.check(), false);
    }
  });

  test('out of range and over-budget cuts never mutate', () {
    final game = BridgeCutSession(seed: 12);
    expect(game.toggle(-1), false);
    expect(game.toggle(game.edges.length), false);
    expect(game.moves, 0);
    final initial = game.budget;
    for (var i = 0; i < initial; i++) {
      expect(game.toggle(i), true);
    }
    expect(game.removed.length, initial);
    expect(game.toggle(initial), false);
    expect(game.removed.length, initial);
    expect(game.moves, initial);
    expect(game.toggle(0), true);
    expect(game.removed.length, initial - 1);
  });

  test('wrong check preserves selected edges for correction', () {
    final game = BridgeCutSession(seed: 4);
    final wrong = List<int>.generate(game.edges.length, (i) => i)
      .firstWhere((i) => !game.optimalCut.contains(i));
    game.toggle(wrong);
    expect(game.check(), false);
    expect(game.round, 0);
    expect(game.mistakes, 1);
    expect(game.removed, {wrong});
  });

  test('unconnected and invalid graphs have no minimum cut', () {
    expect(BridgeCutSession.minimumCut(3, [(0, 1)], 0, 2), null);
    expect(BridgeCutSession.connected(2, [(0, 1)], {}, -1, 1), false);
  });
}
