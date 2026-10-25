import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/beat_bloom/beat_bloom_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('beat scene fits on $size without scrolling', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: BeatBloomPage(
          floor: 10,
          onComplete: () {},
          onSessionEnd: (_, __) {},
        ),
      ));
      await tester.pump(const Duration(milliseconds: 80));

      expect(find.text('Beat Bloom'), findsOneWidget);
      expect(find.byKey(const ValueKey('beat-bloom-target')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(GridView), findsNothing);
      expect(find.text('0 / 6 TAPS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('six taps unlock the next rhythm', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BeatBloomPage(
        onComplete: () {},
        onSessionEnd: (_, __) {},
      ),
    ));

    final action = find.byKey(const ValueKey('beat-bloom-action'));
    expect(tester.widget<FilledButton>(action).onPressed, isNull);
    for (var tap = 0; tap < 6; tap++) {
      await tester.tap(find.byKey(const ValueKey('beat-bloom-target')));
      await tester.pump();
    }
    expect(find.text('NEXT RHYTHM'), findsOneWidget);
    await tester.tap(action);
    await tester.pump();
    expect(find.textContaining('RHYTHM 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
