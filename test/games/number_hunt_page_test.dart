import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/number_hunt/number_hunt_engine.dart';
import 'package:flooria/games/number_hunt/number_hunt_page.dart';

void main() {
  for (final size in [const Size(360, 640), const Size(390, 844)]) {
    testWidgets('fits ${size.width}x${size.height} without scrolling',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: NumberHuntPage(launch: GameLaunch(
          level: 1,
          mode: GamePlayMode.neuron,
          onComplete: (_) {},
        )),
      ));

      expect(find.byKey(const ValueKey('number-hunt-target')), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('ROUND 1 / 5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('advances to the next level after all targets are found',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final completedLevels = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: NumberHuntPage(launch: GameLaunch(
        level: 1,
        maxLevel: 2,
        mode: GamePlayMode.standalone,
        onComplete: (result) => completedLevels.add(result.level!),
      )),
    ));

    Future<void> finishLevel(int level) async {
      final engine = NumberHuntEngine.forLevel(level);
      for (final round in engine.rounds) {
        await tester.tap(find.byKey(ValueKey('number-cell-${round.targetIndex}')));
        await tester.pump();
      }
    }

    await finishLevel(1);
    expect(completedLevels, [1]);
    expect(find.text('NEXT LEVEL'), findsOneWidget);

    await tester.tap(find.text('NEXT LEVEL'));
    await tester.pump();
    expect(find.text('Find the Number  ·  2'), findsOneWidget);
    expect(find.text('ROUND 1 / 5'), findsOneWidget);

    await finishLevel(2);
    expect(completedLevels, [1, 2]);
    expect(find.text('FINISH'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('largest board fits the compact phone viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: NumberHuntPage(launch: GameLaunch(
        level: 100,
        mode: GamePlayMode.neuron,
        onComplete: (_) {},
      )),
    ));

    expect(find.byType(GridView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
