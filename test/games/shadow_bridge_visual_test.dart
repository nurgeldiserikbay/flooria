import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openShadow(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('shadow_bridge');
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
      testWidgets('Shadow Bridge level $level on $size', (tester) async {
        viewport(tester, size);
        await openShadow(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('shadow-board-state')), findsOneWidget);
        expect(find.byTooltip('Move up'), findsOneWidget);
        expect(find.byTooltip('Move down'), findsOneWidget);
        expect(find.byTooltip('Move left'), findsOneWidget);
        expect(find.byTooltip('Move right'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Shadow Bridge explains blocked moves and lamp switches',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openShadow(tester, 1);
    final board = find.byKey(const ValueKey('shadow-board-state'));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Sunlight, player at row 3, column 1'));

    await tester.tap(find.byTooltip('Move left'));
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.textContaining('PATH BLOCKED'), findsOneWidget);

    await tester.tap(find.byTooltip('Move up'));
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('player at row 2, column 1'));
    expect(find.textContaining('GOOD STEP'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Switch between sunlight and moonlight'));
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('MOONLIGHT'), findsOneWidget);
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Moonlight'));
    expect(find.textContaining('LIGHT CHANGED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shadow Bridge cell transitions honor reduced motion',
      (tester) async {
    await openShadow(tester, 1, reducedMotion: true);
    final board = find.byKey(const ValueKey('shadow-board-state'));
    final tiles = tester.widgetList<AnimatedContainer>(
      find.descendant(of: board, matching: find.byType(AnimatedContainer)),
    ).toList();
    expect(tiles, isNotEmpty);
    expect(tiles.every((tile) => tile.duration == Duration.zero), isTrue);
    expect(tester.takeException(), isNull);
  });
}
