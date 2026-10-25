import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/parking_escape/parking_escape_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Parking Escape fits mobile viewport $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: ParkingEscapePage(
        floor: 10,
        onComplete: () {},
        onSessionEnd: (_, __) {},
      )));
      await tester.pump();
      expect(find.byKey(const ValueKey('parking-car-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('parking-positive')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(GridView), findsNothing);
      expect(find.text('RESTART'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('game restart restores moves', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ParkingEscapePage(
      floor: 9,
      onComplete: () {},
      onSessionEnd: (_, __) {},
    )));
    await tester.tap(find.byKey(const ValueKey('parking-positive')));
    await tester.pump();
    await tester.tap(find.text('RESTART'));
    await tester.pump();
    expect(find.text('0 moves'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
