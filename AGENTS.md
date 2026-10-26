# Neuro Playground — contribution rules

Read [docs/PARALLEL_DEVELOPMENT.md](docs/PARALLEL_DEVELOPMENT.md) before changing code.

## Product
The game list has not been approved yet. Do not add a game module, mechanic, scoring rule, or game-specific node until the user approves the list. The English UI should use short copy, a minimal polished visual style, and microanimations. Prefer Flutter-drawn visuals over bundled artwork.

## Structure
- `lib/main.dart`: app shell, navigation, local persistence, module dispatch.
- `lib/core/neuron_progression.dart`: game-independent branching map and saved progression.
- `lib/core/game_registry.dart`: module interface and approved game catalog.
- `lib/core/skill_progress.dart`: explicitly reported, persisted skill metrics only.
- `lib/ui/`: shared map, navigation, catalog, settings, and skill UI.
- `lib/games/<id>/`: one folder per approved game, pure Dart engine plus Flutter page.

## Workflow
Work on a new feature or fix branch from current `main`. Never push directly to `main`. Keep new game work isolated in its module folder and tests until integration is assigned. Use stable IDs; assign an ID to map nodes only after the game is approved. A game may recur on harder nodes and still have one standalone library entry.

Before opening a PR, run `flutter analyze`, `flutter test`, and `flutter build web --release --base-href /flooria/` for UI changes when the SDK is available. State clearly when checks could not be run.
