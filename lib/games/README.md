# Approved game modules

The directory is intentionally empty until the game list is approved.

For each approved game, add a stable-ID folder with a pure Dart rules engine and a Flutter page. Register its `GameDefinition` in `lib/core/game_registry.dart`, then assign its ID to one or more map nodes in `lib/core/neuron_progression.dart`. Leave unapproved modules out of the registry so they cannot appear in the app.
