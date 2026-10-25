import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/map_tints/map_tints_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Map Tints graph fits phone viewport $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: MapTintsPage(
        floor: 13,
        onComplete: () {},
        onSessionEnd: (_, __, ___) {},
      )));
      await tester.pump();
      expect(find.byKey(const ValueKey('map-tints-node-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('map-tints-check')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(GridView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('color selection and restart preserve responsive layout',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: MapTintsPage(
      floor: 9,
      onComplete: () {},
      onSessionEnd: (_, __, ___) {},
    )));
    await tester.tap(find.byKey(const ValueKey('map-tints-node-1')));
    await tester.pump();
    await tester.tap(find.byTooltip('Restart'));
    await tester.pump();
    expect(find.text('0 changes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
