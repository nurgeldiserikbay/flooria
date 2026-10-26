import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/one_stroke/one_stroke_engine.dart';

void main() {
  test('all generated graphs admit edge-exact Euler trails', () {
    for (var seed = -30; seed < 160; seed++) {
      final game = OneStrokeSession(seed: seed);
      final duplicate = OneStrokeSession(seed: seed);
      for (var stage = 0; stage < 3; stage++) {
        expect(game.nodeCount, 5 + stage);
        expect(game.startingNode, duplicate.startingNode);
        expect(game.edges.map((e) => '${e.a}:${e.b}').toList(),
            duplicate.edges.map((e) => '${e.a}:${e.b}').toList());
        final path = game.solution;
        expect(path, isNotNull);
        expect(path!.length, game.edges.length + 1);
        for (var i = 1; i < path.length; i++) {
          expect(game.move(path[i]), true);
          expect(duplicate.move(path[i]), true);
        }
        expect(game.round, stage + 1, reason: 'seed=$seed stage=$stage');
      }
      expect(game.complete, true);
      expect(game.move(0), false);
      expect(game.totalMoves, greaterThan(0));
    }
  });

  test('invalid edges and nodes cannot move player', () {
    final game = OneStrokeSession(seed: 22);
    final start = game.current;
    expect(game.move(-1), false);
    expect(game.move(game.nodeCount), false);
    expect(game.move(start), false);
    expect(game.current, start);
    expect(game.moves, 0);
    expect(game.invalidMoves, 1);
    expect(game.visited, isEmpty);
  });

  test('used edge is never traversed again; undo restores it', () {
    final game = OneStrokeSession(seed: 6);
    final initial = game.current;
    final next = game.solution![1];
    expect(game.move(next), true);
    expect(game.visited.length, 1);
    expect(game.move(initial), false);
    expect(game.invalidMoves, 1);
    expect(game.undo(), true);
    expect(game.current, initial);
    expect(game.visited, isEmpty);
    expect(game.totalMoves, 0);
    expect(game.undo(), false);
    expect(game.move(next), true);
  });
}
