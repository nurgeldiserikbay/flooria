import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/mini_sudoku/mini_sudoku_engine.dart';

void main() {
  test('seeded puzzles are unique, reproducible and can be solved', () {
    for (var seed = -30; seed < 125; seed++) {
      final game = MiniSudokuSession(seed: seed);
      final replay = MiniSudokuSession(seed: seed);
      for (var stage = 0; stage < 3; stage++) {
        expect(game.clues, replay.clues);
        expect(game.solution, replay.solution);
        expect(MiniSudokuSession.countSolutions(game.clues), 1,
            reason: 'seed $seed, stage $stage');
        expect(game.clues.where((n) => n == 0).isNotEmpty, true);
        for (var i = 0; i < 16; i++) {
          expect(MiniSudokuSession.validPlacement(
              [for (var j = 0; j < 16; j++)
                j == i ? 0 : game.solution[j]],
              i, game.solution[i]), true);
          if (game.clues[i] != 0) continue;
          for (var step = 0; step < game.solution[i]; step++) {
            expect(game.tap(i), true);
            expect(replay.tap(i), true);
          }
        }
        expect(game.board, game.solution);
        expect(game.filled, true);
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

  test('solver rejects contradictions and malformed input', () {
    expect(MiniSudokuSession.countSolutions([1, 1, ...List.filled(14, 0)]), 0);
    expect(() => MiniSudokuSession.countSolutions([0]), throwsArgumentError);
    expect(() => MiniSudokuSession.countSolutions(List.filled(16, 0),
        limit: 0), throwsArgumentError);
    expect(MiniSudokuSession.countSolutions(List.filled(16, 0)), 2);
  });

  test('given cells and indices are protected from edits', () {
    final game = MiniSudokuSession(seed: 5);
    final given = game.clues.indexWhere((n) => n != 0);
    final saved = List<int>.of(game.board);
    expect(game.tap(given), false);
    expect(game.tap(-1), false);
    expect(game.tap(16), false);
    expect(game.board, saved);
    expect(game.edits, 0);
    expect(game.check(), false);
    expect(game.checks, 0);
  });

  test('free cell cycles through numbers and returns to empty', () {
    final game = MiniSudokuSession(seed: 19);
    final empty = game.board.indexOf(0);
    for (var n = 1; n <= 4; n++) {
      expect(game.tap(empty), true);
      expect(game.board[empty], n);
    }
    expect(game.tap(empty), true);
    expect(game.board[empty], 0);
    expect(game.edits, 5);
  });

  test('conflicting complete board is not accepted and remains editable', () {
    final game = MiniSudokuSession(seed: 33);
    for (var i = 0; i < 16; i++) {
      if (game.clues[i] != 0) continue;
      final wrong = game.solution[i] % 4 + 1;
      for (var n = 0; n < wrong; n++) {
        game.tap(i);
      }
    }
    expect(game.filled, true);
    expect(game.conflicts, isNotEmpty);
    expect(game.check(), false);
    expect(game.round, 0);
    expect(game.mistakes, 1);
  });
}
