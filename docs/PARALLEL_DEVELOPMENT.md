# Game module workflow

## Current state
The app shell, branching neuron map, empty Games library, and Skills view are in place. The catalog intentionally has no game modules until the user approves a game list. The map graph contains generic slots with no game IDs assigned.

## Module contract
Each approved game belongs in `lib/games/<stable_id>/`:

- `<id>_engine.dart` contains pure Dart rules, deterministic level generation, and scoring.
- `<id>_page.dart` renders input and feedback without owning app navigation or persistence.
- `GameLaunch` provides the level, play mode, and one completion callback.
- `GameResult` returns the score and optional explicitly measured skill metrics.

After review, the integration owner adds one `GameDefinition` to `lib/core/game_registry.dart` and assigns the stable ID to one or more `NeuronNode`s in `lib/core/neuron_progression.dart`. Repeated nodes can use the same module at harder levels. Remove a module from the registry to hide it without removing its source.

## Quality bar
- Distinct, engaging decision mechanic with an unambiguous win condition.
- English UI with short instructions and symbol-led controls.
- No reliance on word knowledge unless approved in the game list.
- Responsive play on 360×640 without unnecessary vertical scrolling.
- Rules tests cover deterministic generation, invalid input, scoring, and solvability where applicable; viewport tests cover 360×640 and 390×844.
- Report local tool limitations; do not claim checks passed unless they ran.

Shared ownership belongs to the integration owner: app shell, registry, progression, skills, shared UI, and CI. New modules should stay within their folder until explicitly assigned for integration.
