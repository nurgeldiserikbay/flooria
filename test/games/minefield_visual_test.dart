import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openMinefield(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('minefield');
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: Builder(builder: (context) => game.buildPage(
        context,
        GameLaunch(
          level: level,
          mode: GamePlayMode.standalone,
          onComplete: (_) {},
        ),
      )),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 120));
}

void viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  for (final size in const [Size(360, 640), Size(390, 844)]) {
    for (final level in const [1, 90]) {
      testWidgets('Minefield level $level at $size', (tester) async {
        viewport(tester, size);
        await openMinefield(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('mine-cell-state-0')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Flag mode lets tap place and remove a marker',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openMinefield(tester, 1);
    final cell = find.byKey(const ValueKey('mine-cell-state-0'));
    expect(tester.widget<Semantics>(cell).properties.label,
        contains('covered'));
    await tester.tap(find.byTooltip('Toggle flag mode'));
    await tester.pump(const Duration(milliseconds: 130));
    expect(find.textContaining('FLAG MODE'), findsOneWidget);
    await tester.tap(cell);
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.widget<Semantics>(cell).properties.label,
        contains('flagged'));
    await tester.tap(cell);
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.widget<Semantics>(cell).properties.label,
        contains('covered'));
    await tester.tap(find.byTooltip('Toggle flag mode'));
    await tester.pump(const Duration(milliseconds: 130));
    expect(find.textContaining('TAP TO REVEAL'), findsOneWidget);
    await tester.tap(cell);
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.widget<Semantics>(cell).properties.label,
        isNot(contains('covered')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Minefield reduced motion disables cell animations',
      (tester) async {
    await openMinefield(tester, 1, reducedMotion: true);
    final cell = find.byKey(const ValueKey('mine-cell-state-0'));
    expect(tester.widget<AnimatedContainer>(
      find.descendant(of: cell, matching: find.byType(AnimatedContainer)).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
