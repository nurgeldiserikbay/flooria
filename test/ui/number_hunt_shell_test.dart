import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/number_hunt/number_hunt_engine.dart';
import 'package:flooria/games/number_hunt/number_hunt_page.dart';
import 'package:flooria/ui/game_kit.dart';

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  for (final size in const [Size(360, 640), Size(390, 844)]) {
    for (final level in const [1, 90]) {
      testWidgets('Number Hunt uses shared shell at level $level on $size',
          (tester) async {
        _viewport(tester, size);
        await tester.pumpWidget(MaterialApp(
          home: NumberHuntPage(launch: GameLaunch(
            level: level,
            mode: GamePlayMode.standalone,
            onComplete: (_) {},
          )),
        ));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('Find the Number'), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byTooltip('Restart'), findsOneWidget);
        expect(find.byKey(const ValueKey('number-hunt-target')),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Number Hunt still reports once and moves to the next level',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    final results = <GameResult>[];
    await tester.pumpWidget(MaterialApp(
      home: NumberHuntPage(launch: GameLaunch(
        level: 1,
        maxLevel: 2,
        mode: GamePlayMode.standalone,
        onComplete: results.add,
      )),
    ));
    final engine = NumberHuntEngine.forLevel(1);
    for (final round in engine.rounds) {
      await tester.tap(find.byKey(ValueKey('number-cell-${round.targetIndex}')));
      await tester.pump(const Duration(milliseconds: 170));
      expect(tester.takeException(), isNull);
    }
    expect(results, hasLength(1));
    expect(results.single.level, 1);
    expect(find.text('NEXT LEVEL'), findsOneWidget);
    await tester.tap(find.text('NEXT LEVEL'));
    await tester.pump(const Duration(milliseconds: 170));
    expect(find.text('LEVEL 2'), findsOneWidget);
    expect(find.byType(GameScaffold), findsOneWidget);
    expect(results, hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
