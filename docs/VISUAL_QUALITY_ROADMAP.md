# Neuro Playground: visual quality and game feel

## Goal

Make Neuro Playground feel like **one polished mobile puzzle adventure**:
bright, joyful, readable and satisfying without interrupting the player.
These are implementation guidelines, not a claim that all 50 modules are polished.

## Code audit (6 November 2026)

- The registry has 50 game modules. The repository already includes
  `GameScaffold`, `ChunkyButton`, `LevelResultPanel`, `RetryPanel`,
  `LevelFlow` and other shared pieces in `lib/ui/game_kit.dart`.
- The Games library draws its own cards in `lib/ui/neuro_hub_pages.dart`.
- At least one older module (`pattern_repeat`) still has a standalone
  `Scaffold`, `AppBar`, level badge and win button, rather than using the
  shared kit. A full per-module audit remains necessary.
- The map already has a background image, fog overlays, dendrites and pulsing
  nodes. Redesign should build on these, not replace or disable them.
- Do not claim tests or device checks passed without running them.

## Design direction

- **Palette:** luminous light backgrounds, readable navy ink, unique accent
  colors per mini-game; no large dark slabs.
- **Objects:** soft highlights, deliberate outlines, restrained solid-depth
  shadows and purposeful color coding; never use color as the only game cue.
- **Visual hierarchy:** playable board is the hero; controls and score must not
  crowd the board. Prefer symbols and short English instructions.
- **Game feel:** short press-squash, motion toward targets, correct-answer glow,
  restrained wrong-answer shake, a distinct but short level-clear celebration.
- **Progression:** winning clearly advances to the next level; a map node
  completes after its assigned sequence. Replay does not grant duplicate wins.
- **Accessibility:** preserve 44px+ tap targets, respect reduced motion,
  readable contrast, semantic labels and non-color feedback.

## Motion budget (guidelines)

| Interaction | Duration | Feedback |
| --- | --- | --- |
| Button / card press | 80–130ms | Squash + return, no delayed input |
| Tile move / swap | 140–240ms | Preserve logical positions |
| Correct input | 120–250ms | Scale, small glow or spark |
| Incorrect input | 220–360ms | Small shake, optional haptic |
| Level complete | 350–850ms | Stars/confetti and clear Next |
| New map link | 500–1000ms | Grow along the connection |

Reduced-motion users receive instant state changes, without essential
information being conveyed only by animation. Avoid infinite animations in
every list card; use animated map ambience sparingly.

## Delivery sequence

1. **Shared polish foundation (this PR):** tactile gradient ChunkyButtons,
   light Flutter-drawn atmosphere, animated Games cards, basic widget tests.
2. **Consistency pass:** identify modules that bypass `GameScaffold` or
   `LevelResultPanel`; migrate them without modifying game engines. Start
   with `pattern_repeat` and apply a shared responsive layout pattern.
3. **Per-game hero pass:** improve boards, feedback, input affordances and
   fail/success states by family, not 50 identical clones. Use paired before/
   after captures and keep each puzzle mechanic distinct.
4. **World pass:** polish the neuron map, connection growth, fog depth,
   mascot movement, unlock transitions and map panning on narrow phones.
5. **Quality gate:** test 360×640, 390×844, landscape behavior where relevant,
   100-level progression, back/retry/next navigation, touch accessibility
   and low-end Android performance.

## Review checklist per game

- [ ] Goal obvious within 3 seconds; tutorial teaches by action.
- [ ] Playfield remains fully visible on 360×640; no accidental scroll.
- [ ] Tap/swipe/drag gives immediate, unmistakable feedback.
- [ ] Correct, incorrect, win, fail and retry states are distinct.
- [ ] Next Level continues; map progress and standalone progress stay correct.
- [ ] No unnecessary text, popups, stale timers or distracting idle motion.
- [ ] Uses common chrome; own palette and board personality.
- [ ] Rule tests, widget viewport tests and real-device inspection complete.

## Wave 2 implementation (6 November 2026)

Polish work shipped **to a review branch**, not automatically considered
released or device-verified:

| Game | Improvements | Quality still to verify |
| --- | --- | --- |
| Pattern Repeat | Shared game chrome, star celebration, replay and Next | Small-screen victory layout; timed playback and accessibility |
| Pair Match | 3D card flip, matched-card glow/check, retained widget state | Mismatch flip timing; reduced motion |
| Lights Out | Animated brightness, gradient tiles, glow and accessibility labels | Dense grid touch targets and contrast |
| Water Sort | Animated liquid layers, glass shading, selected-tube lift, blocked action shake | Tubes across narrow devices; pour legibility and performance |

The next review round should capture screenshots and interaction recordings
at 360×640 and 390×844, then apply the same quality criteria to spatial,
arcade and route-finding games. No claims about all 50 game screens can be made
until they are reviewed individually.

## Wave 3 implementation (6 November 2026)

A further six distinct mini-games were visually polished without touching
their deterministic rules engines, scoring, catalog, or progress persistence.

| Module | Changes |
| --- | --- |
| Merge 2048 | Animated number changes, tile depth, contrast and stable board/cell keys |
| Sokoban | Animated crates and player, deeper floor/goal cues, wall-block feedback and tactile 44px arrow controls |
| Bubble Shooter | Glossy bubbles and animated appearance/pop, clearer next projectile and blocked-shot feedback |
| Path Paint | Visible illuminated continuous trail, differentiated start/goal and blocked-trace state |
| Snake | Fruit-spawn pop, dimensional character segments, directional eyes and food shading |
| Brick Break | Ball motion trail, glint/halo, brighter paddle and playfield polish |

Game feel animations must remain short, optional under reduced motion, and
must never delay the game engine or next-level transition. A six-game smoke
suite exercises level 1 and level 90 on 360x640 and 390x844 screens, plus
basic swiping, tapping, dragging and arcade timer lifecycle. CI results
are authoritative only after they finish on the final PR commit.

These are targeted code-level improvements, not a substitute for visual
inspection on a real touch device. Future work should prioritize snapshots,
screen recording and frame pacing across the full 50-game catalog.

## Wave 4 implementation (6 November 2026)

This wave focuses on spatial reasoning, routing and placement; it does not
alter the pure Dart game engines, registry, scores or persisted progression.

| Game | Gameplay-specific feedback |
| --- | --- |
| Mirror Beam | Animated light-beam route, gradual mirror rotation, glossy reflective pieces |
| Rope Untangle | Thick shaded cords, shiny numbered nodes, selected-knot halo |
| Gravity Shift | Rolling orb animates between grid stops, wall bump shakes the board |
| Knight's Tour | Knight slides between legal chess cells; readable visited / target / available states |
| Rail Router | Train wagons move along rails, visible sleepers, colored junction and bypass |
| Tangram Fit | Colorful raised puzzle pieces, selected-piece pop, clear placement and blocked-move feedback |

The wave includes mobile widget smoke coverage for levels 1 and 90 at 360×640
and 390×844, plus interaction checks for each game. All visual animations
should respect reduced motion. A CI green result is not equivalent to a
real-device visual QA; specifically review small control targets,
frame pacing, accessibility and win-panel fit on Android.
