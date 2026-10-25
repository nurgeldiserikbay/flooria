import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/rule_relay/rule_relay_engine.dart';

void main() {
  group('RuleRelaySession', () {
    test('same seed creates the same rounds', () {
      final first = RuleRelaySession(seed: 90210);
      final second = RuleRelaySession(seed: 90210);

      expect(first.rounds.length, RuleRelaySession.roundCount);
      for (var i = 0; i < first.rounds.length; i++) {
        final a = first.rounds[i];
        final b = second.rounds[i];
        expect(a.rule, b.rule);
        expect(a.target, b.target);
        expect(a.options, b.options);
        expect(a.correctIndex, b.correctIndex);
      }
    });

    test('every generated round has exactly one valid matching card', () {
      final session = RuleRelaySession(seed: 4);

      for (final round in session.rounds) {
        final matching = round.options
            .where((option) =>
                option.valueFor(round.rule) == round.target.valueFor(round.rule))
            .toList();
        expect(matching, [round.correctCard]);
      }
    });

    test('rules stay fixed for three cards and switch at boundaries', () {
      final session = RuleRelaySession(seed: 31);

      for (var block = 0; block < 4; block++) {
        final rule = session.rounds[block * 3].rule;
        expect(session.rounds[block * 3 + 1].rule, rule);
        expect(session.rounds[block * 3 + 2].rule, rule);
        if (block > 0) {
          expect(session.rounds[block * 3].rule,
              isNot(session.rounds[block * 3 - 1].rule));
        }
      }
    });

    test('invalid choices do not change state; valid choices finish once', () {
      final session = RuleRelaySession(seed: 18);
      expect(session.answer(-1), isFalse);
      expect(session.answer(3), isFalse);
      expect(session.round, 0);
      expect(session.correct, 0);

      for (var i = 0; i < RuleRelaySession.roundCount; i++) {
        expect(session.answer(session.current.correctIndex), isTrue);
      }
      expect(session.finished, isTrue);
      expect(session.passed, isTrue);
      expect(session.correct, RuleRelaySession.roundCount);
      expect(session.answer(0), isFalse);
      expect(session.round, RuleRelaySession.roundCount);
    });

    test('passing threshold is measured from actual answers', () {
      final session = RuleRelaySession(seed: 92);

      for (var i = 0; i < RuleRelaySession.roundCount; i++) {
        final round = session.current;
        session.answer(i < RuleRelaySession.passScore
            ? round.correctIndex
            : (round.correctIndex + 1) % round.options.length);
      }

      expect(session.correct, RuleRelaySession.passScore);
      expect(session.passed, isTrue);
    });
  });
}
