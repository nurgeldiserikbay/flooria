# Parallel development playbook

## Current state
Nine playable mini-games are registered centrally in `lib/core/game_registry.dart`.
`GameRegistry.games` supplies catalog/detail/map metadata.
`GameRegistry.buildPage` wires concrete Flutter screens with the app's result callbacks.
`GameRegistry.campaignIds` preserves the original nine-game order.
`FloorEngine` reads the campaign sequence from the registry.

The project still has legacy shared integration files for objectives and stats.
**Do not let separate game-authoring sessions edit those shared files.** Only
the integration owner extends them when merging completed game PRs.

## Suggested five parallel work lanes
| Lane | Owns | Must not change |
| --- | --- | --- |
| New puzzle A | `lib/games/<id>/`, `test/games/<id>/` | Registry, main, floor/progress |
| New puzzle B | Different `lib/games/<id>/`, tests | Files from lane A or shared files |
| New puzzle C | Different `lib/games/<id>/`, tests | Files from A/B or shared files |
| Design polish | One agreed UI/component scope | Game engines and game wiring |
| Integration / QA | Registry, shell, schedule, stats, shared tests | Other sessions' WIP branches |

A single integration owner merges PRs one at a time. CI must pass **after**
updating the PR branch with latest main. Deployment occurs only from main.

## Workflow
1. Assign each session a unique branch and an exclusive directory/scope.
2. Authors implement game rules + UI independently; do not change shared state.
3. PR describes `id`, title, icon, mechanics, difficulty, win/fail, result
   fields, launch signature, seeded tests, and which shared integration is needed.
4. Integrator reviews duplication and accessibility, registers the game,
   adds an objective and persisted metrics, then runs all tests.
5. Append the game ID at the END of the campaign sequence **only when intentional**;
   do not reorder or insert existing IDs. Campaign sequencing and difficulty
   migrations are separately reviewed. PR validation must be green.
6. Merge one PR, update other feature branches with new main, and repeat.

## Game module contract for new modules
```
lib/games/bridge_balance/
  bridge_balance_engine.dart  # rules only; no Flutter dependency
  bridge_balance_page.dart    # Flutter view, internally responsive
test/games/bridge_balance/
  bridge_balance_engine_test.dart
  bridge_balance_viewport_test.dart
```
Preferred view constructor (can be adapted to the mechanic):
```dart
const BridgeBalancePage({
  super.key,
  this.floor,
  required this.onComplete,
  required this.onSessionEnd,
});
```
`onComplete` is invoked exactly once when a tower level is earned.
`onSessionEnd` reports measured performance; practice mode may record a
session without advancing the tower. The page owns no preferences/database.

An engine must expose an unambiguous completion condition; invalid actions
must not mutate state. Randomly generated puzzles must admit a solution.
Guard async win dialogs and animation callbacks against restart/disposal.

## Shared files (integration owner)
- `lib/core/game_registry.dart`: all catalog metadata, routes, campaign IDs.
- `lib/game/game_objective.dart`: objective specification for the new ID.
- `lib/game/player_stats.dart`: new optional backwards-compatible stored fields.
- `lib/main.dart`: shell callback to persist results.
- `lib/ui/neuro_hub_pages.dart`: personal record when necessary.
- Shared map and category visual tokens: only when needed.

## Guardrails
- `main` is never a workspace for multiple parallel sessions.
- An isolated feature PR should NOT fail merely because it isn't registered yet:
  new modules can be imported and tested independently.
- No remote code plugins or runtime-loaded source files.
- No duplicate navigation bars inside game pages.
- Keep screens usable without vertical scrolling where practicable.
- Do not change `package` IDs, shared preferences keys, game IDs, scoring
  definitions, or the floor cycle without a migration plan.
- Avoid mass formatting and auto-generated file churn.
- If no CI quota, report unverified work as unverified; don't claim green tests.

## Copy-paste task prompt
> Work on the Flutter game repository `nurgeldiserikbay/flooria`.
> Read `AGENTS.md` and `docs/PARALLEL_DEVELOPMENT.md`. You are one of
> multiple parallel sessions. Create a fresh branch named
> `feature/<unique-game-id>` from current `main`. Implement only your
> assigned game in `lib/games/<id>/` and `test/games/<id>/`.
> Do NOT change the central registry, main.dart, saved progress, catalog,
> shared CI or another game's files. Keep rules pure Dart, layout scroll-free
> on phone screens, include seeded/solvability tests, and propose integration
> details in your PR. Run `flutter analyze`, `flutter test`; open a PR
> toward main. Do not merge the PR. Tell me the PR URL and status.
