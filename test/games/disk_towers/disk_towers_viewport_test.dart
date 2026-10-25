import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/disk_towers/disk_towers_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('three towers fit without page scrolling on $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: DiskTowersPage(
        floor: 10,
        onComplete: () {},
        onSessionEnd: (_, __, ___) {},
      )));
      await tester.pump();
      expect(find.byKey(const ValueKey('disk-peg-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('disk-peg-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('disk-peg-2')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('selecting towers and restart are safe', (tester) async {
    await tester.pumpWidget(MaterialApp(home: DiskTowersPage(
      floor: 5,
      onComplete: () {},
      onSessionEnd: (_, __, ___) {},
    )));
    await tester.tap(find.byKey(const ValueKey('disk-peg-2')));
    await tester.pump();
    await tester.tap(find.text('RESTART'));
    await tester.pump();
    expect(find.text('0 moves'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
