import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/continuous_maze/continuous_maze_engine.dart';
import 'package:flooria/games/continuous_maze/continuous_maze_page.dart';

void main() {
  for (final size in [const Size(360, 640), const Size(390, 844)]) {
    testWidgets('fits ${size.width}x${size.height} without layout errors',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: ContinuousMazePage(launch: GameLaunch(
          level: 1,
          mode: GamePlayMode.neuron,
          onComplete: (_) {},
        )),
      ));

      expect(find.byKey(const ValueKey('continuous-maze-board')), findsOneWidget);
      expect(find.text('TRACE THE MAZE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('requires one continuous drag and advances to the next level',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final completed = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: ContinuousMazePage(launch: GameLaunch(
        level: 1,
        maxLevel: 2,
        mode: GamePlayMode.standalone,
        onComplete: (result) => completed.add(result.level!),
      )),
    ));

    Future<void> traceLevel(int level) async {
      final maze = ContinuousMazeEngine.forLevel(level);
      final bounds = tester.getRect(find.byKey(
          const ValueKey('continuous-maze-board')));
      Offset center(MazeCell cell) => Offset(
            bounds.left + (cell.column + .5) * bounds.width / maze.side,
            bounds.top + (cell.row + .5) * bounds.height / maze.side,
          );
      final gesture = await tester.startGesture(center(maze.start));
      await tester.pump(const Duration(milliseconds: 30));
      for (final cell in maze.solution.skip(1)) {
        await gesture.moveTo(center(cell), time: const Duration(milliseconds: 80));
        await tester.pump(const Duration(milliseconds: 80));
      }
      await gesture.up();
      await tester.pump();
    }

    await traceLevel(1);
    expect(completed, [1]);
    expect(find.text('MAZE COMPLETE'), findsOneWidget);
    expect(find.text('NEXT LEVEL'), findsOneWidget);

    await tester.tap(find.text('NEXT LEVEL'));
    await tester.pump();
    expect(find.text('One Stroke  ·  2'), findsOneWidget);

    await traceLevel(2);
    expect(completed, [1, 2]);
    expect(find.text('FINISH'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lifting before the exit clears the partial trace',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: ContinuousMazePage(launch: GameLaunch(
        level: 1,
        mode: GamePlayMode.neuron,
        onComplete: (_) {},
      )),
    ));

    final maze = ContinuousMazeEngine.forLevel(1);
    final bounds = tester.getRect(find.byKey(
        const ValueKey('continuous-maze-board')));
    Offset center(MazeCell cell) => Offset(
          bounds.left + (cell.column + .5) * bounds.width / maze.side,
          bounds.top + (cell.row + .5) * bounds.height / maze.side,
        );
    final gesture = await tester.startGesture(center(maze.start));
    await tester.pump(const Duration(milliseconds: 30));
    await gesture.moveTo(center(maze.solution[1]));
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.up();
    await tester.pump();

    expect(find.text('Keep your finger down until you reach the exit.'),
        findsOneWidget);
    expect(find.text('0 steps  ·  5 × 5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
