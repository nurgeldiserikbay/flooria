import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/prism_path/prism_path_engine.dart';

void main() {
  test('seeded puzzles are deterministic', () {
    for (var seed = 0; seed < 20; seed++) {
      final first = PrismPuzzle.generate(seed: seed, round: 1);
      final second = PrismPuzzle.generate(seed: seed, round: 1);

      expect(first.source, second.source);
      expect(first.goal, second.goal);
      expect(
        first.mirrors.map((mirror) => (
          mirror.cell.row,
          mirror.cell.column,
          mirror.face,
          mirror.isDecoy,
        )),
        second.mirrors.map((mirror) => (
          mirror.cell.row,
          mirror.cell.column,
          mirror.face,
          mirror.isDecoy,
        )),
      );
    }
  });

  test('every generated board has a guaranteed two-mirror solution', () {
    for (var seed = 0; seed < 100; seed++) {
      final puzzle = PrismPuzzle.generate(seed: seed, round: seed % 3);
      expect(puzzle.solved, isFalse);

      for (final mirror in puzzle.mirrors.where((mirror) => !mirror.isDecoy)) {
        expect(puzzle.rotateAt(mirror.cell), isTrue);
      }

      expect(puzzle.solved, isTrue, reason: 'seed $seed');
      expect(puzzle.beamCells, contains(puzzle.goal));
      expect(
        puzzle.rotateAt(puzzle.mirrors.first.cell),
        isFalse,
        reason: 'solved boards reject further moves',
      );
    }
  });

  test('invalid moves do not mutate the puzzle', () {
    final session = PrismPathSession(seed: 42);
    final before = session.puzzle.mirrors
        .map((mirror) => mirror.face)
        .toList(growable: false);

    expect(session.rotate(-1, 0), isFalse);
    expect(session.rotate(0, 1), isFalse);
    expect(session.moves, 0);
    expect(
      session.puzzle.mirrors.map((mirror) => mirror.face),
      before,
    );
  });

  test('a session advances only after solving each route', () {
    final session = PrismPathSession(seed: 9);

    expect(session.advance(), isFalse);
    for (var round = 0; round < PrismPathSession.totalRounds; round++) {
      for (final mirror
          in session.puzzle.mirrors.where((mirror) => !mirror.isDecoy)) {
        expect(session.rotate(mirror.cell.row, mirror.cell.column), isTrue);
      }
      expect(session.roundComplete, isTrue);
      expect(session.advance(), isTrue);
      expect(session.round, round + 1);
    }

    expect(session.complete, isTrue);
    expect(session.advance(), isFalse);
    expect(session.moves, 6);
    expect(session.mistakes, 0);
  });

  test('decoy mirror rotations are counted as wrong turns', () {
    final session = PrismPathSession(seed: 14);
    final decoy = session.puzzle.mirrors.firstWhere((mirror) => mirror.isDecoy);

    expect(session.rotate(decoy.cell.row, decoy.cell.column), isTrue);
    expect(session.moves, 1);
    expect(session.mistakes, 1);
  });
}
