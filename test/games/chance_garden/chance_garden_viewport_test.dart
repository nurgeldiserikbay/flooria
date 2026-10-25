import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/chance_garden/chance_garden_engine.dart';
import 'package:flooria/games/chance_garden/chance_garden_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Chance Garden fits $size without scrolling', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(home: ChanceGardenPage(
        floor: 4,
        onComplete: () {},
        onSessionEnd: (_, __) {},
      )));

      expect(find.text('Chance Garden'), findsOneWidget);
      expect(find.text('COMPARE THE SAMPLE WITH EACH TEN-BEAD JAR'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byKey(const ValueKey<String>('chance-answer-0-0')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('chance-answer-0-1')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('correct campaign answers report and complete once', (tester) async {
    var reports = 0;
    var completions = 0;
    await tester.pumpWidget(MaterialApp(home: ChanceGardenPage(
      floor: 1,
      onComplete: () => completions++,
      onSessionEnd: (correct, mistakes) {
        reports++;
        expect(correct, ChanceGardenSession.roundCount);
        expect(mistakes, 0);
      },
    )));
    final expected = ChanceGardenSession(seed: 7920);

    for (var index = 0; index < ChanceGardenSession.roundCount; index++) {
      final answer = expected.current.correctJarIndex;
      await tester.tap(find.byKey(ValueKey<String>('chance-answer-$index-$answer')));
      await tester.pump();
      expect(expected.answer(answer), isTrue);
    }

    expect(reports, 1);
    expect(completions, 1);
    expect(find.text('A sharp prediction!'), findsOneWidget);
    expect(find.text('TOWER LEVEL COMPLETE'), findsOneWidget);
    expect(find.text('PLAY AGAIN'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
