import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/rule_relay/rule_relay_engine.dart';
import 'package:flooria/games/rule_relay/rule_relay_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Rule Relay fits $size and completes without scrolling',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var reports = 0;
      var completions = 0;

      await tester.pumpWidget(MaterialApp(
        home: RuleRelayPage(
          floor: 4,
          onComplete: () => completions++,
          onSessionEnd: (correct, total) {
            reports++;
            expect(correct, inInclusiveRange(0, total));
            expect(total, RuleRelaySession.roundCount);
          },
        ),
      ));
      expect(find.text('Rule Relay'), findsOneWidget);
      final firstRule = RuleRelaySession(seed: 4 * 7919).rounds.first.rule;
      expect(find.text('MATCH BY ${firstRule.name.toUpperCase()}'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(GridView), findsNothing);
      expect(tester.takeException(), isNull);

      final expected = RuleRelaySession(seed: 4 * 7919);
      for (var round = 0; round < RuleRelaySession.roundCount; round++) {
        await tester.tap(find.byKey(ValueKey(
            'rule-option-${expected.rounds[round].correctIndex}')));
        await tester.pump();
      }
      expect(reports, 1);
      expect(completions, 1);
      expect(find.text('PLAY AGAIN'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('practice session reports once and can restart', (tester) async {
    var reports = 0;
    await tester.pumpWidget(MaterialApp(
      home: RuleRelayPage(
        onComplete: () {},
        onSessionEnd: (_, __) => reports++,
      ),
    ));
    for (var round = 0; round < RuleRelaySession.roundCount; round++) {
      await tester.tap(find.byKey(const ValueKey('rule-option-0')));
      await tester.pump();
    }
    expect(reports, 1);
    await tester.tap(find.text('PLAY AGAIN'));
    await tester.pump();
    expect(find.text('1 / 12'), findsOneWidget);
    expect(find.textContaining('MATCH BY '), findsOneWidget);
    expect(reports, 1);
    expect(tester.takeException(), isNull);
  });
}
