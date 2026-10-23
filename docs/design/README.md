# Flooria — UI design production contract (v1)

**Status:** design-first phase. Existing Flutter implementation is provisional; it is NOT an approved fidelity target. No gameplay code changes until common pages and asset contracts are approved.

## Scope

Design all **shell and navigation screens**, not the inner mechanics/gameplay of individual minigames:

| ID | Screen | Primary content | Navigation |
|---|---|---|---|
| S01 | Splash / Loading | Brand logo, atmospheric architecture, progress if needed | Automatic Home |
| S02 | Tower / Home | Large logo, current floor badge, continuous tower, current objective and Play, two-item navigation | Games, My Mind, active floor |
| S03 | Games Library | All / Recent / Favorites; 3-column mobile icon grid with real data | Back, game detail/launch |
| S04 | My Mind | User progress, summary statistics, achievements shortcut, settings | Back, achievements, settings |
| S05 | Game Detail / Pre-play | Game icon, title, short rules, personal stats, Play | Back, gameplay |
| S06 | Settings | Sound/music toggles, language, theme, privacy, about (only working features) | Back |
| S07 | Achievements | Earned/unearned badges, categories, progress | Back |
| S08 | Common Overlay / Victory | Reusable modal structure, success visuals, Next Floor / Tower; game-specific numbers dynamic | Dismiss/next |

*Do not imply unsupported features exist. Where a screen has not been implemented, retain it as a design specification until its navigation and data handling are developed.*

## Approved art direction

- Style: warm premium pastel fantasy, sunlit stone tower and cloud kingdom; soft 2.5D (not dark/neon, no black heavy outlines).
- Palette: sky blue #9FD4F8; white #FFFDFC; navy ink #334F78; warm ivory #FFF8EE; golden CTA #FFD778; sage #CBE4CD; pale lavender #DDD9EE.
- Light: upper-left diffuse daylight, subtle warm windows, physically consistent across sprites.
- Rounded shapes with believable edge highlights, soft ambient occlusion, carefully controlled shadows.
- One dominant hero per screen and generous negative space. No text baked into hero images.
- Copy: no redundant "Current Challenge" and duplicate game/floor labels; only high-signal information.
- Platform: responsive Flutter web/Android/iOS layout; no fixed pixel coordinate assumptions.
- Home reference: approved supplied portrait mockup with centered giant sprout logo, connected 4-floor tower, clouds hiding its end, cream objective row, glossy gold Play and ivory segmented bottom navigation.

## Screen-by-screen visual contracts

### S01 Splash
Full-screen sky and distant architecture; central centered logo; lower subtle progress, no unnecessary controls. Background and logo independent assets.

### S02 Home
Top 0–19% = centered logo + small floor chip. Middle 18–74% = connected tower with one visually continuous structure; green completed / gold active / lavender locked. Bottom 74–90% = airy objective panel and gold pill CTA; bottom 90–100% = Games / My Mind bar. Ratios are guides only, not hard-coded positions. Tap floor to play/check lock; floor indexing is dynamic. No extra title inside tower except necessary game identification. All cloud occlusions separate and parallax-ready.

### S03 Games
Light sky background; top heading Back + Games; three tabs All/Recent/Favorites; 3-column icon grid at normal mobile widths; no giant containers swallowing icon art. Live favorites and recents (not baked in). Each card shows icon and title.

### S04 My Mind
Pastel environment + one hero motif (growth/tree/sprout). A small group of metrics and navigable rows. Do not manufacture stats: use available data or mark as not yet implemented.

### S05 Game Detail
Single clear game icon, name and concise rules; individual stats and one gold Play. The game selection screen is part of app shell; inner game screen redesign deliberately excluded.

### S06 Settings
Ivory list surface on sky background, real toggles for implemented settings only; links for privacy/about only when connected. Avoid decorative, nonfunctional switches.

### S07 Achievements
Badges/icons in a compact clean grid. Clearly distinguish unlocked vs locked. Achievements require actual tracked progress, not fictional scores.

### S08 Common modal
Small cream/ivory card with trophy/sprout focal art, dynamic result and primary action, secondary return. Avoid baked status text or numbers.

## Required assets and ownership

| Group | Deliverable | Preferred format | Reason |
|---|---|---|---|
| Brand | logo with transparent background, mobile icon | SVG if clean vector; else transparent WebP/PNG | Decorative letterform with sprout |
| Environment | distant sky/architecture | WebP | Painterly detail impossible to reproduce simply by Flutter painting |
| Parallax | far ruins, distant clouds, foreground clouds, side vegetation | Transparent WebP layers | Independent drift, crop and depth |
| Tower | unified repeating architectural module + side arch/windows, cornice, base, transition | Transparent WebP from matching 3D scene or authored SVG | True visual continuity; shared lighting/proportions |
| Game iconography | 2048, Number Trail, etc. | SVG | Reusable scalable motifs |
| UI iconography | back, play, lock, completed, gamepad, brain, gear, volume, etc. | SVG | Consistent stroke and safe scaling |
| Panels/buttons | surfaces, pill outlines, tabs, borders, elevation | **Flutter shapes and gradients by default** | Live sizes, touch states and accessibility |
| Fine decoration | leaf sprigs, particles, trophy, crowns | SVG or WebP | Only where painterly detail makes a difference |

**Never crop the entire screen into assets.** Export independently designed components with true alpha, shared viewpoint and light source. Text, floor numbers, challenge descriptions, scores, tile values and states are always Flutter widgets/data. Do not reuse screenshot fragments as game sprites.

## Asset manifest format

Keep a machine-readable `docs/design/asset-manifest.json` mapping asset id to path, format, dimensions/viewBox, alpha transparency, render layer (sky/far/architecture/foreground/UI), scale method, source composition and status (planned/generated/validated/integrated). Asset is production-ready only when it renders correctly in Flutter at 360, 390 and 430 logical-pixel widths.

## Workflow and acceptance gates

1. **Inventory.** Identify navigation, states and real available data for S01–S08.
2. **Coherent design.** Create a consistent multi-screen design board. Treat AI boards as exploratory until explicitly reviewed. Home remains the visual anchor.
3. **Design tokens.** Define colors, spacing, radii, typography, shadows, button/overlay states and safe-area behavior. Agree across every screen before code.
4. **Art source.** Create tower architecture/backgrounds and icons as independently authored, layered assets, not cutouts from flattened full screenshots. Match lighting/perspective.
5. **Asset verification.** Check transparent edges, no baked labels, scale, resource size, name consistency and visual matches.
6. **Flutter composition.** Implement reusable components. Keep business/game logic unchanged while migrating shell design. Every navigation item and toggle must work.
7. **Golden screenshots.** Capture actual Flutter app at 360×800, 390×844, 430×932, plus short-height mobile and desktop. Check overflows, scaled assets, parallax and clickable hit areas.
8. **Visual compare.** Side-by-side review against approved target at the same viewport; correct major silhouette/composition/material differences first, then shadows/icons/text. CI success alone is insufficient.
9. **Functional and performance gates.** flutter analyze, tests, release build, touch targets, load/paint smoothness, optimized sprites, no regressions.
10. **Approval.** Mark screen completed only after visual and functional checks. Do not describe a new design as complete without actual runtime screenshots.

## Definition of done

- All app-shell screens have approved reference designs, organized component inventory and exports.
- Assets are source-traceable, separate, reusable, appropriately optimized and renderer-verified.
- Final Flutter screenshots convincingly match accepted mockups at relevant sizes.
- A coherent shared theme exists, with responsive layouts, accessibility and no duplicated/baked text.
- Existing gameplay and storage behavior remain intact.
