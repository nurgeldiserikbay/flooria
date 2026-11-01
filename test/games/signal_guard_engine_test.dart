import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/signal_guard/signal_guard_engine.dart';

void main() {
  group('SignalGuardEngine', () {
    test('trial lists follow the level rule and stay balanced', () {
      for (var level = 1; level <= 100; level++) {
        final engine = SignalGuardEngine.forLevel(level);
        final trials = engine.trials;
        final go = trials.where((t) => t.isGo).length;
        expect(go, (trials.length * .65).round());
        expect(trials.first.isGo, isTrue);
        for (final trial in trials) {
          if (engine.rule == SignalRule.color) {
            expect(trial.isGo, trial.tint == SignalTint.mint);
          } else {
            expect(trial.isGo, trial.shape == SignalShape.circle);
          }
          expect(trial.delayMs, inInclusiveRange(420, 740));
        }
        var run = 0;
        for (final trial in trials) {
          run = trial.isGo ? 0 : run + 1;
          expect(run, lessThanOrEqualTo(2), reason: 'level $level');
        }
        expect(engine.windowMs, inInclusiveRange(480, 1100));
      }
    });

    test('shape levels mix colours so colour alone does not help', () {
      final engine = SignalGuardEngine.forLevel(15);
      expect(engine.rule, SignalRule.shape);
      final goTints = engine.trials.where((t) => t.isGo).map((t) => t.tint).toSet();
      expect(goTints, hasLength(2));
    });

    test('responses and timeouts resolve each trial once', () {
      final engine = SignalGuardEngine.forLevel(1, seed: 4);
      for (final trial in engine.trials) {
        final outcome = trial.isGo ? engine.respond(300) : engine.timeout();
        expect(outcome, trial.isGo ? TrialOutcome.hit : TrialOutcome.correctRejection);
      }
      expect(engine.isFinished, isTrue);
      expect(engine.respond(100), isNull);
      expect(engine.timeout(), isNull);
      expect(engine.accuracy, 1);
      expect(engine.passed, isTrue);
      expect(engine.stars, 3);
      expect(engine.meanReactionMs, 300);
      expect(engine.controlMetric, 100);
    });

    test('tapping everything fails the accuracy bar', () {
      final engine = SignalGuardEngine.forLevel(12);
      while (!engine.isFinished) {
        engine.respond(200);
      }
      expect(engine.falseAlarms, engine.trials.where((t) => !t.isGo).length);
      expect(engine.passed, isFalse);
    });
  });
}
