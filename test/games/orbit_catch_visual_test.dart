import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openOrbit(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('orbit_catch');
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: Builder(builder: (context) => game.buildPage(
        context,
        GameLaunch(level: level, mode: GamePlayMode.standalone,
          onComplete: (_) {}),
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
      testWidgets('Orbit Catch level $level on $size', (tester) async {
        viewport(tester, size);
        await openOrbit(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('orbit-board-state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Orbit Catch announces lane changes and move totals',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openOrbit(tester, 1);
    final board = find.byKey(const ValueKey('orbit-board-state'));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Orbit 1 of 2, sector 1'));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('0 moves used'));
    expect(find.text('SWITCH ORBIT'), findsOneWidget);

    await tester.tap(find.text('SWITCH ORBIT'));
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Orbit 2 of 2'));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('1 moves used'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Orbit Catch motion can be disabled', (tester) async {
    await openOrbit(tester, 1, reducedMotion: true);
    expect(tester.widget<TweenAnimationBuilder<double>>(
      find.descendant(
        of: find.byKey(const ValueKey('orbit-board-state')),
        matching: find.byType(TweenAnimationBuilder<double>),
      ).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
