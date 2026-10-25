# Neuro Playground architecture

## Current platform
One Flutter codebase for mobile and web. Progress, favorites, recent games
and game records are local via SharedPreferences. No user account or backend.
Nine playable game modules are integrated.

## Core registry (single integration owner)
- `lib/core/game_registry.dart` owns stable IDs, catalog metadata, the
  playable screen factory, and an append-only campaign ID list.
- `lib/game/floor_engine.dart` consumes that stable campaign list.
- `lib/game/game_objective.dart` maps existing game IDs to win objectives.
- `lib/game/player_stats.dart` stores backwards-compatible measured records.
- `lib/main.dart` handles persistence and dispatches callbacks to registry.
- `lib/ui/neuro_hub_pages.dart` and `lib/ui/neuro_map.dart` display metadata
  from the same registry rather than maintaining separate label lists.

Do not reorder registered campaign IDs while floor progress is stored as an
integer. Future schedule migrations require a data-versioning design.

## Existing game modules
Pure game rules currently live under `lib/game/` and independent screens
under `lib/ui/`. They will remain compatible while **new** game modules use
`lib/games/<id>/` and tests in `test/games/<id>/`.

Each module should expose:
- Stable unique game ID and deterministic seeded rules;
- Pure rules engine, separate from Flutter;
- Self-contained screen with optional campaign floor, completion callback
  and result callback;
- Solvable level generation, invalid-input protection and safe async lifecycle;
- Responsive mobile layout without unnecessary gameplay scrolling;
- Focused unit and widget tests.

The registry deliberately owns imports of game pages. Feature PRs should
supply their self-contained module and ask the integrator to add it to the
registry and objective/stats systems after review.

## Parallel workflows
Read `AGENTS.md` and `docs/PARALLEL_DEVELOPMENT.md`. Authors develop on
separate branches, submit PRs, and avoid shared integration files.
`Validate Feature PR` checks Dart analysis, tests and web build on PRs.
The original Pages deployment runs from `main` only.

## Constraints
No remote executable code modules. No personal-data backend required.
Do not break legacy saved progress or rename game IDs without migrations.
