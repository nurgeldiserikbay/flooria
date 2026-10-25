import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/clover_sweep/clover_sweep_engine.dart';

void main() {
  group('CloverSweepPuzzle', () {
    test('seeded fields match and the first patch is a safe zero', () {
      for (var seed = 0; seed < 40; seed++) {
        for (var round = 0; round < CloverSweepSession.totalRounds; round++) {
          final first = CloverSweepPuzzle.generate(seed: seed, round: round);
          final second = CloverSweepPuzzle.generate(seed: seed, round: round);
          expect(first.mines, second.mines);
          expect(first.mines, hasLength(5 + round * 2));
          expect(first.mines, isNot(contains(CloverSweepPuzzle.startCell)));
          expect(first.adjacentMines(CloverSweepPuzzle.startCell), 0);
          expect(first.neighbors(CloverSweepPuzzle.startCell),
              containsAll([1, CloverSweepPuzzle.size,
                CloverSweepPuzzle.size + 1]));
        }
      }
    });

    test('invalid input is inert and flags can be toggled', () {
      final puzzle = CloverSweepPuzzle.generate(seed: 91);
      expect(puzzle.reveal(-1), isFalse);
      expect(puzzle.toggleFlag(CloverSweepPuzzle.cellCount), isFalse);
      expect(puzzle.reveal(CloverSweepPuzzle.startCell), isTrue);
      expect(
          puzzle.toggleFlag(CloverSweepPuzzle.startCell), isFalse);
      expect(puzzle.toggleFlag(35), isTrue);
      expect(puzzle.reveal(35), isFalse);
      expect(puzzle.toggleFlag(35), isTrue);
      expect(puzzle.reveal(35), isTrue);
    });

    test('mine hits are measured and safe flood reveal completes the board',
        () {
      final puzzle = CloverSweepPuzzle.generate(seed: 14);
      final mine = puzzle.mines.first;
      expect(puzzle.reveal(mine), isTrue);
      expect(puzzle.mineHits, 1);
      expect(puzzle.reveal(mine), isFalse);
      for (var cell = 0; cell < CloverSweepPuzzle.cellCount; cell++) {
        if (!puzzle.mines.contains(cell) &&
            !puzzle.revealedSafeCells.contains(cell)) {
          puzzle.reveal(cell);
        }
      }
      expect(puzzle.complete, isTrue);
      expect(puzzle.reveal(2), isFalse);
    });
  });

  test('session advances only after each patch is cleared', () {
    final session = CloverSweepSession(seed: 733);
    expect(session.advance(), isFalse);
    for (var round = 0; round < CloverSweepSession.totalRounds; round++) {
      for (var cell = 0; cell < CloverSweepPuzzle.cellCount; cell++) {
        if (!session.puzzle.mines.contains(cell) &&
            !session.puzzle.revealedSafeCells.contains(cell)) {
          session.reveal(cell);
        }
      }
      expect(session.roundComplete, isTrue);
      expect(session.advance(), isTrue);
    }
    expect(session.complete, isTrue);
    expect(session.totalMoves, greaterThan(0));
    expect(session.advance(), isFalse);
  });
}
