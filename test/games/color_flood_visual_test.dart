import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/color_flood/color_flood_engine.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openFlood(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('color_flood');
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
      testWidgets('Color Flood level $level on $size', (tester) async {
        viewport(tester, size);
        await openFlood(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('flood-board-state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Color Flood announces tile gains and remaining moves',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openFlood(tester, 1);
    final board = find.byKey(const ValueKey('flood-board-state'));
    final engine = ColorFloodEngine.forLevel(1);
    final before = engine.claimedCount;
    final chosen = (engine.currentColor + 1) % engine.colorCount;
    engine.chooseColor(chosen);

    expect(tester.widget<Semantics>(board).properties.label,
      contains('$before of 100 tiles claimed'));
    await tester.tap(find.byKey(ValueKey('flood-color-$chosen')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('${engine.claimedCount} of 100 tiles claimed'));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('${engine.moveLimit - engine.moves} moves remaining'));
    expect(find.textContaining(engine.claimedCount > before
        ? 'MORE TILES CLAIMED' : 'NO NEW TILES'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Color Flood honors reduced-motion setting',
      (tester) async {
    await openFlood(tester, 1, reducedMotion: true);
    final board = find.byKey(const ValueKey('flood-board-state'));
    expect(tester.widget<TweenAnimationBuilder<double>>(
      find.descendant(of: board,
        matching: find.byType(TweenAnimationBuilder<double>)).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
