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
