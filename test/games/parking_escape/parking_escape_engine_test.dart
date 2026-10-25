import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/parking_escape/parking_escape_engine.dart';

void main() {
  test('every curated puzzle has a shortest legal solution', () {
    for (var seed = -24; seed <= 24; seed++) {
      final puzzle = ParkingEscapeSession(seed: seed);
      expect(puzzle.boardIsValid, true);
      expect(puzzle.complete, false);
      final solution = puzzle.shortestSolution();
      expect(solution, isNotNull, reason: 'Seed $seed must be solvable');
      expect(solution, isNotEmpty);
      for (final (id, delta) in solution!) {
        expect(puzzle.slide(id, delta), true,
          reason: 'Each BFS move must be valid in seed $seed');
      }
      expect(puzzle.complete, true);
      expect(puzzle.moves, solution.length);
      expect(puzzle.slide(0, 1), false);
    }
  });

  test('invalid moves leave the board and move count unchanged', () {
    final puzzle = ParkingEscapeSession(seed: 0);
    final positions = [
      for (final car in puzzle.cars) (car.id, car.row, car.column),
    ];
    expect(puzzle.slide(0, -2), false);
    expect(puzzle.slide(0, 0), false);
    expect(puzzle.slide(777, 1), false);
    expect(puzzle.slide(0, -1), false);
    expect(puzzle.moves, 0);
    expect([
      for (final car in puzzle.cars) (car.id, car.row, car.column),
    ], positions);
  });

  test('blocking vehicles move only on their allowed axis', () {
    final puzzle = ParkingEscapeSession(seed: 0);
    final vertical = puzzle.car(1);
    expect(vertical.horizontal, false);
    expect(puzzle.slide(1, -1), true);
    expect(puzzle.car(1).column, vertical.column);
    expect(puzzle.car(1).row, vertical.row - 1);
    expect(puzzle.boardIsValid, true);
  });

  test('solver does not mutate the active game board', () {
    final puzzle = ParkingEscapeSession(seed: 5);
    final before = [
      for (final car in puzzle.cars) (car.row, car.column),
    ];
    final first = puzzle.shortestSolution();
    final second = puzzle.shortestSolution();
    expect(first, second);
    expect([
      for (final car in puzzle.cars) (car.row, car.column),
    ], before);
    expect(puzzle.moves, 0);
  });
}
