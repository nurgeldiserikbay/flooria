import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/pendulum_drop/pendulum_drop_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('pendulum scene fits on $size without scrolling', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: PendulumDropPage(
        floor: 10,
        onComplete: () {},
        onSessionEnd: (_, __) {},
      )));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byKey(const ValueKey('pendulum-field')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(GridView), findsNothing);
      expect(find.text('DROP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('drop starts a single projectile and restart clears attempts',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: PendulumDropPage(
      floor: 4,
      onComplete: () {},
      onSessionEnd: (_, __) {},
    )));
    await tester.tap(find.byKey(const ValueKey('pendulum-drop-button')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('1 drops'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('pendulum-drop-button')));
    expect(button.onPressed, isNull);
    await tester.tap(find.byTooltip('Restart'));
    await tester.pump();
    expect(find.text('0 drops'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
