# Approved game modules

Approved: `pattern_repeat`, `number_hunt`, `hue_sort`, `synapse_link`,
`target_sum`, `ice_slide`, `shape_turn`, `signal_guard`, `path_paint`,
`brick_break`, `tower_shift`, `merge_tiles`, `snake`, `tetris`, `pair_match`,
`precision_stop`, `peg_solitaire`, `number_sequence`, `sokoban`, `lights_out`,
`number_maze`, `minefield`, `color_flood`, `water_sort`, `nonogram`,
`domino_chain`, `whack_target`, `color_catcher`, `zip_route`, `rope_untangle`,
`knight_tour`, `stacker`, `tangram_fit`,
`match_three`, `bubble_shooter`, `rail_router`, `gravity_shift`,
`combination_lock`,
`billiards`, `robot_program`, `set_match`, `balance_scale`, `picture_assemble`.
Also approved: `mirror_beam`, `clone_shift`, `shadow_bridge`, `magnetic_room`,
`tide_shift`, `shape_shift`, `orbit_catch`.

Pages build on `lib/ui/game_kit.dart`: `GameScaffold` for the chrome,
`ChunkyButton` for pressables, `LevelResultPanel`/`RetryPanel` for the end of
a level, and the `LevelFlow` mixin for reporting a win once and moving on.

In map mode, a neuron runs three consecutive levels of its game before it is
marked complete. In the Games library, each game continues through its own
100-level progression.

For each approved game, add a stable-ID folder with a pure Dart rules engine and a Flutter page. Register its `GameDefinition` in `lib/core/game_registry.dart`, then assign its ID to one or more map nodes in `lib/core/neuron_progression.dart`. Leave unapproved modules out of the registry so they cannot appear in the app.
