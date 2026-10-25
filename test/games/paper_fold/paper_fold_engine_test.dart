import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/paper_fold/paper_fold_engine.dart';

void main() {
  test('each folded punched cell maps to the right symmetric locations', () {
    final s = PaperFoldSession(seed: 1);
    for (final direction in PaperFold.values) {
      // Across a representative deterministic search all fold modes occur.
      PaperFoldSession? board;
      for (var seed = 0; seed < 200; seed++) {
        final candidate = PaperFoldSession(seed: seed);
        if (candidate.fold == direction) {
          board = candidate;
          break;
        }
      }
      expect(board, isNotNull);
      for (final punch in board!.visibleCells) {
        final locations = board.unfoldPunch(punch);
        expect(locations.length, direction == PaperFold.both ? 4 : 2);
        expect(locations.every((cell) => cell >= 0 && cell < 36), true);
        for (final cell in locations) {
          final row = cell ~/ 6;
          final column = cell % 6;
          if (direction == PaperFold.left ||
              direction == PaperFold.right ||
              direction == PaperFold.both) {
            expect(locations.contains(row * 6 + (5 - column)), true);
          }
          if (direction == PaperFold.top ||
              direction == PaperFold.bottom ||
              direction == PaperFold.both) {
            expect(locations.contains((5 - row) * 6 + column), true);
          }
        }
      }
    }
    expect(s.round, 0);
  });

  test('seeded stages are reproducible and have a reachable solution', () {
    for (var seed = -50; seed < 130; seed++) {
      final s = PaperFoldSession(seed: seed);
      final replay = PaperFoldSession(seed: seed);
      for (var round = 0; round < 3; round++) {
        expect(s.fold, replay.fold);
        expect(s.punches, replay.punches);
        expect(s.solution, replay.solution);
        expect(s.solution, isNotEmpty);
        expect(s.solution, {
          for (final local in s.punches) ...s.unfoldPunch(local),
        });
        for (final cell in s.solution) {
          expect(s.toggle(cell), true);
          expect(replay.toggle(cell), true);
        }
        expect(s.correct, true);
        expect(s.check(), true);
        expect(replay.check(), true);
      }
      expect(s.complete, true);
      expect(s.round, 3);
      expect(s.attempts, 3);
      expect(s.mistakes, 0);
    }
  });

  test('invalid moves do not change progress; failed checks remain editable', () {
    final s = PaperFoldSession(seed: 13);
    expect(s.toggle(-1), false);
    expect(s.toggle(36), false);
    expect(s.check(), false);
    expect(s.attempts, 0);
    final wrongCell = List<int>.generate(36, (i) => i)
        .firstWhere((i) => !s.solution.contains(i));
    expect(s.toggle(wrongCell), true);
    expect(s.check(), false);
    expect(s.mistakes, 1);
    expect(s.round, 0);
    expect(s.selected.contains(wrongCell), true);
    expect(s.toggle(wrongCell), true);
    for (final cell in s.solution) {
      s.toggle(cell);
    }
    expect(s.check(), true);
    expect(s.round, 1);
  });
}
