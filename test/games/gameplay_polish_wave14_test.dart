import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/billiards/billiards_engine.dart';
import 'package:flooria/ui/game_kit.dart';

void setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> openGame(WidgetTester tester, String id, int level) async {
  final game = GameRegistry.byId(id);
  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) => game.buildPage(
      context,
      GameLaunch(level: level, mode: GamePlayMode.standalone,
        onComplete: (_) {}),
    )),
  ));
  await tester.pump(const Duration(milliseconds: 120));
}

void main() {
  for (final id in const ['billiards', 'stacker']) {
    for (final size in const [Size(360, 640), Size(390, 844)]) {
      for (final level in const [1, 90]) {
        testWidgets('$id level $level at $size', (tester) async {
          setViewport(tester, size);
          await openGame(tester, id, level);
          expect(find.byType(GameScaffold), findsOneWidget);
          expect(find.text('LEVEL $level'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip('Restart'));
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.text('LEVEL $level'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('Billiard Order announces next target and gives shot feedback',
      (tester) async {
    setViewport(tester, const Size(390, 844));
    await openGame(tester, 'billiards', 1);
    final engine = BilliardsEngine.forLevel(1);
    final target = engine.targets.first;
    final table = find.byKey(const ValueKey('billiard-table-state'));
    expect(tester.widget<Semantics>(table).properties.label,
      contains('Next ball 1'));
    expect(tester.widget<Semantics>(table).properties.label,
      contains('Ball 1'));

    // Take the first legal shot and confirm both feedback and next target.
    await tester.tap(find.byTooltip('Shoot ${target.direction.name}'));
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('GREAT SHOT · FIND NUMBER 2'), findsOneWidget);
    expect(tester.widget<Semantics>(table).properties.label,
      contains('Next ball 2'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Stacker describes progress and allows dropping a block',
      (tester) async {
    setViewport(tester, const Size(390, 844));
    await openGame(tester, 'stacker', 1);
    final board = find.byKey(const ValueKey('stacker-board-state'));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('0 of 8 layers'));
    expect(find.byKey(const ValueKey('stacker-board')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stacker-board')));
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('1 of 8 layers'));
    expect(tester.takeException(), isNull);
  });
}
