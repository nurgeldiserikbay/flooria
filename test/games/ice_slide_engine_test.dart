import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/ice_slide/ice_slide_engine.dart';

/// Independent breadth-first search returning one shortest route.
List<SlideDirection>? shortestRoute(IceSlideEngine engine) {
  final previous = <int, (int, SlideDirection)>{};
  final queue = Queue<int>()..add(engine.start);
  final seen = {engine.start};
  while (queue.isNotEmpty) {
    final cell = queue.removeFirst();
    if (cell == engine.goal) {
      final route = <SlideDirection>[];
      var at = cell;
      while (at != engine.start) {
        final (from, direction) = previous[at]!;
        route.insert(0, direction);
        at = from;
      }
      return route;
    }
    for (final direction in SlideDirection.values) {
      final stop = IceSlideEngine.stopFrom(engine.size, engine.blocks, cell, direction);
      if (stop != null && seen.add(stop)) {
        previous[stop] = (cell, direction);
        queue.add(stop);
      }
    }
  }
  return null;
}

void main() {
  group('IceSlideEngine', () {
    test('the puck slides until a block or the edge', () {
      // 5x5 board, block at row 0 column 3.
      expect(IceSlideEngine.stopFrom(5, {3}, 0, SlideDirection.right), 2);
      expect(IceSlideEngine.stopFrom(5, {3}, 0, SlideDirection.down), 20);
      expect(IceSlideEngine.stopFrom(5, {3}, 0, SlideDirection.up), isNull);
      expect(IceSlideEngine.stopFrom(5, {1}, 0, SlideDirection.right), isNull);
    });

    test('every level from 1 to 100 is solvable in exactly par moves', () {
      var deepEnough = 0;
      for (var level = 1; level <= 100; level++) {
        final engine = IceSlideEngine.forLevel(level);
        expect(engine.size, IceSlideEngine.sizeForLevel(level));
        expect(engine.blocks.contains(engine.start), isFalse);
        expect(engine.blocks.contains(engine.goal), isFalse);
        expect(engine.goal, isNot(engine.start));

        final route = shortestRoute(engine);
        expect(route, isNotNull, reason: 'level $level');
        expect(route!.length, engine.par, reason: 'level $level');
        if (engine.par >= IceSlideEngine.minParForLevel(level)) deepEnough++;

        for (final direction in route) {
          expect(engine.slide(direction), isNot(SlideResult.ignored));
        }
        expect(engine.isCompleted, isTrue);
        expect(engine.moves, engine.par);
        expect(engine.stars, 3);
        expect(engine.planningMetric, 100);
      }
      expect(deepEnough, greaterThanOrEqualTo(95));
    });

    test('levels are deterministic and get deeper', () {
      final a = IceSlideEngine.forLevel(30, seed: 4);
      final b = IceSlideEngine.forLevel(30, seed: 4);
      expect(a.blocks, b.blocks);
      expect(a.start, b.start);
      expect(a.goal, b.goal);
      expect(IceSlideEngine.forLevel(60).par,
        greaterThan(IceSlideEngine.forLevel(1).par));
    });

    test('blocked moves are ignored and undo steps back', () {
      final engine = IceSlideEngine.forLevel(8);
      final start = engine.position;
      final move = SlideDirection.values.firstWhere(
        (d) => engine.slideLength(d) > 0 &&
            IceSlideEngine.stopFrom(engine.size, engine.blocks, start, d) != engine.goal);
      expect(engine.slide(move), SlideResult.moved);
      expect(engine.position, isNot(start));
      expect(engine.canUndo, isTrue);
      expect(engine.undo(), isTrue);
      expect(engine.position, start);
      expect(engine.moves, 1, reason: 'undo does not refund the move');
      expect(engine.undo(), isFalse);

      final blocked = SlideDirection.values.where((d) => engine.slideLength(d) == 0);
      for (final direction in blocked) {
        expect(engine.slide(direction), SlideResult.ignored);
      }
      expect(engine.moves, 1);
    });

    test('extra moves lower stars and the planning metric', () {
      final engine = IceSlideEngine.forLevel(12);
      final route = shortestRoute(engine)!;
      // Waste three moves by sliding away and back where possible.
      var wasted = 0;
      for (final direction in SlideDirection.values) {
        if (wasted >= 3) break;
        final stop = IceSlideEngine.stopFrom(engine.size, engine.blocks,
          engine.position, direction);
        if (stop == null || stop == engine.goal) continue;
        engine.slide(direction);
        engine.undo();
        wasted++;
      }
      for (final direction in route) {
        engine.slide(direction);
      }
      expect(engine.isCompleted, isTrue);
      expect(engine.moves, engine.par + wasted);
      if (wasted >= 3) {
        expect(engine.stars, 1);
        expect(engine.planningMetric, 70);
      }
    });
  });
}
