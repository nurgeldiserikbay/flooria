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

## Wave 5 — polished shared game feel and fast catalog discovery (8 Nov 2026)

This follow-up targets improvements reused across the library, instead of
adding one-off effects to every module.

- [x] **Tactile inputs:** quiet 1.3px borders and diffused shadows replace
  the hardest dark button outlines; pressed travel and immediate actions remain.
- [x] **Palette consistency:** the GameScaffold atmosphere now blends with
  each module's own surface; dark games no longer inherit a white center.
- [x] **Micro-animation accessibility:** result confetti is removed under
  system reduced-motion; progress segments change instantly. Regular users
  keep the brief victory animation.
- [x] **Catalog scanning:** gradient game glyphs, an optional compact
  search icon that expands a title/category search field, a clear empty
  state, and larger fixed-height cards at 1.5× font size.
- [x] **Legacy consistency:** Find the Number now uses GameScaffold,
  Restart, and the shared tactile Next Level button, preserving its
  scoring, board and next-level logic.
- [x] **Automated guards:** tests for search, empty results, text scaling,
  dark backgrounds, reduced motion, two phone sizes and Number Hunt
  progression.

### Still not verified

- [ ] Human visual review of 360×640 and 390×844 renders and actual Android
  touch response; CI widget tests do not judge aesthetic quality.
- [ ] Low-end Android frame timings and image memory use.
- [ ] Other older game modules that bypass the shared components.
- [ ] Localization and user tests with children and adults.

The full catalog and game engines are unchanged. The 50 modules remain
accessible under Games without requiring map unlocks.

## Wave 6 — playful feedback for three puzzle families (8 Nov 2026)

- [x] **Nonogram**: solved row/column clues become violet, filled cells
  receive a restrained glossy inset animation, crossed cells stay distinct.
  Grid cells have explicit row, column and fill-state semantics.
- [x] **Color Flood**: each successful colour change triggers a brief board
  arrival animation and 170ms tile recolouring. The palette uses larger
  circular touch targets, a selected checkmark, accessible colour names
  and softer lighting/shadow around the board.
- [x] **Find a Set**: card selection has a subtle press scale and gentle
  highlight; a valid set transitions to a positive checkmark; an invalid
  trio shakes the instruction line without hiding the rule.
- [x] **Accessibility**: animations across these three modules become
  instantaneous when platform reduced-motion is enabled.
- [x] **QA**: game-specific smoke and tap regressions exercise levels 1 and
  90 at 360×640 and 390×844, plus reduced motion.

No gameplay engines, deterministic puzzle generation, progress storage,
registered IDs or scoring rules were altered. Screenshots on actual Android
devices and individual accessibility audits remain outstanding.

## Wave 7 — spatial, physics and chaining polish (8 Nov 2026)

This wave improves three **different** puzzle families without touching their
deterministic engines, registry, scores, progression, or save data.

- [x] **Picture Assembly:** movable neighbours of the blank are outlined
  gently in teal, the scene fragments cross-fade and scale during slides,
  and the board has a quieter rounded frame. Accessible labels distinguish
  blank, movable and non-adjacent cells.
- [x] **Balance Scale:** the balance beam now eases into its new angle as
  weights are selected, selected weights show a checkmark and semantic status,
  and incorrect checks briefly shake the instruction text. Numeric totals
  remain visible, even with motion disabled.
- [x] **Domino Chain:** the free chain end is an obvious high-contrast cue,
  currently connectable pieces receive a gentle gold outline, each newly
  placed domino arrives with a brief pop, and blocked picks shake the end
  indicator. The placement sequence, mistake count and auto-orientation
  remain unchanged.
- [x] **Accessibility and QA:** new optional effects honour the platform's
  reduced-motion preference, and automated tests exercise levels 1/90 at
  360x640 and 390x844, as well as representative taps and restart.

**Still required:** screenshots from actual devices, landscape and enlarged
text review, long-run profiling, sound/haptic preference integration and
independent playtesting with children. Flutter widget tests cannot alone
prove the games are attractive or that frame times are stable on Android.

## Wave 8 — locks, numeric patterns and timed targets (8 Nov 2026)

This wave polishes three distinct game interactions, without changing their
rules, scoring, level generation, catalog entries or persistence.

- [x] **Combination Lock**: five-digit layouts fit 360px screens alongside
  the delete key, the active position has a readable gold highlight and a
  quick transition when a digit changes, failed guesses produce an unobtrusive
  shake, and tall hint/history panels can scroll. Slot semantics expose the
  selected position and entered digit.
- [x] **Number Sequence**: sequence tiles use gentle raised gradients and
  animate between rounds; incorrectly selected answers are marked with a
  cross and calm retry hint, which clear on the next correct answer.
- [x] **Whack the Target**: target cells scale and glow as the moving target
  appears, successful hits become green, each timed window has a short
  progress strip, and spot semantics identify the target without colour
  alone. The existing Dart timer still drives hits and misses.
- [x] **Reduced motion**: new effects stop when the platform requests
  reduced animations; the timing logic remains unchanged.
- [x] **QA**: widget tests cover levels 1/90, 360x640 and 390x844, five-digit
  input, wrong-to-correct number patterns, level progression and time windows.

Still pending: manual Android touch/sound QA, screenshots, 60fps profiling,
keyboard and screen reader testing, and child playtesting. An automated green
run alone cannot certify visual quality.
