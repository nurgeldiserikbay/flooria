import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/map_tints/map_tints_engine.dart';

void main() {
  test('generated rounds have connected graphs and valid witness coloring', () {
    for (var seed = -30; seed < 180; seed++) {
      final game = MapTintsSession(seed: seed);
      final duplicate = MapTintsSession(seed: seed);
      for (var stage = 0; stage < 3; stage++) {
        expect(game.nodeCount, 6 + stage);
        expect(game.edges, duplicate.edges);
        expect(game.witness, duplicate.witness);
        expect(game.fixed, duplicate.fixed);
        expect(MapTintsSession.validColoring(
            game.witness.map<int?>((v) => v).toList(), game.edges), true);
        final reached = <int>{0};
        var changed = true;
        while (changed) {
          final before = reached.length;
          for (final edge in game.edges) {
            if (reached.contains(edge.$1)) reached.add(edge.$2);
            if (reached.contains(edge.$2)) reached.add(edge.$1);
          }
          changed = before != reached.length;
        }
        expect(reached.length, game.nodeCount);
        expect(game.solved, false);
        for (var i = 0; i < game.nodeCount; i++) {
          if (game.fixed.containsKey(i)) continue;
          for (var count = 0; count <= game.witness[i]; count++) {
            expect(game.tap(i), true);
            expect(duplicate.tap(i), true);
          }
        }
        expect(game.solved, true, reason: 'seed $seed stage $stage');
        expect(game.check(), true);
        expect(duplicate.check(), true);
        expect(game.round, stage + 1);
      }
      expect(game.complete, true);
      expect(game.check(), false);
      expect(game.tap(0), false);
    }
  });

  test('locked nodes and bad coordinates cannot be modified', () {
    final game = MapTintsSession(seed: 17);
    final fixedNode = game.fixed.keys.first;
    expect(game.tap(fixedNode), false);
    expect(game.tap(-1), false);
    expect(game.tap(game.nodeCount), false);
    expect(game.taps, 0);
    expect(game.colors[fixedNode], game.fixed[fixedNode]);
  });

  test('color taps cycle through three paints and back to blank', () {
    final game = MapTintsSession(seed: 25);
    final node = List<int>.generate(game.nodeCount, (i) => i)
        .firstWhere((i) => !game.fixed.containsKey(i));
    for (var paint = 0; paint < 3; paint++) {
      expect(game.tap(node), true);
      expect(game.colors[node], paint);
    }
    expect(game.tap(node), true);
    expect(game.colors[node], null);
    expect(game.taps, 4);
  });

  test('adjacent matching colors fail without clearing the board', () {
    final game = MapTintsSession(seed: 11);
    final edge = game.edges.first;
    // Choose an edge whose endpoints are not both locked; witness differs.
    final candidate = game.edges.firstWhere(
      (e) => !game.fixed.containsKey(e.$1) &&
          !game.fixed.containsKey(e.$2));
    for (var i = 0; i < game.nodeCount; i++) {
      if (game.fixed.containsKey(i)) continue;
      final wanted = i == candidate.$2 ? game.witness[candidate.$1]
          : game.witness[i];
      for (var j = 0; j <= wanted; j++) {
        game.tap(i);
      }
    }
    expect(edge.$1 < game.nodeCount, true);
    expect(game.conflicts.contains(candidate.$1), true);
    expect(game.conflicts.contains(candidate.$2), true);
    expect(game.check(), false);
    expect(game.mistakes, 1);
    expect(game.round, 0);
    expect(game.fullyColored, true);
  });
}
