import 'package:flutter/widgets.dart';

import '../ui/color_spot_page.dart';
import '../ui/fifteen_page.dart';
import '../ui/light_grid_page.dart';
import '../ui/maze_route_page.dart';
import '../ui/memory_pairs_page.dart';
import '../ui/merge_page.dart';
import '../ui/pattern_echo_page.dart';
import '../ui/sequence_page.dart';
import '../ui/tap_sprint_page.dart';

/// Catalog metadata is owned by integration, not individual game PRs.
/// IDs are durable identifiers stored in favorites, recents and campaign data.
class GameDefinition {
  const GameDefinition({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    required this.playable,
  });

  final String id;
  final String title;
  final String icon;
  final String description;
  final bool playable;
}

/// Existing progress callbacks live with the shell for backwards compatibility.
/// Adding a new game requires only one new callback in this contract.
class GameCallbacks {
  const GameCallbacks({
    required this.onComplete,
    required this.onMergeEnd,
    required this.onSequenceEnd,
    required this.onMemoryEnd,
    required this.onColorEnd,
    required this.onSpeedEnd,
    required this.onLogicEnd,
    required this.onPatternEnd,
    required this.onFifteenEnd,
    required this.onMazeEnd,
  });

  final VoidCallback onComplete;
  final void Function(int, int, int) onMergeEnd;
  final void Function(int, int) onSequenceEnd;
  final void Function(int, int) onMemoryEnd;
  final void Function(int, int) onColorEnd;
  final void Function(int, int) onSpeedEnd;
  final void Function(int) onLogicEnd;
  final void Function(int, int) onPatternEnd;
  final void Function(int) onFifteenEnd;
  final void Function(int, int) onMazeEnd;
}

/// The only place where shared UI wires a mini-game into the application.
///
/// Parallel authors should edit only lib/games/`<new_game>`/ and tests in
/// separate feature branches. The integration owner registers new games here.
abstract final class GameRegistry {
  static const games = <GameDefinition>[
    GameDefinition(id: 'merge2048', title: '2048', icon: '2048',
      description: 'Merge matching tiles to reach the goal.', playable: true),
    GameDefinition(id: 'numberSequence', title: 'Number Trail', icon: 'trail',
      description: 'Find the missing number.', playable: true),
    GameDefinition(id: 'memory', title: 'Memory Pairs', icon: 'memory',
      description: 'Find every matching pair.', playable: true),
    GameDefinition(id: 'logic', title: 'Light Grid', icon: 'logic',
      description: 'Turn off all the lights.', playable: true),
    GameDefinition(id: 'speed', title: 'Tap Sprint', icon: 'speed',
      description: 'Tap numbers in the right order.', playable: true),
    GameDefinition(id: 'colorMatch', title: 'Color Spot', icon: 'colors',
      description: 'Spot the different shade.', playable: true),
    GameDefinition(id: 'sudoku', title: 'Sudoku', icon: 'sudoku',
      description: 'Solve a number grid.', playable: false),
    GameDefinition(id: 'fifteen', title: 'Sliding Fifteen', icon: 'fifteen',
      description: 'Slide tiles into the empty space.', playable: true),
    GameDefinition(id: 'maze', title: 'Maze Route', icon: 'maze',
      description: 'Find the route to the golden star.', playable: true),
    GameDefinition(id: 'reaction', title: 'Reaction', icon: 'reaction',
      description: 'React to the signal.', playable: false),
    GameDefinition(id: 'pattern', title: 'Pattern Echo', icon: 'pattern',
      description: 'Watch the lights, then repeat.', playable: true),
    GameDefinition(id: 'word', title: 'Words', icon: 'word',
      description: 'Make words from letters.', playable: false),
  ];

  /// Do NOT reorder existing IDs. Campaign progress is saved as a floor
  /// number, not a game ID: reordering changes old users' next challenge.
  /// New games are appended here in a dedicated integration PR.
  static const campaignIds = <String>[
    'merge2048', 'numberSequence', 'memory', 'colorMatch', 'speed',
    'logic', 'pattern', 'fifteen', 'maze',
  ];

  static GameDefinition byId(String id) {
    for (final game in games) {
      if (game.id == id) return game;
    }
    throw ArgumentError.value(id, 'id', 'Unknown mini-game');
  }

  static Widget buildPage(String id, {
    required int? floor,
    required GameCallbacks callbacks,
  }) {
    switch (id) {
      case 'merge2048':
        return MergePage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: callbacks.onMergeEnd);
      case 'numberSequence':
        return SequencePage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: callbacks.onSequenceEnd);
      case 'memory':
        return MemoryPairsPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: callbacks.onMemoryEnd);
      case 'colorMatch':
        return ColorSpotPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: callbacks.onColorEnd);
      case 'speed':
        return TapSprintPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: callbacks.onSpeedEnd);
      case 'logic':
        return LightGridPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: callbacks.onLogicEnd);
      case 'pattern':
        return PatternEchoPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: callbacks.onPatternEnd);
      case 'fifteen':
        return FifteenPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: callbacks.onFifteenEnd);
      case 'maze':
        return MazeRoutePage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: callbacks.onMazeEnd);
      default:
        throw ArgumentError.value(id, 'id', 'Mini-game is not playable');
    }
  }
}
