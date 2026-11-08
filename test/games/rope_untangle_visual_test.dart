import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/rope_untangle/rope_untangle_engine.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openRope(WidgetTester tester, int level) async {
  final game = GameRegistry.byId('rope_untangle');
  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) => game.buildPage(
      context,
      GameLaunch(level: level, mode: GamePlayMode.standalone,
        onComplete: (_) {}),
    )),
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
      testWidgets('Rope Untangle level $level at $size', (tester) async {
        viewport(tester, size);
        await openRope(tester, level);
        final engine = RopeUntangleEngine.forLevel(level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        final board = find.byKey(const ValueKey('rope-board-state'));
        expect(tester.widget<Semantics>(board).properties.label,
          contains('${engine.crossingCount} crossings remaining'));
        expect(find.byKey(const ValueKey('rope-board')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Rope Untangle board announces active joint on drag',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openRope(tester, 1);
    final engine = RopeUntangleEngine.forLevel(1);
    final board = find.byKey(const ValueKey('rope-board'));
    final bounds = tester.getRect(board);
    final point = engine.positions.first;
    final start = bounds.topLeft + Offset(
      bounds.width * point.x, bounds.height * point.y);
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(45, 20));
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.widget<Semantics>(
      find.byKey(const ValueKey('rope-board-state')),
    ).properties.label, contains('moving joint 1'));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.widget<Semantics>(
      find.byKey(const ValueKey('rope-board-state')),
    ).properties.label, isNot(contains('moving joint 1')));
    expect(tester.takeException(), isNull);
  });
}
