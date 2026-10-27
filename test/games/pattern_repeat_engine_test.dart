import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/pattern_repeat/pattern_repeat_engine.dart';

void main() {
  group('PatternRepeatEngine', () {
    test('generates the same pattern from the same level and seed', () {
      final first = PatternRepeatEngine.forLevel(5, seed: 41);
      final second = PatternRepeatEngine.forLevel(5, seed: 41);

      expect(first.sequence, second.sequence);
      expect(first.sequence, hasLength(7));
      expect(first.sequence.toSet(), isNotEmpty);
      expect(first.sequence.every((cell) => cell >= 0 && cell < 9), isTrue);
    });

    test('increases sequence length with difficulty and caps it', () {
      expect(PatternRepeatEngine.forLevel(1).sequence, hasLength(3));
      expect(PatternRepeatEngine.forLevel(4).sequence, hasLength(6));
      expect(PatternRepeatEngine.forLevel(99).sequence, hasLength(24));
    });

    test('restarts the input after a wrong cell and counts the mistake', () {
      final engine = PatternRepeatEngine.forLevel(1, seed: 7);
      final firstCell = engine.sequence.first;
      final wrongCell = (firstCell + 1) % PatternRepeatEngine.boardSize;

      expect(engine.tap(wrongCell), PatternTapResult.incorrect);
      expect(engine.mistakes, 1);
      expect(engine.inputIndex, 0);
      expect(engine.isCompleted, isFalse);
    });

    test('ignores out-of-range taps without affecting progress', () {
      final engine = PatternRepeatEngine.forLevel(1, seed: 7);

      expect(engine.tap(-1), PatternTapResult.ignored);
      expect(engine.tap(9), PatternTapResult.ignored);
      expect(engine.inputIndex, 0);
      expect(engine.mistakes, 0);
    });

    test('completes exactly after the full pattern and ignores later taps', () {
      final engine = PatternRepeatEngine.forLevel(1, seed: 7);

      for (final cell in engine.sequence.take(engine.sequence.length - 1)) {
        expect(engine.tap(cell), PatternTapResult.correct);
      }
      expect(engine.tap(engine.sequence.last), PatternTapResult.completed);
      expect(engine.isCompleted, isTrue);
      expect(engine.score, 300);
      expect(engine.tap(engine.sequence.first), PatternTapResult.ignored);
    });
  });
}
