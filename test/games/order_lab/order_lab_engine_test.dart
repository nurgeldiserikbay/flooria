import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/order_lab/order_lab_engine.dart';

void main() {
  test('every seeded puzzle has exactly one satisfying sequence', () {
    for (var seed = -40; seed < 170; seed++) {
      final game = OrderLabSession(seed: seed);
      final replay = OrderLabSession(seed: seed);
      for (var stage = 0; stage < 3; stage++) {
        expect(game.answer, replay.answer);
        expect(game.clues.map((e) => e.describe()).toList(),
            replay.clues.map((e) => e.describe()).toList());
        expect(game.solutions, [game.answer]);
        expect(game.solved, false);
        final target = game.answer.toList();
        for (var i = 0; i < target.length; i++) {
          if (game.order[i] == target[i]) continue;
          final other = game.order.indexOf(target[i]);
          expect(game.tap(i), true);
          expect(game.tap(other), true);
          expect(replay.tap(i), true);
          expect(replay.tap(other), true);
        }
        expect(game.order, target);
        expect(game.solved, true);
        expect(game.check(), true);
        expect(replay.check(), true);
        expect(game.round, stage + 1);
      }
      expect(game.complete, true);
      expect(game.tap(0), false);
      expect(game.check(), false);
      expect(game.mistakes, 0);
    }
  });

  test('bad tap is ignored, selecting twice cancels', () {
    final game = OrderLabSession(seed: 5);
    expect(game.tap(-1), false);
    expect(game.tap(100), false);
    expect(game.selected, null);
    expect(game.swaps, 0);
    expect(game.tap(0), true);
    expect(game.selected, 0);
    expect(game.tap(0), true);
    expect(game.selected, null);
    expect(game.swaps, 0);
  });

  test('incorrect check never advances or destroys editable order', () {
    final game = OrderLabSession(seed: 14);
    final current = game.order.toList();
    expect(game.solved, false);
    expect(game.check(), false);
    expect(game.round, 0);
    expect(game.mistakes, 1);
    expect(game.order, current);
  });

  test('ordering constraints respect immediate position and endpoints', () {
    const sequence = [3, 1, 0, 2];
    expect(const OrderClue(OrderClueKind.first, 3).holds(sequence), true);
    expect(const OrderClue(OrderClueKind.last, 2).holds(sequence), true);
    expect(const OrderClue(OrderClueKind.before, 1, 2).holds(sequence), true);
    expect(const OrderClue(OrderClueKind.immediatelyBefore, 1, 0)
        .holds(sequence), true);
    expect(const OrderClue(OrderClueKind.immediatelyBefore, 3, 0)
        .holds(sequence), false);
  });
}
