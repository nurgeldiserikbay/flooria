import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openCatcher(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('color_catcher');
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
  await tester.pump(const Duration(milliseconds: 80));
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
      testWidgets('Color Catcher level $level on $size', (tester) async {
        viewport(tester, size);
        await openCatcher(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('catcher-board-state')),
          findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Color Catcher moves basket with buttons and swipes',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openCatcher(tester, 1);
    final board = find.byKey(const ValueKey('catcher-board-state'));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Basket in lane 3 of 5'));

    await tester.tap(find.byTooltip('Move right'));
    await tester.pump(const Duration(milliseconds: 70));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Basket in lane 4 of 5'));

    await tester.fling(find.byKey(const ValueKey('catcher-swipe-area')),
      const Offset(-110, 0), 800);
    await tester.pump(const Duration(milliseconds: 70));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Basket in lane 3 of 5'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Color Catcher cells disable animation in reduced motion',
      (tester) async {
    await openCatcher(tester, 1, reducedMotion: true);
    final area = find.byKey(const ValueKey('catcher-swipe-area'));
    expect(tester.widget<AnimatedContainer>(
      find.descendant(of: area, matching: find.byType(AnimatedContainer)).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
