import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/ink_switch/ink_switch_engine.dart';
import 'package:flooria/games/ink_switch/ink_switch_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Ink Switch fits $size without page scrolling', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(home: InkSwitchPage(
        floor: 2,
        onComplete: () {},
        onSessionEnd: (_, __) {},
      )));

      expect(find.text('Ink Switch'), findsOneWidget);
      expect(find.text('TAP THE COLOR OF THE LETTERS'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(OutlinedButton), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a correct campaign run reports once and blocks duplicate completion', (tester) async {
    var reports = 0;
    var completions = 0;
    await tester.pumpWidget(MaterialApp(home: InkSwitchPage(
      floor: 1,
      onComplete: () => completions++,
      onSessionEnd: (correct, mistakes) {
        reports++;
        expect(correct, InkSwitchSession.roundCount);
        expect(mistakes, 0);
      },
    )));
    final expected = InkSwitchSession(seed: 104730);

    for (var index = 0; index < InkSwitchSession.roundCount; index++) {
      await tester.tap(find.byKey(ValueKey<String>(
        'ink-option-$index-${expected.current.correctIndex}',
      )));
      await tester.pump();
    }

    expect(reports, 1);
    expect(completions, 1);
    expect(find.text('Color control complete!'), findsOneWidget);
    expect(find.text('TOWER LEVEL COMPLETE'), findsOneWidget);
    expect(find.text('PLAY AGAIN'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('practice can restart after recording one completed session', (tester) async {
    var reports = 0;
    await tester.pumpWidget(MaterialApp(home: InkSwitchPage(
      onComplete: () {},
      onSessionEnd: (_, __) => reports++,
    )));
    for (var index = 0; index < InkSwitchSession.roundCount; index++) {
      await tester.tap(find.byKey(ValueKey<String>('ink-option-$index-0')));
      await tester.pump();
    }
    expect(reports, 1);
    await tester.tap(find.text('PLAY AGAIN'));
    await tester.pump();
    expect(find.text('1 / 10'), findsOneWidget);
    expect(reports, 1);
    expect(tester.takeException(), isNull);
  });
}
