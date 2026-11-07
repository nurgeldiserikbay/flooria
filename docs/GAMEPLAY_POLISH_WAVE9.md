# Flooria — Wave 9: Moving worlds

This is the independent change log for PR #102, kept separate from
the shared visual roadmap because PR #101 is updating it concurrently.

## Wave 9 — moving worlds: Tide Shift and Orbit Catch (8 Nov 2026)

Wave 8 (locks, numerical patterns, timed targets) is being developed in a
separate session/PR. Wave 9 intentionally touches different modules, avoiding
parallel edit conflicts.

- [x] **Tide Shift:** distinguish dry high ground, sand and flooded tiles with
  soft gradients; smoothly recolour newly flooded cells; animate player and
  goal markers; expose position/terrain through tile accessibility labels.
  The four movement controls now have directional tooltips. Blocked moves
  shake the hint without advancing the game.
- [x] **Orbit Catch:** smoothly interpolate the player along the shortest
  angular path, including wrap-around between first and last sectors, and
  between the two orbital lanes. Gold stars and red meteors now have distinct
  silhouettes, with a bright player beacon. Impact shakes the board briefly.
  Screen readers get orbit, sector and collection progress.
- [x] **Reduced motion:** new movement effects become instantaneous under
  system reduced-motion settings.
- [x] **Tests:** widget smoke/regression coverage for levels 1 and 90 at
  360×640 and 390×844, plus representative movement and reduced-motion checks.

The game engines, difficulty, score and save system are unchanged. CI does
not replace live Android touch, frame-time, accessibility or children/adults
playtesting. Validate these experiences on a device before claiming complete
visual polish across the 50 games.

