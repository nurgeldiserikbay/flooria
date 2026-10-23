# Flooria — The Endless Tower

A playable, offline-first Flutter puzzle tower with a continuous pastel 2.5D
world. Web preview: https://nurgeldiserikbay.github.io/flooria/

## Working features

- **Tower / Home**: reusable architectural storeys, live floor and game labels,
  objectives, a Play button and automatic floor progression.
- **2048**: swipe/keyboard movement, scores, goals, restart and win condition.
- **Number Trail**: seeded sequence puzzles, per-round feedback and goals.
- **Games**: All / Recent / Favorites, working 3-column cards and practice
  game detail screens. Color Match, Sudoku, Memory and Fifteen are clearly
  marked as **Soon**, not presented as playable.
- **My Mind**: persisted floor progress, completed floors, favorites, unique
  played games; achievements derived from real local progress.
- **Settings**: persisted ambient-motion and haptic feedback preferences.
- **Victory**: reusable result dialog, next-floor or tower navigation.
- **Responsive interface**: portrait phone-first with larger-screen constraints.

## Run locally

```sh
flutter create --project-name flooria --platforms=web,android,ios .
flutter pub get
flutter run -d chrome
flutter analyze
flutter test
```

The deployed web version is built by GitHub Actions on pushes to `main`.
Each successful deploy uploads `flooria-ui-screenshots` (mobile sizes
360×800, 390×844 and 430×932) for **visual** verification.

## Art production

The real UI is not a screenshot. Shared sky, ruins, foreground clouds and
**empty transparent architectural storeys** are separate optimized assets
in `assets/design/`. The generator is `tools/build_production_assets.py`;
its input is an approved design board already in `assets/`. Labels,
numbers, progress and actions remain live Flutter widgets.

See `docs/design/screen-blueprints.md` and `docs/design/tokens.json`
for the shared visual contracts.

## Current scope

The interface, progression shell and two existing mini-games are functional.
The four preview mini-games have not been implemented yet. Device QA,
sound, privacy-policy publication and store release preparation are separate
release checks; a successful web build alone does not certify them.
