import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/queens_guard/queens_guard_engine.dart';

void main() {
  test('every seeded round admits five non-attacking queens', () {
    for (var seed = -30; seed < 130; seed++) {
      final game = QueensGuardSession(seed: seed);
      final replay = QueensGuardSession(seed: seed);
      for (var stage = 0; stage < 3; stage++) {
        expect(game.exampleSolution, replay.exampleSolution);
        expect(game.blocked, replay.blocked);
        expect(game.fixedQueen, replay.fixedQueen);
        expect(game.exampleSolution.length, 5);
        expect(game.exampleSolution.contains(game.fixedQueen), true);
        expect(game.blocked.intersection(game.exampleSolution), isEmpty);
        final all = game.exampleSolution.toList();
        for (var a = 0; a < all.length; a++) {
          for (var b = a + 1; b < all.length; b++) {
            expect(QueensGuardSession.attack(all[a], all[b]), false);
          }
        }
        for (final cell in all) {
          if (cell == game.fixedQueen) continue;
          expect(game.toggle(cell), true);
          expect(replay.toggle(cell), true);
        }
        expect(game.solved, true);
        expect(game.conflicts, isEmpty);
        expect(game.check(), true);
        expect(replay.check(), true);
        expect(game.round, stage + 1, reason: 'seed $seed stage $stage');
      }
      expect(game.complete, true);
      expect(game.queens.length, 5);
      expect(game.toggle(0), false);
      expect(game.check(), false);
      expect(game.checks, 3);
      expect(game.mistakes, 0);
    }
  });

  test('blocked and fixed cells, invalid coordinates are immutable', () {
    final game = QueensGuardSession(seed: 12);
    expect(game.toggle(-1), false);
    expect(game.toggle(25), false);
    expect(game.toggle(game.fixedQueen), false);
    for (final cell in game.blocked) {
      expect(game.toggle(cell), false);
    }
    expect(game.placements, 0);
    expect(game.queens, {game.fixedQueen});
    expect(game.check(), false);
    expect(game.checks, 0);
  });

  test('conflicts reveal attacks and wrong checks remain editable', () {
    final game = QueensGuardSession(seed: 9);
    final row = game.fixedQueen ~/ 5;
    final wrong = [
      for (var col = 0; col < 5; col++) row * 5 + col,
    ].firstWhere((cell) => cell != game.fixedQueen && !game.blocked.contains(cell));
    expect(game.toggle(wrong), true);
    expect(game.conflicts.contains(game.fixedQueen), true);
    expect(game.conflicts.contains(wrong), true);
    expect(game.toggle(wrong), true);
    expect(game.conflicts, isEmpty);
    expect(game.placements, 2);
  });

  test('a full but conflicting arrangement cannot pass a check', () {
    final game = QueensGuardSession(seed: 3);
    for (var cell = 0; cell < 25 && game.queens.length < 5; cell++) {
      if (cell != game.fixedQueen && !game.blocked.contains(cell)) {
        game.toggle(cell);
      }
    }
    expect(game.queens.length, 5);
    if (game.solved) {
      // The generator may coincidentally produce the earliest valid 5 cells.
      expect(game.check(), true);
    } else {
      expect(game.check(), false);
      expect(game.mistakes, 1);
      expect(game.round, 0);
    }
  });
}
