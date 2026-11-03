import 'package:flutter/widgets.dart';

import '../games/hue_sort/hue_sort_page.dart';
import '../games/brick_break/brick_break_page.dart';
import '../games/ice_slide/ice_slide_page.dart';
import '../games/merge_tiles/merge_tiles_page.dart';
import '../games/number_hunt/number_hunt_page.dart';
import '../games/number_maze/number_maze_page.dart';
import '../games/number_sequence/number_sequence_page.dart';
import '../games/minefield/minefield_page.dart';
import '../games/lights_out/lights_out_page.dart';
import '../games/color_flood/color_flood_page.dart';
import '../games/color_catcher/color_catcher_page.dart';
import '../games/zip_route/zip_route_page.dart';
import '../games/rope_untangle/rope_untangle_page.dart';
import '../games/knight_tour/knight_tour_page.dart';
import '../games/stacker/stacker_page.dart';
import '../games/tangram_fit/tangram_fit_page.dart';
import '../games/match_three/match_three_page.dart';
import '../games/bubble_shooter/bubble_shooter_page.dart';
import '../games/rail_router/rail_router_page.dart';
import '../games/gravity_shift/gravity_shift_page.dart';
import '../games/combination_lock/combination_lock_page.dart';
import '../games/mirror_beam/mirror_beam_page.dart';
import '../games/clone_shift/clone_shift_page.dart';
import '../games/shadow_bridge/shadow_bridge_page.dart';
import '../games/magnetic_room/magnetic_room_page.dart';
import '../games/tide_shift/tide_shift_page.dart';
import '../games/shape_shift/shape_shift_page.dart';
import '../games/orbit_catch/orbit_catch_page.dart';
import '../games/billiards/billiards_page.dart';
import '../games/robot_program/robot_program_page.dart';
import '../games/set_match/set_match_page.dart';
import '../games/balance_scale/balance_scale_page.dart';
import '../games/picture_assemble/picture_assemble_page.dart';
import '../games/domino_chain/domino_chain_page.dart';
import '../games/nonogram/nonogram_page.dart';
import '../games/path_paint/path_paint_page.dart';
import '../games/pair_match/pair_match_page.dart';
import '../games/peg_solitaire/peg_solitaire_page.dart';
import '../games/pattern_repeat/pattern_repeat_page.dart';
import '../games/precision_stop/precision_stop_page.dart';
import '../games/shape_turn/shape_turn_page.dart';
import '../games/signal_guard/signal_guard_page.dart';
import '../games/sokoban/sokoban_page.dart';
import '../games/snake/snake_page.dart';
import '../games/synapse_link/synapse_link_page.dart';
import '../games/target_sum/target_sum_page.dart';
import '../games/tower_shift/tower_shift_page.dart';
import '../games/tetris/tetris_page.dart';
import '../games/water_sort/water_sort_page.dart';
import '../games/whack_target/whack_target_page.dart';

enum GamePlayMode { neuron, standalone }

@immutable
class GameResult {
  const GameResult({
    this.score = 0,
    this.metrics = const {},
    this.level,
    this.completesNeuron = false,
  });

