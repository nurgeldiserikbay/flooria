# Flooria — calmer game-first visual shell

## Direction

**Playful enough for children; quiet enough for adults.** This is not an
enterprise dashboard or an educational form. The player should see a place to
explore, then a game to play. Preserve the neural map, existing unlocked games,
progress, analytics, saved preferences and working level transitions.

### Experience rules

- **World first:** the neural map, not panels or navigation, fills the home.
  The first open neuron should be visible without a manual pan.
- **Only three destinations:** Map, Games, Skills. One compact floating switcher
  lives near the top; no full-width bottom tab bar.
- **Keep affordances, remove clutter:** progress and Settings remain available
  at the top. Locked and open neurons differ by color, glow, and semantics
  without tiny overlaid level-number badges.
- **The library is a playable catalog:** all registered games remain reachable
  for QA. Skill filters and favorites still work. A game card shows its
  illustration, title, and next level; category is already visible in filters.
- **Game board is the hero:** no decorative sparkles behind playfields. A quiet
  game header shows Back, name, level and game-specific controls.
- **One clear success path:** Next Level stays the primary action; Replay stays
  secondary; three stars remain recognizable without heavy result boxes.
- **Inclusivity:** readable navy text, softly tinted white surfaces, warm
  highlights, 44px touch controls, reduced-motion support and semantics.

## Visual system

| Element | Treatment |
| --- | --- |
| Background | Quiet pearl-white with pale lavender / blue / peach atmosphere |
| Accent | Muted periwinkle #8176D7 for navigation, game-specific accent in boards |
| Text | Deep slate #29354F; secondary #71809B |
| Navigation | 50px floating capsule, labeled icons, no bottom bar |
| Library cards | Soft 23px radius, subtle edge and diffuse shadow |
| Game chrome | Small back affordance; title + level without a secondary badge |
| Stats | Compact 13px rounded translucent chips, barely-there borders |
| Result panels | Rounded white surface with diffuse shadow; minimal chrome |
| Motion | 120–260ms purposeful transitions; instant when reduce-motion is enabled |

## Applied scope of this PR

- [x] Floating top navigation shared by Map / Games / Skills.
- [x] Home header simplified; settings and progress remain visible.
- [x] Initial map camera focuses the next available neuron.
- [x] Removed redundant tiny map-node level badges.
- [x] Games library: cleaner title, one icon-only Surprise action, simpler cards.
- [x] Skills: human-readable heading, no redundant explanatory line.
- [x] Settings: two uncomplicated preferences, no debug-like footer.
- [x] Shared game header: remove starred level badge and backdrop sparkles.
- [x] Shared stat chips and result/retry panel borders softened.
- [x] Reduced-motion preferences honoured in shared panels and switcher.
- [x] Widget smoke checks for two common phone sizes and initial map visibility.

## Important remaining work

- [ ] Visual screenshots on 360×640, 390×844, and a tablet in actual Flutter
  renderers; no tool-only CI can prove the design is visually great.
- [ ] Real Android touch, memory pressure, 60fps pacing and orientation checks.
- [ ] Accessible contrast and large-text sizing (1.3–1.5x).
- [ ] Review map's **background image repeat / parallax** on device; keep fog
  and dendrites but avoid blurry scaling.
- [ ] Review the whole 50-game catalog, including win, fail, replay and next.
- [ ] Make real-world playtesting with children and adults part of acceptance.

### QA gates

1. All 50 registered games remain available in Games library.
2. Navigation Map → Games → Skills → Map and Settings works.
3. On a fresh install, first playable neuron appears in the viewport.
4. No RenderFlex overflow at 360×640 and 390×844.
5. No change to saved IDs, user progress or deterministic game engines.
6. `flutter analyze`, `flutter test` and release web build pass.

This is a coherent shell pass, not a claim that every screen has been
individually re-art-directed or device-verified.

## Map polish follow-up (7 November 2026)

A separate stacked PR implements the next layer of world polish:

- **No stretched panorama:** the existing seamless neural background texture
  is tiled at native scale in map space, so it follows pan and zoom while the
  overall screen atmosphere remains stationary. This creates subtle depth
  without new UI or asset downloads.
- **Space between nodes:** the final 37 positions were staggered and spread
  vertically. Previously nodes 39–48 nearly shared a single row and overlapped.
- **More inviting start:** the initial camera opens at about 125% of viewport
  width, so the graph responds to horizontal panning without requiring zoom.
  The player still starts focused on the next playable neuron.
- **Clearer hierarchy:** completed nodes are 62 logical pixels across and
  locked ones 49; unlocked nodes remain prominent and locked colors are softer.
- **Performance and accessibility:** static texture/connection layers have
  repaint boundaries; repeating ambient particles and node pulsing stop when
  the app's motion toggle is off or system reduced motion is enabled.
- **Checks:** 360×640, 390×844 and 800×1100 responsive camera tests, collision
  regression checks for late nodes, repeat-background assertion and reduced-
  motion panning test.

The static world texture uses the existing bundled image. Visual/animation
checks on a real Android device and a large-text audit are still outstanding.
