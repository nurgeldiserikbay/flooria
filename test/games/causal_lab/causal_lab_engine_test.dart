import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/causal_lab/causal_lab_engine.dart';

void main() {
  group('CausalLabSession', () {
    test('seeded sessions repeat and every observation fits both models', () {
      final first = CausalLabSession(seed: 42, level: 5);
      final second = CausalLabSession(seed: 42, level: 5);
      expect(first.rounds.length, 6);
      expect(first.rounds.map((r) => [r.firstModel, r.secondModel, r.observation]),
          second.rounds.map((r) => [r.firstModel, r.secondModel, r.observation]));
      for (final round in first.rounds) {
        expect(round.firstModel.predict(round.observation.sun, round.observation.water),
            round.secondModel.predict(round.observation.sun, round.observation.water));
        expect(round.experiments.any(round.isInformative), isTrue);
      }
    });

    test('invalid experiments leave round and score unchanged', () {
      final session = CausalLabSession(seed: 11);
      final knownObservation = session.current.observation;
      expect(session.answer(knownObservation), isFalse);
      expect(session.round, 0);
      expect(session.correct, 0);
      expect(session.answer(session.current.experiments.first), isTrue);
      expect(session.round, 1);
    });

    test('informative experiments score and completion stops input', () {
      final session = CausalLabSession(seed: 99);
      for (var i = 0; i < session.roundCount; i++) {
        final round = session.current;
        final best = round.experiments.firstWhere(round.isInformative);
        expect(session.answer(best), isTrue);
      }
      expect(session.finished, isTrue);
      expect(session.correct, session.roundCount);
      expect(session.passed, isTrue);
      expect(session.answer(session.current.experiments.first), isFalse);
    });

    test('pass threshold is four experiments', () {
      final session = CausalLabSession(seed: 123);
      for (var i = 0; i < session.roundCount; i++) {
        final round = session.current;
        final choice = i < CausalLabSession.passScore
            ? round.experiments.firstWhere(round.isInformative)
            : round.experiments.firstWhere((experiment) => !round.isInformative(experiment));
        session.answer(choice);
      }
      expect(session.correct, CausalLabSession.passScore);
      expect(session.passed, isTrue);
    });
  });
}
