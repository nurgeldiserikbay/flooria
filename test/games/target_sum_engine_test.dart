import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/target_sum/target_sum_engine.dart';

/// Brute-force one valid set of tile indices for the current round.
List<int> findSolution(SumRound round) {
  List<int>? walk(int start, List<int> chosen, int sum) {
    if (chosen.length == round.picks) return sum == round.target ? chosen : null;
    for (var i = start; i < round.values.length; i++) {
      final found = walk(i + 1, [...chosen, i], sum + round.values[i]);
      if (found != null) return found;
    }
    return null;
  }
  return walk(0, [], 0)!;
}

void main() {
  group('TargetSumEngine', () {
    test('every round on 100 levels has a solution but is not trivial', () {
      for (var level = 1; level <= 100; level++) {
        final engine = TargetSumEngine.forLevel(level);
        final rules = TargetSumEngine.rulesForLevel(level);
        for (final round in engine.rounds) {
          expect(round.values, hasLength(rules.tiles));
          expect(round.picks, inInclusiveRange(rules.minPicks, rules.maxPicks));
          for (final value in round.values) {
            expect(value, inInclusiveRange(rules.low, rules.high));
          }
          expect(TargetSumEngine.countSolutions(round.values, round.picks,
            round.target), greaterThan(0), reason: 'level $level');
        }
      }
    });

    test('solving every round completes the level', () {
      final engine = TargetSumEngine.forLevel(6, seed: 1);
      for (var i = 0; i < engine.rounds.length; i++) {
        final solution = findSolution(engine.currentRound);
        for (var k = 0; k < solution.length - 1; k++) {
          expect(engine.toggle(solution[k]), SumResult.placed);
        }
        expect(engine.toggle(solution.last), i == engine.rounds.length - 1
            ? SumResult.completed : SumResult.correct);
        expect(engine.toggle(0), SumResult.ignored, reason: 'locked until advance');
        engine.advance();
      }
      expect(engine.isCompleted, isTrue);
      expect(engine.stars, 3);
      expect(engine.mathMetric, 100);
    });

    test('a wrong total counts a mistake and clears after the feedback', () {
      final engine = TargetSumEngine.forLevel(1, seed: 3);
      final round = engine.currentRound;
      final solution = findSolution(round).toSet();
      // Find a pair that misses the target.
      late List<int> wrong;
      outer:
      for (var a = 0; a < round.values.length; a++) {
        for (var b = a + 1; b < round.values.length; b++) {
          if (round.values[a] + round.values[b] != round.target) {
            wrong = [a, b];
            break outer;
          }
        }
      }
      expect(engine.toggle(wrong[0]), SumResult.placed);
      expect(engine.toggle(wrong[1]), SumResult.incorrect);
      expect(engine.mistakes, 1);
      expect(engine.phase, SumPhase.wrong);
      expect(engine.toggle(wrong[0]), SumResult.ignored);
      engine.clearWrong();
      expect(engine.slots, isEmpty);
      expect(engine.phase, SumPhase.picking);
      expect(solution, isNotEmpty);
    });

    test('a placed tile can be taken back', () {
      final engine = TargetSumEngine.forLevel(10);
      expect(engine.toggle(2), SumResult.placed);
      expect(engine.isUsed(2), isTrue);
      expect(engine.toggle(2), SumResult.removed);
      expect(engine.slots, isEmpty);
      expect(engine.toggle(99), SumResult.ignored);
    });

    test('later levels hide the running total', () {
      expect(TargetSumEngine.forLevel(5).showRunningTotal, isTrue);
      expect(TargetSumEngine.forLevel(25).showRunningTotal, isFalse);
    });
  });
}
