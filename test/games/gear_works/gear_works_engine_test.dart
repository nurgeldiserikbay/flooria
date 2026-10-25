import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/gear_works/gear_works_engine.dart';

void main() {
  test('all generated levels are solvable with finite gear supply', () {
    for (var seed = 0; seed < 240; seed++) {
      final puzzle = GearWorksSession(seed: seed);
      final replay = GearWorksSession(seed: seed);
      expect(puzzle.solutionGears, replay.solutionGears);
      expect(puzzle.blockers, replay.blockers);
      expect(puzzle.fixedGears, replay.fixedGears);
      expect(puzzle.complete, isFalse);
      expect(puzzle.solutionGears.intersection(puzzle.blockers), isEmpty);
      expect(puzzle.inventory, puzzle.solutionGears.length - puzzle.fixedGears.length);
      for (final cell in puzzle.solutionGears) {
        if (puzzle.fixedGears.contains(cell)) continue;
        expect(puzzle.toggle(cell), isTrue);
      }
      expect(puzzle.complete, isTrue,
        reason: 'Seed $seed must have a working solution');
      expect(puzzle.powered.contains(puzzle.receiver), isTrue);
    }
  });

  test('illegal moves, fixed gears, and obstacles cannot be modified', () {
    final puzzle = GearWorksSession(seed: 89);
    expect(puzzle.toggle(-1), isFalse);
    expect(puzzle.toggle(25), isFalse);
    expect(puzzle.toggle(puzzle.driver), isFalse);
    expect(puzzle.toggle(puzzle.receiver), isFalse);
    for (final cell in puzzle.fixedGears) {
      expect(puzzle.toggle(cell), isFalse);
    }
    for (final cell in puzzle.blockers) {
      expect(puzzle.toggle(cell), isFalse);
    }
    expect(puzzle.moves, 0);
  });

  test('player can remove a placed gear and reuse the inventory', () {
    final puzzle = GearWorksSession(seed: 13);
    final cell = puzzle.solutionGears.difference(puzzle.fixedGears).first;
    final remaining = puzzle.remaining;
    expect(puzzle.toggle(cell), isTrue);
    expect(puzzle.remaining, remaining - 1);
    expect(puzzle.toggle(cell), isTrue);
    expect(puzzle.remaining, remaining);
    expect(puzzle.moves, 2);
  });

  test('power directions alternate across engaged gears', () {
    final puzzle = GearWorksSession(seed: 27);
    for (final cell in puzzle.solutionGears) {
      if (!puzzle.fixedGears.contains(cell)) puzzle.toggle(cell);
    }
    final rotations = puzzle.spinDirections;
    for (final cell in rotations.keys) {
      for (final neighbor in puzzle.neighbors(cell)) {
        if (rotations.containsKey(neighbor)) {
          expect(rotations[cell], -rotations[neighbor]!);
        }
      }
    }
  });
}
