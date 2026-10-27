import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/number_hunt/number_hunt_engine.dart';

void main() {
  group('NumberHuntEngine', () {
    test('generates deterministic boards with one target per round', () {
      final first = NumberHuntEngine.forLevel(4, seed: 23);
      final second = NumberHuntEngine.forLevel(4, seed: 23);

      expect(first.columns, 4);
      expect(first.rows, 4);
      expect(first.rounds.length, NumberHuntEngine.baseRoundsPerLevel);
      for (var i = 0; i < first.rounds.length; i++) {
        expect(first.rounds[i].target, second.rounds[i].target);
        expect(first.rounds[i].numbers, second.rounds[i].numbers);
        expect(first.rounds[i].numbers, hasLength(first.cellCount));
        expect(first.rounds[i].numbers.where((n) => n == first.rounds[i].target),
            hasLength(1));
      }
    });

    test('board and round count increase with level and respect their caps', () {
      final first = NumberHuntEngine.forLevel(1);
      final harder = NumberHuntEngine.forLevel(20);
      final finalLevel = NumberHuntEngine.forLevel(100);

      expect(harder.cellCount, greaterThan(first.cellCount));
      expect(finalLevel.columns, NumberHuntEngine.maxGridColumns);
      expect(finalLevel.rows, NumberHuntEngine.maxGridRows);
      expect(finalLevel.rounds.length, 9);
    });

    test('wrong taps count as misses and a correct tap advances the round', () {
      final engine = NumberHuntEngine.forLevel(1, seed: 9);
      final round = engine.currentRound;
      final wrongIndex = (round.targetIndex + 1) % engine.cellCount;

      expect(engine.tap(wrongIndex), NumberHuntTapResult.incorrect);
      expect(engine.mistakes, 1);
      expect(engine.roundIndex, 0);
      expect(engine.tap(round.targetIndex), NumberHuntTapResult.correct);
      expect(engine.roundIndex, 1);
      expect(engine.isCompleted, isFalse);
    });

    test('completes only after all targets and ignores invalid taps', () {
      final engine = NumberHuntEngine.forLevel(1, seed: 12);

      expect(engine.tap(-1), NumberHuntTapResult.ignored);
      expect(engine.tap(engine.cellCount), NumberHuntTapResult.ignored);
      for (final round in engine.rounds.take(engine.rounds.length - 1)) {
        expect(engine.tap(round.targetIndex), NumberHuntTapResult.correct);
      }
      expect(engine.tap(engine.currentRound.targetIndex),
          NumberHuntTapResult.completed);
      expect(engine.isCompleted, isTrue);
      expect(engine.score, 500);
      expect(engine.tap(0), NumberHuntTapResult.ignored);
    });
  });
}
