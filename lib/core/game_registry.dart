import 'package:flutter/widgets.dart';

import '../games/analogy_lab/analogy_lab_page.dart';
import '../games/arrow_orbit/arrow_orbit_page.dart';
import '../games/balance_scale/balance_scale_page.dart';
import '../games/bead_sort/bead_sort_page.dart';
import '../games/beat_bloom/beat_bloom_page.dart';
import '../games/belief_detective/belief_detective_page.dart';
import '../games/bridge_cut/bridge_cut_page.dart';
import '../games/bridge_islands/bridge_islands_page.dart';
import '../games/causal_lab/causal_lab_page.dart';
import '../games/chance_garden/chance_garden_page.dart';
import '../games/clover_sweep/clover_sweep_page.dart';
import '../games/code_breaker/code_breaker_page.dart';
import '../games/cube_vista/cube_vista_page.dart';
import '../games/cue_keeper/cue_keeper_page.dart';
import '../games/disk_towers/disk_towers_page.dart';
import '../games/domino_fit/domino_fit_page.dart';
import '../games/focus_finder/focus_finder_page.dart';
import '../games/fraction_forge/fraction_forge_page.dart';
import '../games/gear_works/gear_works_page.dart';
import '../games/glow_grid/glow_grid_page.dart';
import '../games/ink_switch/ink_switch_page.dart';
import '../games/knight_reach/knight_reach_page.dart';
import '../games/logic_gates/logic_gates_page.dart';
import '../games/loop_logic/loop_logic_page.dart';
import '../games/magnitude_mapper/magnitude_mapper_page.dart';
import '../games/map_tints/map_tints_page.dart';
import '../games/matchstick_math/matchstick_math_page.dart';
import '../games/mind_loop/mind_loop_page.dart';
import '../games/mini_sudoku/mini_sudoku_page.dart';
import '../games/mirror_mosaic/mirror_mosaic_page.dart';
import '../games/mood_mirror/mood_mirror_page.dart';
import '../games/neural_links/neural_links_page.dart';
import '../games/nonogram/nonogram_page.dart';
import '../games/one_stroke/one_stroke_page.dart';
import '../games/order_lab/order_lab_page.dart';
import '../games/paper_fold/paper_fold_page.dart';
import '../games/parking_escape/parking_escape_page.dart';
import '../games/pattern_trio/pattern_trio_page.dart';
import '../games/pendulum_drop/pendulum_drop_page.dart';
import '../games/prism_path/prism_path_page.dart';
import '../games/queens_guard/queens_guard_page.dart';
import '../games/quick_count/quick_count_page.dart';
import '../games/rhyme_rally/rhyme_rally_page.dart';
import '../games/river_crossing/river_crossing_page.dart';
import '../games/rule_relay/rule_relay_page.dart';
import '../games/scene_shift/scene_shift_page.dart';
import '../games/shape_shift/shape_shift_page.dart';
import '../games/shell_shuffle/shell_shuffle_page.dart';
import '../games/signal_guard/signal_guard_page.dart';
import '../games/steady_hand/steady_hand_page.dart';
import '../games/symbol_matrix/symbol_matrix_page.dart';
import '../games/target_sum/target_sum_page.dart';
import '../games/tilt_trail/tilt_trail_page.dart';
import '../games/time_sense/time_sense_page.dart';
import '../games/torch_bridge/torch_bridge_page.dart';
import '../games/tower_tactics/tower_tactics_page.dart';
import '../games/water_jugs/water_jugs_page.dart';
import '../games/word_bridge/word_bridge_page.dart';
import '../games/word_forge/word_forge_page.dart';

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
    this.testAccessible = false,
  });

  final String id;
  final String title;
  final String icon;
  final String description;
  final bool playable;
  /// Test-only games are hidden from the normal library unless testing access is enabled.
  final bool testAccessible;
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
      description: 'Solve the mini number grid.', playable: false, testAccessible: true),
    GameDefinition(id: 'fifteen', title: 'Sliding Fifteen', icon: 'fifteen',
      description: 'Slide tiles into the empty space.', playable: true),
    GameDefinition(id: 'maze', title: 'Maze Route', icon: 'maze',
      description: 'Find the route to the golden star.', playable: true),
    GameDefinition(id: 'reaction', title: 'Reaction', icon: 'reaction',
      description: 'Respond to the changing signal.', playable: false, testAccessible: true),
    GameDefinition(id: 'pattern', title: 'Pattern Echo', icon: 'pattern',
      description: 'Watch the lights, then repeat.', playable: true),
    GameDefinition(id: 'word', title: 'Words', icon: 'word',
      description: 'Build words from the letter set.', playable: false, testAccessible: true),
    GameDefinition(id: 'analogy_lab', title: 'Analogy Lab', icon: 'pattern',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'arrow_orbit', title: 'Arrow Orbit', icon: 'reaction',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'balance_scale', title: 'Balance Scale', icon: 'logic',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'bead_sort', title: 'Bead Sort', icon: 'logic',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'beat_bloom', title: 'Beat Bloom', icon: 'reaction',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'belief_detective', title: 'Belief Detective', icon: 'memory',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'bridge_cut', title: 'Bridge Cut', icon: 'maze',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'bridge_islands', title: 'Bridge Islands', icon: 'maze',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'causal_lab', title: 'Causal Lab', icon: 'logic',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'chance_garden', title: 'Chance Garden', icon: 'logic',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'clover_sweep', title: 'Clover Sweep', icon: 'colors',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'code_breaker', title: 'Code Breaker', icon: 'logic',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'cube_vista', title: 'Cube Vista', icon: 'logic',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'cue_keeper', title: 'Cue Keeper', icon: 'memory',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'disk_towers', title: 'Disk Towers', icon: 'maze',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'domino_fit', title: 'Domino Fit', icon: 'math',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'focus_finder', title: 'Focus Finder', icon: 'reaction',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'fraction_forge', title: 'Fraction Forge', icon: 'math',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'gear_works', title: 'Gear Works', icon: 'logic',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'glow_grid', title: 'Glow Grid', icon: 'colors',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'ink_switch', title: 'Ink Switch', icon: 'colors',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'knight_reach', title: 'Knight Reach', icon: 'maze',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'logic_gates', title: 'Logic Gates', icon: 'logic',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'loop_logic', title: 'Loop Logic', icon: 'logic',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'magnitude_mapper', title: 'Magnitude Mapper', icon: 'math',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'map_tints', title: 'Map Tints', icon: 'pattern',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'matchstick_math', title: 'Matchstick Math', icon: 'math',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'mind_loop', title: 'Mind Loop', icon: 'pattern',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'mirror_mosaic', title: 'Mirror Mosaic', icon: 'pattern',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'mood_mirror', title: 'Mood Mirror', icon: 'logic',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'neural_links', title: 'Neural Links', icon: 'colors',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'nonogram', title: 'Nonogram', icon: 'logic',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'one_stroke', title: 'One Stroke', icon: 'maze',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'order_lab', title: 'Order Lab', icon: 'logic',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'paper_fold', title: 'Paper Fold', icon: 'maze',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'parking_escape', title: 'Parking Escape', icon: 'maze',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'pattern_trio', title: 'Pattern Trio', icon: 'pattern',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'pendulum_drop', title: 'Pendulum Drop', icon: 'logic',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'prism_path', title: 'Prism Path', icon: 'maze',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'queens_guard', title: 'Queens Guard', icon: 'logic',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'quick_count', title: 'Quick Count', icon: 'math',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'rhyme_rally', title: 'Rhyme Rally', icon: 'word',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'river_crossing', title: 'River Crossing', icon: 'maze',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'rule_relay', title: 'Rule Relay', icon: 'logic',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'scene_shift', title: 'Scene Shift', icon: 'pattern',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'shape_shift', title: 'Shape Shift', icon: 'pattern',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'shell_shuffle', title: 'Shell Shuffle', icon: 'memory',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'steady_hand', title: 'Steady Hand', icon: 'reaction',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'symbol_matrix', title: 'Symbol Matrix', icon: 'pattern',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'target_sum', title: 'Target Sum', icon: 'math',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'tilt_trail', title: 'Tilt Trail', icon: 'reaction',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'time_sense', title: 'Time Sense', icon: 'reaction',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'torch_bridge', title: 'Torch Bridge', icon: 'maze',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'tower_tactics', title: 'Tower Tactics', icon: 'maze',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'water_jugs', title: 'Water Jugs', icon: 'maze',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
    GameDefinition(id: 'word_bridge', title: 'Word Bridge', icon: 'word',
      description: 'Experimental game available for testing.', playable: false, testAccessible: true),
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
      case 'analogy_lab':
        return AnalogyLabPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'arrow_orbit':
        return ArrowOrbitPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'balance_scale':
        return BalanceScalePage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'bead_sort':
        return BeadSortPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'beat_bloom':
        return BeatBloomPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'belief_detective':
        return BeliefDetectivePage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'bridge_cut':
        return BridgeCutPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'bridge_islands':
        return BridgeIslandsPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'causal_lab':
        return CausalLabPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'chance_garden':
        return ChanceGardenPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'clover_sweep':
        return CloverSweepPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'code_breaker':
        return CodeBreakerPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'cube_vista':
        return CubeVistaPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'cue_keeper':
        return CueKeeperPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'disk_towers':
        return DiskTowersPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'domino_fit':
        return DominoFitPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'focus_finder':
        return FocusFinderPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'fraction_forge':
        return FractionForgePage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'gear_works':
        return GearWorksPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'glow_grid':
        return GlowGridPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'ink_switch':
        return InkSwitchPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'knight_reach':
        return KnightReachPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'logic_gates':
        return LogicGatesPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'loop_logic':
        return LoopLogicPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'magnitude_mapper':
        return MagnitudeMapperPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'map_tints':
        return MapTintsPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'matchstick_math':
        return MatchstickMathPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'mind_loop':
        return MindLoopPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'sudoku':
        return MiniSudokuPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'mirror_mosaic':
        return MirrorMosaicPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'mood_mirror':
        return MoodMirrorPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'neural_links':
        return NeuralLinksPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'nonogram':
        return NonogramPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'one_stroke':
        return OneStrokePage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'order_lab':
        return OrderLabPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'paper_fold':
        return PaperFoldPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'parking_escape':
        return ParkingEscapePage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'pattern_trio':
        return PatternTrioPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'pendulum_drop':
        return PendulumDropPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'prism_path':
        return PrismPathPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'queens_guard':
        return QueensGuardPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'quick_count':
        return QuickCountPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'rhyme_rally':
        return RhymeRallyPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'river_crossing':
        return RiverCrossingPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'rule_relay':
        return RuleRelayPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'scene_shift':
        return SceneShiftPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'shape_shift':
        return ShapeShiftPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'shell_shuffle':
        return ShellShufflePage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'reaction':
        return SignalGuardPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'steady_hand':
        return SteadyHandPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'symbol_matrix':
        return SymbolMatrixPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'target_sum':
        return TargetSumPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'tilt_trail':
        return TiltTrailPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'time_sense':
        return TimeSensePage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'torch_bridge':
        return TorchBridgePage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'tower_tactics':
        return TowerTacticsPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'water_jugs':
        return WaterJugsPage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'word_bridge':
        return WordBridgePage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      case 'word':
        return WordForgePage(floor: floor, onComplete: callbacks.onComplete,
          onSessionEnd: _ignoreTestSession);
      default:
        throw ArgumentError.value(id, 'id', 'Mini-game is not playable');
    }
  }
}


void _ignoreTestSession([Object? first, Object? second, Object? third]) {}