  final int score;
  final Map<String, num> metrics;
  final int? level;
  /// True only when the final level assigned to a map node is cleared.
  final bool completesNeuron;
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

/// Product catalog. Each module can be disabled here without deleting its source.
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
    GameDefinition(
      id: 'hue_sort',
      title: 'Hue Sort',
      icon: 'hue_sort',
      skill: 'perception',
      maxLevel: 100,
      buildPage: buildHueSortPage,
    ),
    GameDefinition(
      id: 'synapse_link',
      title: 'Synapse Link',
      icon: 'synapse_link',
      skill: 'logic',
      maxLevel: 100,
      buildPage: buildSynapseLinkPage,
    ),
    GameDefinition(
      id: 'target_sum',
      title: 'Target Sum',
      icon: 'target_sum',
      skill: 'math',
      maxLevel: 100,
      buildPage: buildTargetSumPage,
    ),
    GameDefinition(
      id: 'ice_slide',
      title: 'Ice Slide',
      icon: 'ice_slide',
      skill: 'planning',
      maxLevel: 100,
      buildPage: buildIceSlidePage,
    ),
    GameDefinition(
      id: 'shape_turn',
      title: 'Shape Turn',
      icon: 'shape_turn',
      skill: 'spatial',
      maxLevel: 100,
      buildPage: buildShapeTurnPage,
    ),
    GameDefinition(
      id: 'signal_guard',
      title: 'Signal Guard',
      icon: 'signal_guard',
      skill: 'control',
      maxLevel: 100,
      buildPage: buildSignalGuardPage,
    ),
    GameDefinition(
      id: 'path_paint',
      title: 'Path Paint',
      icon: 'path_paint',
      skill: 'focus',
      maxLevel: 100,
      buildPage: buildPathPaintPage,
    ),
    GameDefinition(
      id: 'brick_break',
      title: 'Brick Break',
      icon: 'brick_break',
      skill: 'control',
      maxLevel: 100,
      buildPage: buildBrickBreakPage,
    ),
    GameDefinition(
      id: 'tower_shift',
      title: 'Tower Shift',
      icon: 'tower_shift',
      skill: 'planning',
      maxLevel: 100,
      buildPage: buildTowerShiftPage,
    ),
    GameDefinition(
      id: 'merge_tiles',
      title: 'Merge 2048',
      icon: 'merge_tiles',
      skill: 'logic',
      maxLevel: 100,
      buildPage: buildMergeTilesPage,
    ),
    GameDefinition(
      id: 'snake',
      title: 'Snake',
      icon: 'snake',
      skill: 'control',
      maxLevel: 100,
      buildPage: buildSnakePage,
    ),
    GameDefinition(
      id: 'tetris',
      title: 'Tetris',
      icon: 'tetris',
      skill: 'spatial',
      maxLevel: 100,
      buildPage: buildTetrisPage,
    ),
    GameDefinition(
      id: 'pair_match',
      title: 'Pair Match',
      icon: 'pair_match',
      skill: 'memory',
      maxLevel: 100,
      buildPage: buildPairMatchPage,
    ),
    GameDefinition(
      id: 'precision_stop',
      title: 'Precision Stop',
      icon: 'precision_stop',
      skill: 'control',
      maxLevel: 100,
      buildPage: buildPrecisionStopPage,
    ),
    GameDefinition(
      id: 'peg_solitaire',
      title: 'Peg Solitaire',
      icon: 'peg_solitaire',
      skill: 'planning',
      maxLevel: 100,
      buildPage: buildPegSolitairePage,
    ),
    GameDefinition(
      id: 'number_sequence',
      title: 'Number Sequence',
      icon: 'number_sequence',
      skill: 'math',
      maxLevel: 100,
      buildPage: buildNumberSequencePage,
    ),
    GameDefinition(
      id: 'sokoban',
      title: 'Sokoban',
      icon: 'sokoban',
      skill: 'planning',
      maxLevel: 100,
      buildPage: buildSokobanPage,
    ),
    GameDefinition(
      id: 'lights_out',
      title: 'Lights Out',
      icon: 'lights_out',
      skill: 'logic',
      maxLevel: 100,
      buildPage: buildLightsOutPage,
    ),
    GameDefinition(
      id: 'number_maze',
      title: 'Number Maze',
      icon: 'number_maze',
      skill: 'planning',
      maxLevel: 100,
      buildPage: buildNumberMazePage,
    ),
    GameDefinition(
      id: 'minefield',
      title: 'Minefield',
      icon: 'minefield',
      skill: 'logic',
      maxLevel: 100,
      buildPage: buildMinefieldPage,
    ),
    GameDefinition(
      id: 'color_flood',
      title: 'Color Flood',
      icon: 'color_flood',
      skill: 'perception',
      maxLevel: 100,
      buildPage: buildColorFloodPage,
    ),
    GameDefinition(
      id: 'water_sort',
      title: 'Water Sort',
      icon: 'water_sort',
      skill: 'planning',
      maxLevel: 100,
      buildPage: buildWaterSortPage,
    ),
    GameDefinition(
      id: 'nonogram',
      title: 'Nonogram',
      icon: 'nonogram',
      skill: 'logic',
      maxLevel: 100,
      buildPage: buildNonogramPage,
    ),
    GameDefinition(
      id: 'domino_chain',
      title: 'Domino Chain',
      icon: 'domino_chain',
      skill: 'logic',
      maxLevel: 100,
      buildPage: buildDominoChainPage,
    ),
    GameDefinition(
      id: 'whack_target',
      title: 'Whack the Target',
      icon: 'whack_target',
      skill: 'control',
      maxLevel: 100,
      buildPage: buildWhackTargetPage,
    ),
    GameDefinition(
      id: 'color_catcher',
      title: 'Color Catcher',
      icon: 'color_catcher',
      skill: 'control',
      maxLevel: 100,
      buildPage: buildColorCatcherPage,
    ),
    GameDefinition(
      id: 'zip_route',
      title: 'Zip Route',
      icon: 'zip_route',
      skill: 'planning',
      maxLevel: 100,
      buildPage: buildZipRoutePage,
    ),
    GameDefinition(
      id: 'rope_untangle',
      title: 'Rope Untangle',
      icon: 'rope_untangle',
      skill: 'spatial',
      maxLevel: 100,
      buildPage: buildRopeUntanglePage,
    ),
    GameDefinition(
      id: 'knight_tour',
      title: "Knight's Tour",
      icon: 'knight_tour',
      skill: 'planning',
      maxLevel: 100,
      buildPage: buildKnightTourPage,
    ),
    GameDefinition(
      id: 'stacker',
      title: 'Stacker',
      icon: 'stacker',
      skill: 'control',
      maxLevel: 100,
      buildPage: buildStackerPage,
    ),
    GameDefinition(
      id: 'tangram_fit',
      title: 'Tangram Fit',
      icon: 'tangram_fit',
      skill: 'spatial',
      maxLevel: 100,
      buildPage: buildTangramFitPage,
    ),
    GameDefinition(
      id: 'match_three',
      title: 'Match Three',
      icon: 'match_three',
      skill: 'planning',
      maxLevel: 100,
      buildPage: buildMatchThreePage,
    ),
    GameDefinition(
      id: 'bubble_shooter',
      title: 'Bubble Shooter',
      icon: 'bubble_shooter',
      skill: 'focus',
      maxLevel: 100,
      buildPage: buildBubbleShooterPage,
    ),
    GameDefinition(
      id: 'rail_router',
      title: 'Rail Router',
      icon: 'rail_router',
      skill: 'planning',
      maxLevel: 100,
      buildPage: buildRailRouterPage,
    ),
    GameDefinition(
      id: 'gravity_shift',
      title: 'Gravity Shift',
      icon: 'gravity_shift',
      skill: 'spatial',
      maxLevel: 100,
      buildPage: buildGravityShiftPage,
    ),
    GameDefinition(
      id: 'combination_lock',
      title: 'Combination Lock',
      icon: 'combination_lock',
      skill: 'logic',
      maxLevel: 100,
      buildPage: buildCombinationLockPage,
    ),
    GameDefinition(
      id: 'billiards',
      title: 'Billiard Order',
      icon: 'billiards',
      skill: 'planning',
      maxLevel: 100,
      buildPage: buildBilliardsPage,
    ),
    GameDefinition(
      id: 'robot_program',
      title: 'Robot Program',
      icon: 'robot_program',
      skill: 'logic',
      maxLevel: 100,
      buildPage: buildRobotProgramPage,
    ),
    GameDefinition(
      id: 'set_match',
      title: 'Find a Set',
      icon: 'set_match',
      skill: 'focus',
      maxLevel: 100,
      buildPage: buildSetMatchPage,
    ),
    GameDefinition(
      id: 'balance_scale',
      title: 'Balance Scale',
      icon: 'balance_scale',
      skill: 'math',
      maxLevel: 100,
      buildPage: buildBalanceScalePage,
    ),
    GameDefinition(
      id: 'picture_assemble',
      title: 'Picture Assembly',
      icon: 'picture_assemble',
      skill: 'spatial',
      maxLevel: 100,
      buildPage: buildPictureAssemblePage,
    ),
    GameDefinition(
      id: 'mirror_beam',
      title: 'Mirror Beam',
      icon: 'mirror_beam',
      skill: 'logic',
      maxLevel: 100,
      buildPage: buildMirrorBeamPage,
    ),
    GameDefinition(
      id: 'clone_shift',
      title: 'Clone Shift',
      icon: 'clone_shift',
      skill: 'planning',
      maxLevel: 100,
      buildPage: buildCloneShiftPage,
    ),
    GameDefinition(
      id: 'shadow_bridge',
      title: 'Shadow Bridge',
      icon: 'shadow_bridge',
      skill: 'spatial',
      maxLevel: 100,
      buildPage: buildShadowBridgePage,
    ),
    GameDefinition(
      id: 'magnetic_room',
      title: 'Magnetic Room',
      icon: 'magnetic_room',
      skill: 'planning',
      maxLevel: 100,
      buildPage: buildMagneticRoomPage,
    ),
    GameDefinition(
      id: 'tide_shift',
      title: 'Tide Shift',
      icon: 'tide_shift',
      skill: 'planning',
      maxLevel: 100,
      buildPage: buildTideShiftPage,
    ),
    GameDefinition(
      id: 'shape_shift',
      title: 'Shape Shift',
      icon: 'shape_shift',
      skill: 'control',
      maxLevel: 100,
      buildPage: buildShapeShiftPage,
    ),
    GameDefinition(
      id: 'orbit_catch',
      title: 'Orbit Catch',
      icon: 'orbit_catch',
      skill: 'control',
      maxLevel: 100,
      buildPage: buildOrbitCatchPage,
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
