import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openMagnet(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('magnetic_room');
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
      testWidgets('Magnetic Room level $level on $size', (tester) async {
        viewport(tester, size);
        await openMagnet(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('magnet-board-state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Magnetic Room reports blocked and successful pulses',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openMagnet(tester, 1);
    final board = find.byKey(const ValueKey('magnet-board-state'));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Core at row 6, column 1'));
    await tester.tap(find.byTooltip('Pulse left'));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.textContaining('BLOCKED'), findsOneWidget);
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Core at row 6, column 1'));

    await tester.tap(find.byTooltip('Pulse right'));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.textContaining('NICE MOVE'), findsOneWidget);
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Core at row 6, column 2'));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('1 pulses used'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Magnetic Room respects reduced-motion preference',
      (tester) async {
    await openMagnet(tester, 1, reducedMotion: true);
    final board = find.byKey(const ValueKey('magnet-board-state'));
    final tiles = tester.widgetList<AnimatedContainer>(
      find.descendant(of: board, matching: find.byType(AnimatedContainer)),
    ).toList();
    expect(tiles, isNotEmpty);
    expect(tiles.every((tile) => tile.duration == Duration.zero), isTrue);
    expect(tester.takeException(), isNull);
  });
}
