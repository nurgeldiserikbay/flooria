import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/loop_logic/loop_logic_engine.dart';

void main() {
  group('LoopLogicPuzzle', () {
    test('seeded loops are deterministic and match every clue', () {
      for (var seed = 0; seed < 40; seed++) {
        for (var round = 0; round < LoopLogicSession.totalRounds; round++) {
          final first = LoopLogicPuzzle.generate(seed: seed, round: round);
          final second = LoopLogicPuzzle.generate(seed: seed, round: round);
          expect(first.clues, second.clues);
          expect(first.solutionEdges, second.solutionEdges);
          for (var row = 0; row < LoopLogicPuzzle.size; row++) {
            for (var column = 0; column < LoopLogicPuzzle.size; column++) {
              final around = first.solutionEdges.where((edge) {
                final top = LoopEdge(
                    row * LoopLogicPuzzle.vertexCount + column,
                    row * LoopLogicPuzzle.vertexCount + column + 1);
                final bottom = LoopEdge(
                    (row + 1) * LoopLogicPuzzle.vertexCount + column,
                    (row + 1) * LoopLogicPuzzle.vertexCount + column + 1);
                final left = LoopEdge(
                    row * LoopLogicPuzzle.vertexCount + column,
                    (row + 1) * LoopLogicPuzzle.vertexCount + column);
                final right = LoopEdge(
                    row * LoopLogicPuzzle.vertexCount + column + 1,
                    (row + 1) * LoopLogicPuzzle.vertexCount + column + 1);
                return edge == top ||
                    edge == bottom ||
                    edge == left ||
                    edge == right;
              }).length;
              expect(around, first.clues[row][column]);
            }
          }
          for (final edge in first.solutionEdges) {
            expect(first.toggleEdge(edge), isTrue);
          }
          expect(first.solved, isTrue);
        }
      }
    });

    test('rejects invalid or non-adjacent edges without mutation', () {
      final puzzle = LoopLogicPuzzle.generate(seed: 88);
      expect(puzzle.toggleEdge(const LoopEdge(-1, 0)), isFalse);
      expect(puzzle.toggleEdge(const LoopEdge(0, 6)), isFalse);
      expect(puzzle.moves, 0);
      expect(puzzle.selectedEdges, isEmpty);
    });

    test('edge can be removed before the loop is complete', () {
      final puzzle = LoopLogicPuzzle.generate(seed: 15);
      final edge = puzzle.solutionEdges.first;
      expect(puzzle.toggleEdge(edge), isTrue);
      expect(puzzle.toggleEdge(edge), isTrue);
      expect(puzzle.selectedEdges, isEmpty);
      expect(puzzle.moves, 2);
    });
  });

  test('three-loop session advances only on completed loops', () {
    final session = LoopLogicSession(seed: 377);
    expect(session.advance(), isFalse);
    for (var round = 0; round < LoopLogicSession.totalRounds; round++) {
      for (final edge in session.puzzle.solutionEdges) {
        expect(session.toggle(edge), isTrue);
      }
      expect(session.roundComplete, isTrue);
      expect(session.advance(), isTrue);
    }
    expect(session.complete, isTrue);
    expect(session.totalMoves, greaterThan(0));
    expect(session.advance(), isFalse);
  });
}
