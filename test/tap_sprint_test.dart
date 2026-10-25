import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/game/tap_sprint.dart';
import 'package:flooria/game/player_stats.dart';
import 'package:flooria/game/floor_engine.dart';
import 'package:flooria/game/game_objective.dart';
import 'package:flooria/ui/tap_sprint_page.dart';

void main() {
  test('tap sprint has all nine numbers exactly once', () {
    final a = TapSprintSession(seed: 18);
    final b = TapSprintSession(seed: 18);
    expect(a.values, b.values);
    expect(a.values.toSet(), <int>{1,2,3,4,5,6,7,8,9});
  });

  test('numbers must be tapped in order and speed record persists', () {
    final game = TapSprintSession(seed: 44);
    expect(game.tap(game.values.indexOf(9)), isFalse);
    expect(game.mistakes, 1);
    for (var n = 1; n <= 9; n++) {
      expect(game.tap(game.values.indexOf(n)), isTrue);
    }
    expect(game.finished, isTrue);
    expect(game.completed, 9);
    final stats = PlayerGameStats();
    stats.recordSpeed(elapsedMillis: 12000, mistakes: game.mistakes);
    final copy = PlayerGameStats.fromJson(stats.toJson());
    expect(copy.speedRuns, 1);
    expect(copy.speedBestMillis, 12000);
    expect(copy.skillRatings.firstWhere((r) => r.name == 'Speed').value, 80);
  });

  test('tap sprint is fifth game in campaign', () {
    expect(const FloorEngine().challengeFor(5).gameId, 'speed');
    expect(const ObjectiveCatalog().forGame('speed').target, 9);
  });

  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('tap sprint is playable without scrolling at $size',
      (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: TapSprintPage(
        onComplete: () {},
        onSessionEnd: (_, __) {},
      )));
      await tester.pump(const Duration(milliseconds: 240));
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.text('RESTART'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
