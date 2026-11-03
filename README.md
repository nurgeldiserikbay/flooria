# Neuro Playground

A mobile-first puzzle adventure built with Flutter. Fifty games sit on a branching neuron map; each one also has 100 standalone levels in the Games library.

## Product foundation

- A branching neuron map; each game node contains three consecutive levels
  before it unlocks the next part of the map.
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
| Path Paint | Trace a maze from its entrance to the exit in one continuous stroke | focus |
| Brick Break | Move the paddle to clear every block | control |
| Tower Shift | Move every disk to the goal peg without stacking a larger disk on a smaller one | planning |
| Merge 2048 | Slide and combine equal tiles to reach the target | logic |
| Snake | Steer the snake to food and reach the length goal | control |
| Tetris | Rotate and place falling blocks to clear the line goal | spatial |
| Pair Match | Turn over cards and find every matching pair | memory |
| Precision Stop | Stop the timer as close as possible to each target | control |
| Peg Solitaire | Jump pegs to leave one on the board | planning |
| Number Sequence | Choose the value that continues each number pattern | math |
| Sokoban | Push every crate onto a marked pad | planning |
| Lights Out | Switch off the board by toggling neighbouring lights | logic |
| Number Maze | Reach the exit while managing energy across numbered cells | planning |
| Minefield | Reveal safe tiles using number clues | logic |
| Color Flood | Grow one connected colour region across the board | perception |
| Water Sort | Pour coloured layers into tubes until each tube is sorted | planning |
| Nonogram | Fill cells using row and column number clues | logic |
| Domino Chain | Connect every domino to the matching open end | logic |
| Whack the Target | Tap each highlighted target before it moves | control |
| Color Catcher | Catch fruit and dodge bombs by moving between lanes | control |
| Mirror Beam | Rotate mirrors to route a laser into its receiver | logic |
| Clone Shift | Guide two linked explorers whose horizontal moves are mirrored | planning |
| Shadow Bridge | Turn the light to reveal safe shadow tiles across a gap | spatial |
| Magnetic Room | Send magnetic pulses; metal tiles carry the core farther | planning |
| Tide Shift | Reach high ground before rising water floods the low tiles | planning |
| Shape Shift | Change form to fit through a sequence of gates | control |
| Orbit Catch | Switch orbital lanes to collect stars and dodge meteors | control |

Games share the chrome in `lib/ui/game_kit.dart` and pick their own palette.

The product concept and module contract are described in [docs/GAME_CONCEPT.md](docs/GAME_CONCEPT.md) and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Run locally

```sh
flutter pub get
flutter run -d chrome
flutter analyze
flutter test
```

When the approved games are ready, place each module in `lib/games/<game_id>/`, keep its rules separate from its Flutter screen, and register it in `lib/core/game_registry.dart`.
