# Neuro Playground — Game Concept

## What the game is

Neuro Playground is a polished mobile puzzle adventure. The player travels through a branching map of neuron-like nodes. Each node represents one short game challenge. Completing a node lights it up and opens connected paths, so the player chooses which direction to explore next.

## Core loop

1. Open the map and choose an available node.
2. Play the challenge attached to that node.
3. Complete it to save progress and reveal connected nodes.
4. Replay unlocked game types from the Games library, where each type keeps its own level or best result.
5. Check the Skills view for a compact summary of measurements that games actually report.

## Progression rules

- A new save begins at one open node; later nodes are dimmed and locked.
- The map branches. A node may connect to more than one later node, and later paths may join.
- Completing a node opens its children. A game type may appear on multiple nodes with a higher level or a different target.
- Unlocking a game type adds it to the standalone Games library.
- Standalone progress is stored per game type and resumes at that game's next level.
- The map, catalog, and game implementations are separate. The catalog starts empty until the game list is approved.

## Visual direction

- Minimal, calm, premium-feeling mobile UI with clear hierarchy and little copy.
- English interface with short labels and symbol-led controls, so play does not depend on English fluency.
- A luminous branching map: completed nodes glow, available nodes are bright, locked areas stay subdued.
- Small transitions for opening paths, completing a node, and moving between views.
- Draw interface art directly with Flutter gradients, geometry, and icons. Add external assets only when a specific approved game needs them.
- Keep gameplay screens focused, responsive, and free of unnecessary vertical scrolling.

## Game design bar

Each approved game must have a distinct, satisfying decision mechanic and a clear win condition. A game should remain interesting as its levels deepen, use short instructions, and avoid relying on word knowledge. Rules live in a pure Dart engine; the screen handles input, feedback, and motion. Difficulty and score data are owned by that module and saved through the shared launch/result contract.

## Out of scope until the game list is approved

No game modules, game-specific icons, campaign order, scoring rules, or cognitive-skill claims are selected in this foundation. The Skills view must show only explicit results reported by approved games; it must not invent or imply clinical measurements.
