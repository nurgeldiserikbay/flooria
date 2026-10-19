# Flooria Architecture (Foundation)

## Goals
- One Flutter codebase for Android, iOS, and Web.
- Offline-first progress, no player account or personal data backend.
- A mini-game can run in Tower mode, Library mode, or a future standalone application.
- Keep game rules independent of Flutter widgets and the UI framework.
- Reuse procedural vector drawing instead of large texture packs where possible.

## Current implementation
- `lib/game/merge_2048.dart`: isolated 2048 rule engine.
- `lib/game/floor_engine.dart`: deterministic initial two-game tower schedule.
- `lib/main.dart`: initial Flooria soft visual language, library and navigation.
- SharedPreferences: initial local floor, favorites, recent games. Full session persistence is pending.

## Module design contract (target)
Each module should provide:
- A stable identifier and a version.
- Immutable launch configuration: mode, challenge seed, difficulty, optional content ID.
- Level provider: generated, curated, or hybrid.
- Pure rules/session object and serializable game state.
- Renderer and input adapter, separate from rules.
- Result with completion, moves, timing, accuracy, and hints used.
- Gameplay tests validating reachability, solvability and save/restore.

The Tower Director must depend on module descriptions, not concrete module classes.
The Game Library owns independent game progression. Tower completion must never
silently skip that progression.

## Offline data
The player's floor, recent activity, favorites, personal levels, and results remain
on their own device. Future migrations will introduce an indexed local database and
portable backups. Deleting content must not delete progress.

## Constraints
No remote executable plugin loader. New engines ship with normal app releases.
Additional puzzle datasets and visual assets may eventually be versioned separately,
but network-delivered game updates are out of current scope.

## Next engineering tasks
1. Extract dedicated GameRegistry, GameHost and two reusable UI renderers.
2. Implement persisted standalone level progression and session resume.
3. Improve deterministic tower challenges and difficulty validation.
4. Add Snake and Fifteen Puzzle modules.
5. Add accessibility, reduced motion and widget tests.
6. Replace temporary web scaffold generation with checked-in platform projects.
