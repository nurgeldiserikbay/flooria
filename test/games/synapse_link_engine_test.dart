import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/synapse_link/synapse_link_engine.dart';

/// Turns every tile back to its generated orientation.
int solve(SynapseLinkEngine engine) {
  var taps = 0;
  for (var i = 0; i < engine.cellCount && !engine.isCompleted; i++) {
    while (engine.maskAt(i) != engine.solution[i] && !engine.isCompleted) {
      engine.rotate(i);
      taps++;
    }
  }
  return taps;
}

void main() {
  group('Links', () {
    test('rotate moves each link clockwise and wraps after four turns', () {
      expect(Links.rotate(Links.north, 1), Links.east);
      expect(Links.rotate(Links.west, 1), Links.north);
      expect(Links.rotate(Links.north | Links.east, 2), Links.south | Links.west);
      expect(Links.rotate(11, 4), 11);
    });
  });

  group('SynapseLinkEngine', () {
    test('same seed gives the same board', () {
      final a = SynapseLinkEngine.forLevel(7, seed: 99);
      final b = SynapseLinkEngine.forLevel(7, seed: 99);
      expect(a.solution, b.solution);
      expect([for (var i = 0; i < a.cellCount; i++) a.rotationAt(i)],
        [for (var i = 0; i < b.cellCount; i++) b.rotationAt(i)]);
    });

    test('every level from 1 to 100 is a scrambled, solvable tree', () {
      for (var level = 1; level <= 100; level++) {
        final engine = SynapseLinkEngine.forLevel(level);
        final (columns, rows) = SynapseLinkEngine.sizeForLevel(level);
        expect(engine.columns, columns);
        expect(engine.rows, rows);
        // A spanning tree has exactly cells - 1 links.
        final degrees = engine.solution.fold<int>(0, (s, m) => s + Links.degree(m));
        expect(degrees ~/ 2, engine.cellCount - 1, reason: 'level $level');
        expect(engine.solution.any((m) => m == 15), isFalse,
          reason: 'no crossroads on level $level');
        expect(engine.isCompleted, isFalse);
        expect(engine.litCells.length, lessThan(engine.cellCount));
        expect(engine.par, greaterThan(1));

        final taps = solve(engine);
        expect(engine.isCompleted, isTrue, reason: 'level $level');
        expect(taps, lessThanOrEqualTo(engine.par));
        expect(engine.litCells.length, engine.cellCount);
      }
    });

    test('par play earns three stars and the full logic metric', () {
      final engine = SynapseLinkEngine.forLevel(3);
      solve(engine);
      expect(engine.moves, lessThanOrEqualTo(engine.par));
      expect(engine.stars, 3);
      expect(engine.score, 1000);
      expect(engine.logicMetric, 100);
    });

    test('pinned tiles ignore taps and invalid taps change nothing', () {
      final engine = SynapseLinkEngine.forLevel(5);
      final before = engine.rotationAt(0);
      expect(engine.toggleLock(0), isTrue);
      expect(engine.rotate(0), SynapseTapResult.ignored);
      expect(engine.rotationAt(0), before);
      expect(engine.rotate(-1), SynapseTapResult.ignored);
      expect(engine.rotate(engine.cellCount), SynapseTapResult.ignored);
      expect(engine.moves, 0);
      engine.toggleLock(0);
      expect(engine.rotate(0), isNot(SynapseTapResult.ignored));
      expect(engine.moves, 1);
    });

    test('a finished board ignores further taps', () {
      final engine = SynapseLinkEngine.forLevel(1);
      solve(engine);
      final moves = engine.moves;
      expect(engine.rotate(0), SynapseTapResult.ignored);
      expect(engine.toggleLock(0), isFalse);
      expect(engine.moves, moves);
    });
  });
}
