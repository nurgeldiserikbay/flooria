# Architecture

## App shell

- `lib/main.dart` owns navigation, local preferences, progress persistence, and dispatch to game modules.
- `lib/core/neuron_progression.dart` owns the branching node graph and progression data. It does not import Flutter.
- `lib/core/game_registry.dart` owns approved game metadata and one screen factory per module. The catalog is empty until games are approved.
- `lib/core/skill_progress.dart` stores only explicit 0–100 measurements returned by modules.
- `lib/ui/neuro_map.dart`, `neuro_hub_pages.dart`, and `skill_radar.dart` render shared navigation and progression UI.
- Shared UI is drawn with Flutter widgets and CustomPainter. There are no bundled game assets or runtime-loaded code.

## Adding an approved game

Create `lib/games/<stable_id>/` with a pure Dart rules engine and a Flutter page. Keep game state local to the module and use the shared launch contract:

- `GameLaunch.level` supplies the node or standalone level.
- `GameLaunch.mode` distinguishes map challenges from standalone play.
- `GameLaunch.onComplete(GameResult(...))` records a win once.
- `GameResult.score` carries the module's score; `metrics` may include an explicitly measured skill on a 0–100 scale.
- `GameDefinition.maxLevel` caps standalone progression; `skill` selects the optional metric key.

Then add one `GameDefinition` to `GameRegistry.games` and assign its stable ID to selected nodes in `NeuronMapGraph`. Leaving the module out of the registry disables it without deleting source. Repeated module IDs on different nodes support harder variants without duplicating the game implementation.

## Persistence

Map completion and standalone best levels/scores are stored locally in SharedPreferences through `PlayerProgress`. Named skill measurements are stored separately through `SkillProgress`. The app has no account or backend requirement.
