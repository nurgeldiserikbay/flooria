import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/bead_sort/bead_sort_engine.dart';

void main() {
  group('BeadSortPuzzle', () {
    test('seeded puzzles match and retain a complete solution route', () {
      for (var seed = 0; seed < 30; seed++) {
        final first = BeadSortPuzzle.generate(seed: seed, round: 1, floor: 12);
        final second = BeadSortPuzzle.generate(seed: seed, round: 1, floor: 12);
        expect(first.tubes, second.tubes);
        expect(first.solutionMoves, second.solutionMoves);
        expect(first.solved, isFalse);

        for (final move in first.solutionMoves) {
          expect(first.move(move.from, move.to), isTrue);
        }
        expect(first.solved, isTrue);
      }
    });

    test('rejects invalid pours without changing tubes or move count', () {
      final puzzle = BeadSortPuzzle.generate(seed: 77);
      final before = puzzle.tubes.map(List<BeadColor>.of).toList();
      expect(puzzle.move(-1, 0), isFalse);
      expect(puzzle.move(0, 99), isFalse);
      expect(puzzle.move(0, 0), isFalse);
      expect(puzzle.moves, 0);
      expect(puzzle.tubes, before);
    });

    test('allows a bead into an empty or matching tube only', () {
      final puzzle = BeadSortPuzzle.generate(seed: 41);
      final move = puzzle.solutionMoves.first;
      expect(puzzle.move(move.from, move.to), isTrue);
      expect(puzzle.tubes[move.to].length, greaterThan(0));
      expect(puzzle.moves, 1);
    });
  });

  test('session advances only after each of three boards is sorted', () {
    final session = BeadSortSession(seed: 229);
    expect(session.advance(), isFalse);
    for (var round = 0; round < BeadSortSession.totalRounds; round++) {
      for (final move in session.puzzle.solutionMoves) {
        expect(session.move(move.from, move.to), isTrue);
      }
      expect(session.roundComplete, isTrue);
      expect(session.advance(), isTrue);
    }
    expect(session.complete, isTrue);
    expect(session.totalMoves, greaterThan(0));
    expect(session.advance(), isFalse);
  });
}
