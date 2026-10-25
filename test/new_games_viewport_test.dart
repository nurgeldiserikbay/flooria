import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/ui/memory_pairs_page.dart';
import 'package:flooria/ui/color_spot_page.dart';

void main() {
  for (final screen in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Memory Pairs fits a small screen $screen', (tester) async {
      tester.view.physicalSize = screen;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: MemoryPairsPage(
        onComplete: () {},
        onSessionEnd: (_, __) {},
      )));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('RESTART'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Color Spot fits a small screen $screen', (tester) async {
      tester.view.physicalSize = screen;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: ColorSpotPage(
        onComplete: () {},
        onSessionEnd: (_, __) {},
      )));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('RESTART'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
