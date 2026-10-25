# Neuro Playground — rules for parallel coding agents

Read [docs/PARALLEL_DEVELOPMENT.md](docs/PARALLEL_DEVELOPMENT.md) before changing code.
This repository is a Flutter mobile/web game; UI language is English.

## First action in every new session
1. Read these instructions and the current `main` branch.
2. Announce your branch name and module ownership in the task/PR.
3. Work on a **new `feature/<game-id>` or `fix/<scope>` branch** from current `main`.
4. Never commit or push directly to `main`. Do not self-merge PRs.
5. Keep commits small, deterministic, and scoped to the assigned module.
6. Inspect existing game engines, UI components, and tests before creating equivalents.

## Ownership and integration
- Mini-game authors own `lib/games/<game_id>/` and `test/games/<game_id>/`.
- Existing game engines remain in `lib/game/` and screens in `lib/ui/` until migrated.
- **Integration owner only:** `lib/core/game_registry.dart`, `lib/main.dart`,
  `lib/game/floor_engine.dart`, `lib/game/game_objective.dart`,
  `lib/game/player_stats.dart`, `lib/ui/neuro_hub_pages.dart`,
  `lib/ui/neuro_map.dart`, CI workflows, and shared visual tokens.
- If your game needs integration: document the requested registry/metrics/goal
  additions in the PR. Do not modify the shared files in your feature branch
  unless explicitly assigned to do so.
- Never reorder existing `GameRegistry.campaignIds`: persisted floor numbers
  refer to this order. Any schedule migration requires a dedicated migration plan.
- Stable game IDs must never be renamed or reused.

## Product and quality
- Each new game must have a distinct input/decision mechanic, not a re-skin.
- Pure Dart rules separated from Flutter widget rendering.
- Solvable/deterministic generated levels (seeded); no impossible board.
- Bright, readable pastel visual language; game-specific accent allowed.
- Gameplay visible immediately with no vertical page scrolling on 360x640.
- Limit accidental double submissions; guard delayed callbacks with mounted
  checks and generation tokens; dispose listeners/controllers.
- Record results only when earned; don't invent cognitive skill measurements.
- Avoid breaking offline SharedPreferences progress and legacy JSON.

## Before opening a PR
- `flutter analyze`
- `flutter test`
- `flutter build web --release --base-href /flooria/` when modifying UI
- Add tests for rules, seeded generation, invalid input, completion, and small
  phone layouts (360x640 and 390x844).
- Include screenshots/description of visual changes, changed files, and any
  shared integration required. Check current `main` again before merge.

If multiple AI sessions run concurrently, treat a PR as a proposed change,
not an instruction to overwrite other sessions' files.
