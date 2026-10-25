import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/game/pattern_echo.dart';
import 'package:flooria/game/player_stats.dart';
import 'package:flooria/game/floor_engine.dart';
import 'package:flooria/game/game_objective.dart';
import 'package:flooria/ui/pattern_echo_page.dart';

void main() {
  test('Pattern Echo generates repeatable valid pads for every stage', () {
    final a = PatternEchoSession(seed: 31);
    final b = PatternEchoSession(seed: 31);
    for (var stage = 0; stage < PatternEchoSession.stages; stage++) {
      expect(a.pattern, b.pattern);
      expect(a.pattern.length, stage + 2);
      expect(a.pattern.every((pad) => pad >= 0 && pad < 4), isTrue);
      final pattern = List<int>.from(a.pattern);
      for (final pad in pattern) {
        a.input(pad);
        b.input(pad);
      }
    }
    expect(a.complete, isTrue);
  });

  test('Wrong input resets only current stage and counts mistakes', () {
    final game = PatternEchoSession(seed: 22);
    final first = game.pattern.first;
    expect(game.input(first), 0);
    expect(game.cursor, 1);
    expect(game.input((game.pattern[1] + 1) % 4), -1);
    expect(game.stage, 0);
    expect(game.cursor, 0);
    expect(game.mistakes, 1);
  });

  test('Completed stages persist in dedicated saved metrics', () {
    final stats = PlayerGameStats();
    stats.recordPatternEcho(stages: 3, mistakes: 2);
    stats.recordPatternEcho(stages: 3, mistakes: 1);
    final restored = PlayerGameStats.fromJson(stats.toJson());
    expect(restored.echoRuns, 2);
    expect(restored.echoBestMistakes, 1);
    expect(restored.memoryRuns, 0);
  });

  test('Pattern Echo is campaign node seven with objective', () {
    expect(const FloorEngine().challengeFor(7).gameId, 'pattern');
    expect(const ObjectiveCatalog().forGame('pattern').target, 3);
  });

  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Pattern Echo is visible without scrolling on $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: PatternEchoPage(
        onComplete: () {},
        onSessionEnd: (_, __) {},
      )));
      // Advance each async light pulse; a single large pump leaves pending
      // fake-async timers because subsequent pulses are scheduled later.
      for (var i = 0; i < 9; i++) {
        await tester.pump(const Duration(milliseconds: 600));
      }
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.text('RESTART'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
