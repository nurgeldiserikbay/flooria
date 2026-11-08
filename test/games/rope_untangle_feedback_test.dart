import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/rope_untangle/rope_untangle_engine.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openRope(WidgetTester tester, int level) async {
  final game = GameRegistry.byId('rope_untangle');
  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) => game.buildPage(
      context, GameLaunch(level: level, mode: GamePlayMode.standalone,
        onComplete: (_) {}))),
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
      testWidgets('Rope Untangle level $level on $size', (tester) async {
        viewport(tester, size);
        await openRope(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('rope-board-state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Rope Untangle reports drag progress to accessibility',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openRope(tester, 1);
    final board = find.byKey(const ValueKey('rope-board'));
    final state = find.byKey(const ValueKey('rope-board-state'));
    final engine = RopeUntangleEngine.forLevel(1);
    final point = engine.positions.first;
    final topLeft = tester.getTopLeft(board);
    final size = tester.getSize(board);
    expect(tester.widget<Semantics>(state).properties.label,
      contains('${engine.crossingCount} crossings remaining'));

    final start = topLeft + Offset(point.x * size.width, point.y * size.height);
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(35, 25));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<Semantics>(state).properties.label,
      contains('Moving joint 1'));
    await gesture.moveBy(const Offset(12, 5));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<Semantics>(state).properties.label,
      contains('drag updates'));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
