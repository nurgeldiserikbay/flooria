import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/word_bridge/word_bridge_engine.dart';
import 'package:flooria/games/word_bridge/word_bridge_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Word Bridge fits $size without scrolling', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(home: WordBridgePage(
        floor: 4,
        onComplete: () {},
        onSessionEnd: (_, __) {},
      )));

      expect(find.text('Word Bridge'), findsOneWidget);
      expect(find.text('FIND THE WORD THAT COMPLETES THE SAME RELATIONSHIP'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(OutlinedButton), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('campaign completion reports the score once', (tester) async {
    var reports = 0;
    var completions = 0;
    await tester.pumpWidget(MaterialApp(home: WordBridgePage(
      floor: 2,
      onComplete: () => completions++,
      onSessionEnd: (correct, mistakes) {
        reports++;
        expect(correct, WordBridgeSession.roundCount);
        expect(mistakes, 0);
      },
    )));
    final expected = WordBridgeSession(seed: 6507);

    for (var index = 0; index < WordBridgeSession.roundCount; index++) {
      final answer = expected.current.correctIndex;
      await tester.tap(find.byKey(ValueKey<String>('word-bridge-option-$index-$answer')));
      await tester.pump();
      expect(expected.answer(answer), isTrue);
    }

    expect(reports, 1);
    expect(completions, 1);
    expect(find.text('Bridge builder!'), findsOneWidget);
    expect(find.text('TOWER LEVEL COMPLETE'), findsOneWidget);
    expect(find.text('PLAY AGAIN'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
