import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openRail(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('rail_router');
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
  await tester.pump(const Duration(milliseconds: 100));
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
      testWidgets('Rail Router level $level on $size', (tester) async {
        viewport(tester, size);
        await openRail(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('rail-board-state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Rail Router explains switching and advancing trains',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openRail(tester, 1);
    final board = find.byKey(const ValueKey('rail-board-state'));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Time 0'));
    await tester.tap(find.byKey(const ValueKey('rail-route-0')));
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.textContaining('TRAIN 1 USES THE BYPASS'), findsOneWidget);
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Train 1 bypass'));
    await tester.tap(find.byKey(const ValueKey('rail-advance')));
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Time 1'));
    expect(find.textContaining('TRAINS MOVING'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rail Router respects reduced-motion setting',
      (tester) async {
    await openRail(tester, 1, reducedMotion: true);
    final board = find.byKey(const ValueKey('rail-board-state'));
    expect(tester.widget<TweenAnimationBuilder<double>>(
      find.descendant(
        of: board,
        matching: find.byType(TweenAnimationBuilder<double>),
      ).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
