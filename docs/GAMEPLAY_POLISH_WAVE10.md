# Flooria — Wave 10: magnetic, energy and ice puzzles

## Objective

Polish three different gameplay families while keeping their established
engines, scores, level generation and save format unchanged. Work is isolated
to three game pages and a test suite so concurrent contributors can continue
without conflicting changes.

## Changes

- **Magnetic Room:** clearly distinguish walls, magnetic amplifier plates,
  the moving core and its socket with subtle gradients and separate shapes.
  Short transitions show movements; illegal pulses shake the hint instead of
  changing the puzzle state. Cell semantics describe row, column and contents.
- **Number Maze:** legal adjacent, unvisited moves are outlined; visited cells
  remain visibly distinct from the current position and exit. A rejected tap
  receives immediate hint feedback. The board keeps +/- energy values legible.
  Accessible cell descriptions provide location, value, current/visited and
  legal-step state.
- **Ice Slide:** softer ice-rink lighting and puck highlight. Puck semantics
  expose its board position; its slide animation, the goal-ring transition and
  the completion-panel transition honor system reduced-motion settings.

## Regression checks

Widget tests open each game at levels **1 and 90** on 360×640 and 390×844,
exercise restart and representative controls, and verify reduced motion.
The magnetic blocked-pulse check preserves the core's starting position;
Number Maze verifies legal adjacency and rejection of far-away cells; Ice
Slide checks a valid directional input increments the move counter.

## Remaining quality checks

- [ ] Real Android screenshots and manual touch review at 360×640 and 390×844
- [ ] Enlarged-text and landscape screenshots
- [ ] 60fps frame-time profiling on a lower-end Android phone
- [ ] Check controls with a screen reader and keyboard navigation
- [ ] Short playtest sessions with children and adults

CI green means tested Flutter behavior, not independently validated aesthetics
or performance on an actual device.
