# Approved game modules

Approved: `pattern_repeat`, `number_hunt`, `hue_sort`, `synapse_link`,
`target_sum`, `ice_slide`, `shape_turn`, `signal_guard`.

Pages build on `lib/ui/game_kit.dart`: `GameScaffold` for the chrome,
`ChunkyButton` for pressables, `LevelResultPanel`/`RetryPanel` for the end of
a level, and the `LevelFlow` mixin for reporting a win once and moving on.

For each approved game, add a stable-ID folder with a pure Dart rules engine and a Flutter page. Register its `GameDefinition` in `lib/core/game_registry.dart`, then assign its ID to one or more map nodes in `lib/core/neuron_progression.dart`. Leave unapproved modules out of the registry so they cannot appear in the app.
