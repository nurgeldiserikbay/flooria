import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/game/light_grid.dart';
import 'package:flooria/game/floor_engine.dart';
import 'package:flooria/game/game_objective.dart';
import 'package:flooria/game/player_stats.dart';
import 'package:flooria/ui/light_grid_page.dart';

void main() {
  test('every generated Light Grid puzzle has a reverse solution', () {
    for (var seed = 0; seed < 80; seed++) {
      final game = LightGridSession(seed: seed);
      expect(game.litCount, greaterThan(0));
      for (final position in game.scrambleMoves.reversed) {
        if (game.finished) break; // Repeated scramble moves can cancel early.
        expect(game.tap(position), isTrue);
      }
      expect(game.litCount, 0);
      expect(game.finished, isTrue);
    }
  });

  test('click affects only the center and orthogonal neighbors', () {
    final game = LightGridSession(seed: 42, scrambleCount: 0);
    expect(game.litCount, greaterThan(0));
    final before = List<bool>.from(game.lights);
    game.tap(4);
    for (var i = 0; i < 9; i++) {
      final distance = (i ~/ 3 - 1).abs() + (i % 3 - 1).abs();
      expect(game.lights[i] != before[i], distance <= 1);
    }
  });

  test('logic progress stores separately from memory', () {
    final stats = PlayerGameStats()..recordLogic(moves: 7);
    final copy = PlayerGameStats.fromJson(stats.toJson());
    expect(copy.logicRuns, 1);
    expect(copy.logicBestMoves, 7);
    expect(copy.memoryRuns, 0);
    expect(copy.skillRatings.firstWhere((s) => s.name == 'Logic').value,
      isNotNull);
  });

  test('Light Grid is in campaign and objective catalog', () {
    expect(const FloorEngine().challengeFor(6).gameId, 'logic');
    expect(const ObjectiveCatalog().forGame('logic').target, 9);
  });

  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Light Grid fits without scrolling on $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: LightGridPage(
        onComplete: () {},
        onSessionEnd: (_) {},
      )));
      await tester.pump(const Duration(milliseconds: 260));
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.text('RESTART'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
