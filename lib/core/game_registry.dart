import 'package:flutter/widgets.dart';

import '../games/pattern_repeat/pattern_repeat_page.dart';
import '../games/number_hunt/number_hunt_page.dart';

enum GamePlayMode { neuron, standalone }

@immutable
class GameResult {
  const GameResult({this.score = 0, this.metrics = const {}, this.level});

  final int score;
  final Map<String, num> metrics;
  final int? level;
}

@immutable
class GameLaunch {
  const GameLaunch({
    required this.level,
    this.maxLevel = 100,
    required this.mode,
    required this.onComplete,
  });

  final int level;
  final int maxLevel;
  final GamePlayMode mode;
  final ValueChanged<GameResult> onComplete;
}

typedef GamePageBuilder = Widget Function(BuildContext context, GameLaunch launch);

/// One self-contained game module. Add a module under `lib/games/<id>/` and
/// register one definition in [GameRegistry.games] after its design is approved.
@immutable
class GameDefinition {
  const GameDefinition({
    required this.id,
    required this.title,
    required this.icon,
    required this.skill,
    required this.maxLevel,
    required this.buildPage,
    this.enabled = true,
  });

  final String id;
  final String title;
  final String icon;
  final String skill;
  final int maxLevel;
  final bool enabled;
  final GamePageBuilder buildPage;
}

/// Product catalog. It intentionally starts empty until the game list is
/// approved. Each module can be disabled here without deleting its source.
abstract final class GameRegistry {
  static const games = <GameDefinition>[
    GameDefinition(
      id: 'pattern_repeat',
      title: 'Pattern Repeat',
      icon: 'memory',
      skill: 'memory',
      maxLevel: 100,
      buildPage: buildPatternRepeatPage,
    ),
    GameDefinition(
      id: 'number_hunt',
      title: 'Find the Number',
      icon: 'number_hunt',
      skill: 'focus',
      maxLevel: 100,
      buildPage: buildNumberHuntPage,
    ),
  ];

  static List<GameDefinition> get enabledGames =>
      games.where((game) => game.enabled).toList(growable: false);

  static GameDefinition byId(String id) {
    final game = maybeById(id);
    if (game == null) throw ArgumentError.value(id, 'id', 'Unknown game');
    return game;
  }

  static GameDefinition? maybeById(String id) {
    for (final game in games) {
      if (game.id == id && game.enabled) return game;
    }
    return null;
  }

  static Set<String> get enabledIds =>
      enabledGames.map((game) => game.id).toSet();
}
