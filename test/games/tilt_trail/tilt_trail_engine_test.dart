import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/tilt_trail/tilt_trail_engine.dart';

void main() {
  test('seeded boards reproduce their walls and known solution', () {
    for (var seed = 0; seed < 30; seed++) {
      final first = TiltPuzzle.generate(seed: seed, round: 2);
      final second = TiltPuzzle.generate(seed: seed, round: 2);

      expect(first.start, second.start);
      expect(first.goal, second.goal);
      expect(first.walls, second.walls);
      expect(first.solution, second.solution);
    }
  });

  test('every generated board can be solved using its guaranteed route', () {
    for (var seed = 0; seed < 120; seed++) {
      final puzzle = TiltPuzzle.generate(seed: seed, round: seed % 3);

      expect(puzzle.solution.length, greaterThanOrEqualTo(3));
      for (final direction in puzzle.solution) {
        expect(puzzle.tilt(direction), isTrue, reason: 'seed $seed');
      }
      expect(puzzle.solved, isTrue, reason: 'seed $seed');
      expect(puzzle.tilt(TiltDirection.left), isFalse);
    }
  });

  test('blocked tilt does not move the marble or increase moves', () {
    TiltPuzzle? puzzleWithBlockedStartMove;
    TiltDirection? blockedDirection;

    for (var seed = 0; seed < 200 && puzzleWithBlockedStartMove == null; seed++) {
      final puzzle = TiltPuzzle.generate(seed: seed);
      for (final direction in TiltDirection.values) {
        final adjacent = switch (direction) {
          TiltDirection.up => TiltCell(puzzle.start.row - 1, puzzle.start.column),
          TiltDirection.right =>
            TiltCell(puzzle.start.row, puzzle.start.column + 1),
          TiltDirection.down =>
            TiltCell(puzzle.start.row + 1, puzzle.start.column),
          TiltDirection.left =>
            TiltCell(puzzle.start.row, puzzle.start.column - 1),
        };
        if (puzzle.walls.contains(adjacent)) {
          puzzleWithBlockedStartMove = puzzle;
          blockedDirection = direction;
          break;
        }
      }
    }

    expect(puzzleWithBlockedStartMove, isNotNull);
    final position = puzzleWithBlockedStartMove!.position;
    expect(puzzleWithBlockedStartMove.tilt(blockedDirection!), isFalse);
    expect(puzzleWithBlockedStartMove.position, position);
    expect(puzzleWithBlockedStartMove.moves, 0);
  });

  test('three-round session advances only after reaching each star', () {
    final session = TiltTrailSession(seed: 73);

    expect(session.advance(), isFalse);
    for (var round = 0; round < TiltTrailSession.totalRounds; round++) {
      for (final direction in session.puzzle.solution) {
        expect(session.tilt(direction), isTrue);
      }
      expect(session.roundComplete, isTrue);
      expect(session.advance(), isTrue);
      expect(session.round, round + 1);
    }

    expect(session.complete, isTrue);
    expect(session.advance(), isFalse);
    expect(session.moves, greaterThanOrEqualTo(9));
  });
}
