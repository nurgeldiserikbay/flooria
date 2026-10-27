import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/pattern_repeat/pattern_repeat_engine.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/pattern_repeat/pattern_repeat_page.dart';

void main() {
  for (final size in [const Size(360, 640), const Size(390, 844)]) {
    testWidgets('fits ${size.width}x${size.height} without scrolling',
        (tester) async {
      var completed = false;
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: PatternRepeatPage(launch: GameLaunch(
          level: 1,
          mode: GamePlayMode.neuron,
          onComplete: (_) => completed = true,
        )),
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('WATCH THE PATTERN'), findsOneWidget);
      expect(find.byKey(const ValueKey('pattern-status')), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      expect(completed, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('continues to the next level after tapping next level',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final completedLevels = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: PatternRepeatPage(launch: GameLaunch(
        level: 1,
        maxLevel: 2,
        mode: GamePlayMode.standalone,
        onComplete: (result) => completedLevels.add(result.level!),
      )),
    ));

    Future<void> finishLevel(int level) async {
      await tester.pump(const Duration(milliseconds: 380));
      final sequence = PatternRepeatEngine.forLevel(level).sequence;
      for (final cell in sequence) {
        await tester.pump(const Duration(milliseconds: 360));
        await tester.pump(const Duration(milliseconds: 130));
      }
      for (var i = 0; i < sequence.length; i++) {
        await tester.tap(find.byKey(ValueKey('pattern-pad-${sequence[i]}')));
        await tester.pump();
        if (i < sequence.length - 1) {
          await tester.pump(const Duration(milliseconds: 110));
        }
      }
    }

    await finishLevel(1);
    expect(completedLevels, [1]);
    expect(find.text('NEXT LEVEL'), findsOneWidget);

    await tester.tap(find.text('NEXT LEVEL'));
    await tester.pump();
    expect(find.text('Pattern  ·  2'), findsOneWidget);
    expect(find.text('STEP 0 OF 4'), findsOneWidget);

    await finishLevel(2);
    expect(completedLevels, [1, 2]);
    expect(find.text('FINISH'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
