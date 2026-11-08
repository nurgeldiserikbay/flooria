import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';

void main() {
  test('the full 50-game library stays available for standalone play', () {
    final all = GameRegistry.games;
    final enabled = GameRegistry.enabledGames;

    expect(all, hasLength(50));
    expect(enabled, hasLength(50));
    expect(GameRegistry.enabledIds, hasLength(50));

    final ids = all.map((game) => game.id).toList();
    final titles = all.map((game) => game.title).toList();

    expect(ids.toSet(), hasLength(all.length), reason: 'Duplicate game ID');
    expect(titles.toSet(), hasLength(all.length),
        reason: 'Duplicate game title');

    for (final game in all) {
      expect(game.enabled, isTrue, reason: game.id);
      expect(game.id.trim(), isNotEmpty);
      expect(game.title.trim(), isNotEmpty);
      expect(game.skill.trim(), isNotEmpty);
      expect(game.maxLevel, 100, reason: game.id);
      expect(GameRegistry.byId(game.id), same(game));
      expect(GameRegistry.maybeById(game.id), same(game));
    }
  });

  test('missing games cannot silently resolve to another module', () {
    expect(GameRegistry.maybeById('__missing__'), isNull);
    expect(() => GameRegistry.byId('__missing__'), throwsArgumentError);
  });

  test('catalog covers all eight distinct development skills', () {
    expect(
      GameRegistry.enabledGames.map((game) => game.skill).toSet(),
      containsAll(<String>{
        'memory',
        'focus',
        'perception',
        'logic',
        'math',
        'planning',
        'spatial',
        'control',
      }),
    );
  });
}
