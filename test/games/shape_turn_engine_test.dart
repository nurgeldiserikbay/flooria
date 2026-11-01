import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/shape_turn/shape_turn_engine.dart';

void main() {
  group('Shapes', () {
    test('four quarter turns return the original shape', () {
      const l = [(0, 0), (1, 0), (2, 0), (2, 1)];
      expect(Shapes.key(Shapes.rotate(l, 4)), Shapes.key(l));
      expect(Shapes.key(Shapes.rotate(l, 1)), isNot(Shapes.key(l)));
      expect(Shapes.isChiral(l), isTrue);
      expect(Shapes.isChiral(const [(0, 0), (0, 1), (1, 0), (1, 1)]), isFalse);
    });
  });

  group('ShapeTurnEngine', () {
    test('every round on 100 levels has exactly one true rotation', () {
      for (var level = 1; level <= 100; level++) {
        final engine = ShapeTurnEngine.forLevel(level);
        for (final round in engine.rounds) {
          final targetClass = Shapes.rotationClass(round.target);
          expect(round.target, hasLength(ShapeTurnEngine.cellsForLevel(level)));
          expect(Shapes.isChiral(round.target), isTrue);
          expect(round.options, hasLength(4));
          final matches = round.options.where((option) =>
              Shapes.rotationClass(option.displayed) == targetClass);
          expect(matches, hasLength(1), reason: 'level $level');
          expect(matches.single.correct, isTrue);
          expect(round.options[round.answer].correct, isTrue);
          // Options must look different from each other.
          expect(round.options.map((o) => Shapes.key(o.displayed)).toSet(),
            hasLength(4));
          // The correct answer is never shown upright.
          expect(Shapes.key(round.options[round.answer].displayed),
            isNot(Shapes.key(round.target)));
        }
        expect(engine.rounds.map((r) => Shapes.rotationClass(r.target)).toSet(),
          hasLength(engine.rounds.length));
      }
    });

    test('correct answers complete the level after the last advance', () {
      final engine = ShapeTurnEngine.forLevel(4, seed: 2);
      for (var i = 0; i < engine.rounds.length; i++) {
        final result = engine.answer(engine.currentRound.answer);
        expect(result, i == engine.rounds.length - 1
            ? ShapeAnswer.completed : ShapeAnswer.correct);
        expect(engine.answer(0), ShapeAnswer.ignored, reason: 'waits for advance');
        engine.advance();
      }
      expect(engine.isCompleted, isTrue);
      expect(engine.stars, 3);
      expect(engine.spatialMetric, 100);
      expect(engine.answer(0), ShapeAnswer.ignored);
    });

    test('too many wrong picks fail the level', () {
      final engine = ShapeTurnEngine.forLevel(12, seed: 5);
      expect(engine.allowedMistakes, 1);
      int wrong() => (engine.currentRound.answer + 1) % 4;
      expect(engine.answer(wrong()), ShapeAnswer.incorrect);
      engine.advance();
      expect(engine.answer(wrong()), ShapeAnswer.failed);
      expect(engine.isFailed, isTrue);
      expect(engine.isCompleted, isFalse);
      engine.advance();
      expect(engine.roundIndex, 1, reason: 'a failed level stays put');
      expect(engine.missedRounds, {0, 1});
    });

    test('invalid options are ignored', () {
      final engine = ShapeTurnEngine.forLevel(1);
      expect(engine.answer(-1), ShapeAnswer.ignored);
      expect(engine.answer(4), ShapeAnswer.ignored);
      expect(engine.mistakes, 0);
    });
  });
}
