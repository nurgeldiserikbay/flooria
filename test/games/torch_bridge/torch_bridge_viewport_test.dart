import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/torch_bridge/torch_bridge_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Torch Bridge fits scroll-free viewport $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: TorchBridgePage(
        floor: 10,
        onComplete: () {},
        onSessionEnd: (_, __, ___) {},
      )));
      await tester.pump();
      expect(find.byKey(const ValueKey('torch-traveler-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('torch-action')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(GridView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('select, cross and reset a bridge', (tester) async {
    await tester.pumpWidget(MaterialApp(home: TorchBridgePage(
      floor: 7,
      onComplete: () {},
      onSessionEnd: (_, __, ___) {},
    )));
    await tester.tap(find.byKey(const ValueKey('torch-traveler-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('torch-action')));
    await tester.pump();
    expect(find.text('1 crossings'), findsOneWidget);
    await tester.tap(find.byTooltip('Restart'));
    await tester.pump();
    expect(find.text('0 crossings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
