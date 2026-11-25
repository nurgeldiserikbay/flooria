import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/core/neuron_progression.dart';
import 'package:flooria/games/color_catcher/color_catcher_engine.dart';
import 'package:flooria/games/match_three/match_three_engine.dart';
import 'package:flooria/games/set_match/set_match_engine.dart';
import 'package:flooria/games/whack_target/whack_target_engine.dart';
import 'package:flooria/ui/game_kit.dart';
import 'package:flooria/ui/neuro_hub_pages.dart';

void main() {
  group('release gating', () {
    test('a fresh save unlocks only the first map node game', () {
      expect(PlayerProgress.unlockAllGamesForQa, isFalse);
      final progress = PlayerProgress();
      expect(progress.unlockedModuleIds, {'pattern_repeat'});
      expect(() => progress.completeStandaloneLevel('tetris', 1, 100),
          throwsStateError);
    });

    test('completing a node adds its children to the library', () {
      final progress = PlayerProgress()..completeNeuron('node_01');
      expect(progress.unlockedModuleIds,
          containsAll(<String>['pattern_repeat', 'number_hunt', 'hue_sort']));
      expect(progress.unlockedModuleIds, isNot(contains('synapse_link')));
    });

    testWidgets('library shows locked games and does not launch them',
        (tester) async {
      final played = <String>[];
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: NeuroGamesPage(
          onTab: (_) {},
          onPlay: played.add,
          favorites: const <String>{},
          onFavorite: (_) {},
          bestStandaloneLevels: const <String, int>{},
          unlockedIds: const {'pattern_repeat'},
        ),
      )));
      await tester.pump();

      expect(find.byKey(const ValueKey('game-locked')), findsWidgets);
      await tester.tap(find.text('Find the Number'));
      await tester.pump();
      expect(played, isEmpty);
      expect(find.text('Reach this game on the map to unlock it'),
          findsOneWidget);

      await tester.tap(find.text('Pattern Repeat'));
      await tester.pump();
      expect(played, ['pattern_repeat']);

      await tester.tap(find.byKey(const ValueKey('random-game')));
      await tester.pump();
      expect(played.last, 'pattern_repeat',
          reason: 'Surprise me only picks unlocked games');
    });
  });

  test('best scores above 999 survive a save round trip', () {
    final progress = PlayerProgress()
      ..completeNeuron('node_01')
      ..completeStandaloneLevel('pattern_repeat', 1, 2450);
    final restored = PlayerProgress.fromJson(progress.toJson());
    expect(restored.bestStandaloneScores['pattern_repeat'], 2450);
    expect(PlayerProgress.fromJson({
      'bestStandaloneLevels': {'pattern_repeat': 5000},
    }).bestStandaloneLevels['pattern_repeat'], 999);
  });

  group('skill metrics', () {
    test('efficiencyMetric maps the 100..1000 score range onto 0..100', () {
      expect(efficiencyMetric(1000), 100);
      expect(efficiencyMetric(1400), 100);
      expect(efficiencyMetric(550), 50);
      expect(efficiencyMetric(100), 0);
      expect(efficiencyMetric(0), 0);
    });

    test('rate-based engine metrics stay within 0..100', () {
      final whack = WhackTargetEngine.forLevel(1)
        ..hits = 3
        ..misses = 1;
      expect(whack.controlMetric, 75);

      final catcher = ColorCatcherEngine.forLevel(1)
        ..caught = 9
        ..strikes = 1;
      expect(catcher.controlMetric, 90);

      final sets = SetMatchEngine.forLevel(1)
        ..setsFound = 2
        ..moves = 4;
      expect(sets.focusMetric, 50);

      final match = MatchThreeEngine.forLevel(1);
      expect(match.planningMetric, 100);
      match.moves = match.moveLimit;
      expect(match.planningMetric, 0);
    });

    test('every game except fixed-outcome ones reports its catalog skill', () {
      // These wins have no per-play variation to measure: the route or tour
      // always fills the board, or the goal is reached at a fixed length.
      const unmeasured = {
        'bubble_shooter', 'knight_tour', 'merge_tiles', 'minefield',
        'number_maze', 'snake', 'tetris', 'zip_route',
      };
      for (final game in GameRegistry.games) {
        final dir = Directory('lib/games/${game.id}');
        final source = dir.listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('_page.dart'))
            .map((file) => file.readAsStringSync())
            .join();
        final reports = source.contains("'${game.skill}':");
        expect(reports, !unmeasured.contains(game.id),
            reason: '${game.id} should '
                '${unmeasured.contains(game.id) ? 'not ' : ''}'
                'report a ${game.skill} metric');
      }
    });
  });
}
