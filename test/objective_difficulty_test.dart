import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/game/game_objective.dart';
import 'package:flooria/game/sequence_generator.dart';

void main() {
  const objectives = ObjectiveCatalog();
  test('first tower 2048 objective requires a meaningful 128 tile', () {
    expect(objectives.forGame('merge2048', floor: 1).target, 128);
    expect(objectives.forGame('merge2048', floor: 13).target, 256);
    expect(objectives.forGame('merge2048', floor: 25).target, 512);
    expect(objectives.forGame('merge2048', floor: 49).target, 2048);
    expect(objectives.forGame('merge2048', floor: 100).target, 2048);
  });
  test('later number puzzles require improved accuracy', () {
    expect(objectives.forGame('numberSequence', floor: 2).target, 2);
    expect(objectives.forGame('numberSequence', floor: 14).target, 3);
  });
  test('sequence options are distinct, valid and reproducible', () {
    const generator = SequenceGenerator();
    for (final floor in [2, 12, 22, 52]) {
      for (var round = 0; round < 3; round++) {
        final puzzle = generator.generate(floor: floor, round: round);
        expect(puzzle.choices.length, 4);
        expect(puzzle.choices.toSet().length, 4);
        expect(puzzle.choices, contains(puzzle.answer));
        expect(puzzle.numbers.length, 3);
        expect(generator.generate(floor: floor, round: round).answer, puzzle.answer);
      }
    }
  });
  test('later sequences introduce new pattern kinds', () {
    const generator = SequenceGenerator();
    expect(generator.generate(floor: 2, round: 0).pattern, 'Arithmetic');
    expect(generator.generate(floor: 22, round: 1).pattern, 'Multiplication');
    expect(generator.generate(floor: 22, round: 2).pattern, 'Growing differences');
  });
}
