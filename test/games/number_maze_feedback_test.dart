import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/number_maze/number_maze_engine.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openMaze(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('number_maze');
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: Builder(builder: (context) => game.buildPage(
        context, GameLaunch(level: level, mode: GamePlayMode.standalone,
          onComplete: (_) {}))),
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
      testWidgets('Number Maze level $level at $size', (tester) async {
        viewport(tester, size);
        await openMaze(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('number-maze-progress')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Number Maze explains energy change and forbidden moves',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openMaze(tester, 1);
    final engine = NumberMazeEngine.forLevel(1);
    final progress = find.byKey(const ValueKey('number-maze-progress'));
    expect(tester.widget<Semantics>(progress).properties.label,
      contains('Energy ${engine.energy}'));

    await tester.tap(find.byKey(const ValueKey('maze-cell-2')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('MOVE ONE SPACE'), findsOneWidget);
    expect(tester.widget<Semantics>(progress).properties.label,
      contains('0 steps taken'));

    await tester.tap(find.byKey(const ValueKey('maze-cell-1')));
    engine.enter(1);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('ENERGY +1'), findsOneWidget);
    expect(tester.widget<Semantics>(progress).properties.label,
      contains('Energy ${engine.energy}'));
    expect(tester.widget<Semantics>(progress).properties.label,
      contains('1 steps taken'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Number Maze honors reduced motion', (tester) async {
    await openMaze(tester, 1, reducedMotion: true);
    final cell = find.byKey(const ValueKey('maze-cell-0'));
    expect(tester.widget<AnimatedScale>(
      find.descendant(of: cell, matching: find.byType(AnimatedScale)).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
