import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/pixel_garden/pixel_garden_engine.dart';

void main() {
  group('PixelGardenPuzzle', () {
    test('seeded boards are deterministic and have unique clue solutions', () {
      for (var seed = 0; seed < 50; seed++) {
        for (var round = 0; round < PixelGardenSession.totalRounds; round++) {
          final first = PixelGardenPuzzle.generate(seed: seed, round: round);
          final second = PixelGardenPuzzle.generate(seed: seed, round: round);
          expect(first.targetCells, second.targetCells);
          expect(first.rowClues, second.rowClues);
          expect(first.columnClues, second.columnClues);
          expect(
            PixelGardenPuzzle.countSolutions(
              rowClues: first.rowClues,
              columnClues: first.columnClues,
            ),
            1,
          );
        }
      }
    });

    test('rejects out-of-range cells without mutating the board', () {
      final puzzle = PixelGardenPuzzle.generate(seed: 42);
      expect(puzzle.toggle(-1), isFalse);
      expect(puzzle.toggle(PixelGardenPuzzle.cellCount), isFalse);
      expect(puzzle.moves, 0);
      expect(puzzle.filledCells, isEmpty);
    });

    test('counts incorrect fills and completes only on the exact picture', () {
      final puzzle = PixelGardenPuzzle.generate(seed: 9);
      final wrongCell = List<int>.generate(
        PixelGardenPuzzle.cellCount,
        (index) => index,
      ).firstWhere((index) => !puzzle.targetCells.contains(index));
      expect(puzzle.toggle(wrongCell), isTrue);
      expect(puzzle.mistakes, 1);
      expect(puzzle.solved, isFalse);
      expect(puzzle.toggle(wrongCell), isTrue);
      expect(puzzle.mistakes, 1);
      for (final cell in puzzle.targetCells) {
        expect(puzzle.toggle(cell), isTrue);
      }
      expect(puzzle.solved, isTrue);
      expect(puzzle.toggle(0), isFalse);
    });
  });

  test('session advances only through three solved pictures', () {
    final session = PixelGardenSession(seed: 502);
    expect(session.advance(), isFalse);
    for (var round = 0; round < PixelGardenSession.totalRounds; round++) {
      for (final cell in session.puzzle.targetCells) {
        expect(session.toggle(cell), isTrue);
      }
      expect(session.roundComplete, isTrue);
      expect(session.advance(), isTrue);
    }
    expect(session.complete, isTrue);
    expect(session.totalMoves, greaterThan(0));
    expect(session.advance(), isFalse);
  });
}
