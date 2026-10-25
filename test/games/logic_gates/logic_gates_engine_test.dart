import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/logic_gates/logic_gates_engine.dart';

void main() {
  test('all six Boolean gates produce correct truth-table values', () {
    const rules = [
      GateRule(GateKind.and, 0, 1, false),
      GateRule(GateKind.or, 0, 1, false),
      GateRule(GateKind.xor, 0, 1, false),
      GateRule(GateKind.nand, 0, 1, false),
      GateRule(GateKind.nor, 0, 1, false),
      GateRule(GateKind.xnor, 0, 1, false),
    ];
    for (var mask = 0; mask < 4; mask++) {
      final a = (mask & 1) != 0;
      final b = (mask & 2) != 0;
      final inputs = [a, b, false, false];
      final expected = [a && b, a || b, a != b,
        !(a && b), !(a || b), a == b];
      for (var i = 0; i < rules.length; i++) {
        expect(rules[i].evaluate(inputs), expected[i]);
        expect(GateRule(rules[i].kind, 0, 1, true).evaluate(inputs),
          !expected[i]);
      }
    }
  });

  test('every generated target is attainable in all rounds', () {
    for (var seed = -30; seed < 200; seed++) {
      final session = LogicGatesSession(seed: seed);
      final copy = LogicGatesSession(seed: seed);
      for (var stage = 0; stage < 3; stage++) {
        expect(session.rules.map((r) => r.kind).toList(),
          copy.rules.map((r) => r.kind).toList());
        expect(session.target, copy.target);
        expect(session.matched, false, reason: 'stage must need actions');
        expect(session.evaluate(session.witness), session.target);
        for (var i = 0; i < 4; i++) {
          if (session.witness[i]) {
            expect(session.toggle(i), true);
            expect(copy.toggle(i), true);
          }
        }
        expect(session.matched, true);
        expect(session.check(), true);
        expect(copy.check(), true);
        expect(session.round, stage + 1);
      }
      expect(session.complete, true);
      expect(session.check(), false);
      expect(session.toggle(0), false);
    }
  });

  test('bad input does not affect switches or move totals', () {
    final session = LogicGatesSession(seed: 42);
    expect(session.toggle(-1), false);
    expect(session.toggle(4), false);
    expect(session.moves, 0);
    expect(session.switches, [false, false, false, false]);
    expect(() => session.evaluate([true, false]), throwsArgumentError);
  });

  test('wrong check preserves switches, records mistake', () {
    final session = LogicGatesSession(seed: 11);
    expect(session.matched, false);
    expect(session.check(), false);
    expect(session.mistakes, 1);
    expect(session.checks, 1);
    expect(session.round, 0);
    expect(session.switches, [false, false, false, false]);
  });
}
