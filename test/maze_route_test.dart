import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/game/maze_route.dart';
import 'package:flooria/game/floor_engine.dart';
import 'package:flooria/game/game_objective.dart';
import 'package:flooria/game/player_stats.dart';
import 'package:flooria/ui/maze_route_page.dart';

void main() {
  test('generated mazes have connected reciprocal passages and valid routes', () {
    for (var seed = 0; seed < 90; seed++) {
      final maze = MazeRouteSession(seed: seed);
      expect(maze.passages.length, 36);
      for (var cell = 0; cell < maze.passages.length; cell++) {
        for (var direction = 0; direction < 4; direction++) {
          if (!maze.canMove(cell, direction)) continue;
          final neighbor = maze.neighbor(cell, direction);
          expect(neighbor, isNotNull);
          expect(maze.canMove(neighbor!, (direction + 2) % 4), isTrue);
        }
      }
      final route = maze.solution();
      expect(route, isNotEmpty);
      expect(maze.position, 0);
      for (final direction in route) {
        expect(maze.step(direction), isTrue);
      }
      expect(maze.finished, isTrue);
      expect(maze.moves, route.length);
    }
  });

  test('invalid directions and blocked moves cannot skip walls', () {
    final maze = MazeRouteSession(seed: 17);
    expect(maze.step(-1), isFalse);
    expect(maze.step(4), isFalse);
    expect(maze.step(0), isFalse); // top-left has no north neighbor
    expect(maze.position, 0);
    expect(maze.moves, 0);
  });

  test('maze schedule, objective and recorded efficiency', () {
    expect(const FloorEngine().challengeFor(9).gameId, 'maze');
    expect(const ObjectiveCatalog().forGame('maze').target, 1);
    final stats = PlayerGameStats.fromJson({'mergeRuns': 3});
    stats.recordMaze(moves: 18, shortest: 12);
    stats.recordMaze(moves: 12, shortest: 12);
    final restored = PlayerGameStats.fromJson(stats.toJson());
    expect(restored.mazeRuns, 2);
    expect(restored.mazeBestExcessSteps, 0);
    expect(restored.mergeRuns, 3);
  });

  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('maze field and navigation fit without scrolling on $size',
      (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: MazeRoutePage(
        onComplete: () {},
        onSessionEnd: (_, __) {},
      )));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byKey(const ValueKey('maze-direction-0')), findsOneWidget);
      expect(find.text('NEW MAZE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
