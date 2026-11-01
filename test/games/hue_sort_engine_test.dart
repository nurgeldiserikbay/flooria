import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/hue_sort/hue_sort_engine.dart';

/// Cycle sort: every swap puts one tile home, which is the minimum.
void solve(HueSortEngine engine) {
  for (var p = 0; p < engine.cellCount && !engine.isCompleted; p++) {
    while (engine.tileAt(p) != p && !engine.isCompleted) {
      engine.swap(p, engine.tileAt(p));
    }
  }
}

double distance(int a, int b) {
  int ch(int c, int s) => (c >> s) & 0xFF;
  var sum = 0;
  for (final s in [16, 8, 0]) {
    final d = ch(a, s) - ch(b, s);
    sum += d * d;
  }
  return sum.toDouble();
}

void main() {
  group('HueSortEngine', () {
    test('all 100 levels have distinct, ordered colours and fixed anchors', () {
      for (var level = 1; level <= 100; level++) {
        final engine = HueSortEngine.forLevel(level);
        expect(engine.colors.toSet(), hasLength(engine.cellCount),
          reason: 'duplicate colours on level $level');
        // Neighbouring tiles must be visibly apart (RGB distance > 6).
        for (var p = 0; p < engine.cellCount; p++) {
          final right = p % engine.columns < engine.columns - 1 ? p + 1 : null;
          final below = p + engine.columns < engine.cellCount ? p + engine.columns : null;
          for (final q in [right, below]) {
            if (q == null) continue;
            expect(distance(engine.colors[p], engine.colors[q]), greaterThan(36),
              reason: 'level $level tiles $p/$q too close');
          }
        }
        for (final p in engine.fixed) {
          expect(engine.tileAt(p), p);
        }
        // The four corners are always anchors.
        expect(engine.fixed, containsAll([0, engine.columns - 1,
          engine.cellCount - engine.columns, engine.cellCount - 1]));
        expect(engine.isCompleted, isFalse);
        expect(engine.minSwaps, greaterThan(0));
      }
    });

    test('solving with the fewest swaps completes with three stars', () {
      for (final level in [1, 5, 20, 40, 80]) {
        final engine = HueSortEngine.forLevel(level);
        solve(engine);
        expect(engine.isCompleted, isTrue);
        expect(engine.swaps, engine.minSwaps);
        expect(engine.stars, 3);
        expect(engine.perceptionMetric, 100);
      }
    });

    test('anchors, self swaps and out-of-range swaps are ignored', () {
      final engine = HueSortEngine.forLevel(3);
      final movable = [
        for (var p = 0; p < engine.cellCount; p++) if (!engine.isFixed(p)) p,
      ];
      expect(engine.swap(0, movable.first), HueSwapResult.ignored);
      expect(engine.swap(movable.first, movable.first), HueSwapResult.ignored);
      expect(engine.swap(-1, movable.first), HueSwapResult.ignored);
      expect(engine.swap(movable.first, engine.cellCount), HueSwapResult.ignored);
      expect(engine.swaps, 0);
      expect(engine.swap(movable[0], movable[1]), HueSwapResult.swapped);
      expect(engine.swaps, 1);
    });

    test('difficulty grows from checkerboard anchors to corners only', () {
      final first = HueSortEngine.forLevel(1);
      final late = HueSortEngine.forLevel(60);
      expect(first.anchors, HueAnchors.checker);
      expect(late.anchors, HueAnchors.corners);
      expect(late.cellCount - late.fixed.length,
        greaterThan(first.cellCount - first.fixed.length));
    });
  });
}
