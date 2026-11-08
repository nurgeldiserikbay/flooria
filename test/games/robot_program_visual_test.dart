import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/robot_program/robot_program_engine.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openRobot(WidgetTester tester, {
  int level = 1,
  bool reduceMotion = false,
}) async {
  final game = GameRegistry.byId('robot_program');
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Builder(builder: (context) => game.buildPage(
        context,
        GameLaunch(
          level: level,
          mode: GamePlayMode.standalone,
          onComplete: (_) {},
        ),
      )),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 250));
}

void main() {
  for (final size in const [Size(360, 640), Size(390, 844)]) {
    for (final level in const [1, 90]) {
      testWidgets('Robot Program level $level at $size', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await openRobot(tester, level: level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('robot-cell-0')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('robot cells describe walls, start, exit, and heading',
      (tester) async {
    await openRobot(tester);
    final engine = RobotProgramEngine.forLevel(1);
    final start = tester.widget<Semantics>(
      find.byKey(ValueKey('robot-cell-${engine.start}')),
    );
    expect(start.properties.label, contains('start'));
    expect(start.properties.label, contains('robot facing north'));
    expect(tester.widget<Semantics>(
      find.byKey(ValueKey('robot-cell-${engine.goal}')),
    ).properties.label, contains('exit'));
    expect(tester.widget<Semantics>(
      find.byKey(ValueKey('robot-cell-${engine.walls.first}')),
    ).properties.label, contains('wall'));

    expect(tester.widget<Semantics>(
      find.byKey(const ValueKey('robot-program-slot-0')),
    ).properties.label, contains('empty'));
    await tester.tap(find.text('MOVE'));
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.widget<Semantics>(
      find.byKey(const ValueKey('robot-program-slot-0')),
    ).properties.label, contains('move forward'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Robot Program honors reduced motion on board and command',
      (tester) async {
    await openRobot(tester, reduceMotion: true);
    final cell = find.byKey(const ValueKey('robot-cell-0'));
    final animatedCell = tester.widget<AnimatedContainer>(
      find.descendant(of: cell, matching: find.byType(AnimatedContainer)),
    );
    expect(animatedCell.duration, Duration.zero);
    final slot = find.byKey(const ValueKey('robot-program-slot-0'));
    final animatedSlot = tester.widget<AnimatedContainer>(
      find.descendant(of: slot, matching: find.byType(AnimatedContainer)),
    );
    expect(animatedSlot.duration, Duration.zero);
  });
}
