import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/pattern_trio/pattern_trio_engine.dart';

void main() {
  test('complement completes a trio for every pair of unique cards', () {
    for (var a = 0; a < 27; a++) {
      for (var b = 0; b < 27; b++) {
        if (a == b) continue;
        final first = PatternCard.fromCode(a);
        final second = PatternCard.fromCode(b);
        final third = PatternTrioSession.complement(first, second);
        expect(PatternTrioSession.isTrio(first, second, third), true);
      }
    }
    expect(
      () => PatternTrioSession.complement(
          PatternCard.fromCode(0), PatternCard.fromCode(0)),
      throwsArgumentError,
    );
    expect(() => PatternCard.fromCode(27), throwsRangeError);
  });

  test('every seeded deck contains a real trio and replays identically', () {
    for (var seed = -25; seed < 155; seed++) {
      final session = PatternTrioSession(seed: seed);
      final replay = PatternTrioSession(seed: seed);
      for (var round = 0; round < 3; round++) {
        expect(session.cards, replay.cards);
        expect(session.cards.length, 9);
        expect(session.cards.toSet().length, 9);
        final indices = session.exampleTrio;
        expect(indices, isNotNull, reason: 'seed=$seed round=$round');
        for (final index in indices!) {
          expect(session.tap(index), true);
          expect(replay.tap(index), true);
        }
        expect(session.round, round + 1);
      }
      expect(session.complete, true);
      expect(session.attempts, 3);
      expect(session.mistakes, 0);
      expect(session.tap(0), false);
    }
  });

  test('invalid taps do not mutate state, repeated tap deselects', () {
    final session = PatternTrioSession(seed: 7);
    expect(session.tap(-1), false);
    expect(session.tap(9), false);
    expect(session.totalTaps, 0);
    expect(session.tap(0), true);
    expect(session.selected, {0});
    expect(session.tap(0), true);
    expect(session.selected, isEmpty);
    expect(session.attempts, 0);
  });

  test('incorrect trio records a miss and selection resets', () {
    final session = PatternTrioSession(seed: 13);
    List<int>? bad;
    for (var a = 0; a < 9 && bad == null; a++) {
      for (var b = a + 1; b < 9 && bad == null; b++) {
        for (var c = b + 1; c < 9; c++) {
          if (!PatternTrioSession.isTrio(
              session.cards[a], session.cards[b], session.cards[c])) {
            bad = [a, b, c];
            break;
          }
        }
      }
    }
    expect(bad, isNotNull);
    for (final index in bad!) {
      session.tap(index);
    }
    expect(session.round, 0);
    expect(session.attempts, 1);
    expect(session.mistakes, 1);
    expect(session.selected, isEmpty);
    final solution = session.exampleTrio!;
    for (final index in solution) {
      session.tap(index);
    }
    expect(session.round, 1);
    expect(session.attempts, 2);
  });
}
