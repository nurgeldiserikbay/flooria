# Neuro Playground

A mobile-first puzzle game foundation built with Flutter. The game catalog is intentionally empty while the game list is being reviewed.

## Product foundation

- A branching neuron map with open, locked, and completed nodes.
- A Games library that lists only approved and unlocked modules.
- A Skills view that displays only measurements reported by games.
- Local progress, level records, skill scores, favorites, motion, and haptic preferences.
- A shared visual style drawn in Flutter with gradients, shapes, and vector icons; no game artwork is required.

The product concept and module contract are described in [docs/GAME_CONCEPT.md](docs/GAME_CONCEPT.md) and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Run locally

```sh
flutter pub get
flutter run -d chrome
flutter analyze
flutter test
```

When the approved games are ready, place each module in `lib/games/<game_id>/`, keep its rules separate from its Flutter screen, and register it in `lib/core/game_registry.dart`.
