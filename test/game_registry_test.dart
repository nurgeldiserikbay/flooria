import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/game/floor_engine.dart';
import 'package:flooria/game/game_objective.dart';
import 'package:flooria/ui/merge_page.dart';
import 'package:flooria/ui/sequence_page.dart';

void main() {
  test('every registered game ID is unique and metadata complete', () {
    final games = GameRegistry.games;
    expect(games.length, 12);
    expect(games.map((game) => game.id).toSet().length, games.length);
    for (final game in games) {
      expect(game.id, isNotEmpty);
      expect(game.title, isNotEmpty);
      expect(game.icon, isNotEmpty);
      expect(game.description, isNotEmpty);
      expect(GameRegistry.byId(game.id), same(game));
    }
  });

  test('campaign order and existing user floor mapping never change', () {
    const expectedIds = <String>[
      'merge2048', 'numberSequence', 'memory', 'colorMatch',
      'speed', 'logic', 'pattern', 'fifteen', 'maze',
    ];
    expect(GameRegistry.campaignIds, expectedIds);
    expect(FloorEngine.gameIds, expectedIds);
    const engine = FloorEngine();
    for (var floor = 1; floor <= 90; floor++) {
      final id = expectedIds[(floor - 1) % expectedIds.length];
      expect(engine.challengeFor(floor).gameId, id);
    }
  });

  test('every playable game has an objective and is in campaign', () {
    for (final game in GameRegistry.games.where((game) => game.playable)) {
      expect(GameRegistry.campaignIds, contains(game.id));
      final objective = const ObjectiveCatalog().forGame(game.id);
      expect(objective.target, greaterThan(0));
    }
  });

  test('unimplemented games cannot be launched by mistake', () {
    expect(() => GameRegistry.byId('unknown-id'), throwsArgumentError);
    expect(() => GameRegistry.buildPage('sudoku',
      floor: null, callbacks: callbacks), throwsArgumentError);
  });

  test('existing pages retain their expected widget types', () {
    expect(GameRegistry.buildPage('merge2048', floor: 1,
      callbacks: callbacks), isA<MergePage>());
    expect(GameRegistry.buildPage('numberSequence', floor: 2,
      callbacks: callbacks), isA<SequencePage>());
    for (final game in GameRegistry.games.where((game) => game.playable)) {
      expect(GameRegistry.buildPage(game.id, floor: null,
        callbacks: callbacks), isA<Widget>());
    }
  });
}

final callbacks = GameCallbacks(
  onComplete: () {},
  onMergeEnd: (_, __, ___) {},
  onSequenceEnd: (_, __) {},
  onMemoryEnd: (_, __) {},
  onColorEnd: (_, __) {},
  onSpeedEnd: (_, __) {},
  onLogicEnd: (_) {},
  onPatternEnd: (_, __) {},
  onFifteenEnd: (_) {},
  onMazeEnd: (_, __) {},
);
