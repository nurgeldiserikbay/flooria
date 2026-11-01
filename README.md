# Neuro Playground

A mobile-first puzzle adventure built with Flutter. Eight games sit on a branching neuron map; each one also has 100 standalone levels in the Games library.

## Product foundation

- A branching neuron map with open, locked, and completed nodes.
- A Games library that lists only approved and unlocked modules.
- A Skills view that displays only measurements reported by games.
- Local progress, level records, skill scores, favorites, motion, and haptic preferences.
- A shared visual style drawn in Flutter with gradients, shapes, and vector icons; no game artwork is required.

## Games

| Game | Mechanic | Skill |
|---|---|---|
| Pattern Repeat | Watch a light sequence, then repeat it | memory |
| Find the Number | Spot one number among distractors | focus |
| Hue Sort | Swap tiles to restore a colour gradient | perception |
| Synapse Link | Turn tiles until the signal reaches every neuron | logic |
| Target Sum | Combine tiles into an exact total | math |
| Ice Slide | Slide a puck that only stops at walls onto the ring | planning |
| Shape Turn | Pick the shape that is turned, not mirrored | spatial |
| Signal Guard | Tap go signals, hold back on the rest | control |

Every generated level is checked by tests to be solvable; games share the
chrome in `lib/ui/game_kit.dart` and pick their own palette.

The product concept and module contract are described in [docs/GAME_CONCEPT.md](docs/GAME_CONCEPT.md) and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Run locally

```sh
flutter pub get
flutter run -d chrome
flutter analyze
flutter test
```

When the approved games are ready, place each module in `lib/games/<game_id>/`, keep its rules separate from its Flutter screen, and register it in `lib/core/game_registry.dart`.
