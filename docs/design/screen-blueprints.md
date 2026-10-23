# Flooria — Screen blueprints and art export checklist (v1)

These are production layouts, not proof that the Flutter runtime matches. The accepted portrait reference remains the Home art-direction anchor. Mockups must be reviewed **before** slicing/exporting assets.

## Universal composition
- Source artboard: 390×844 logical px, with alternate targets 360×800, 430×932 and desktop 560×900. All UI stays inside safe areas.
- Sky/background takes full screen, shared ambient lighting upper-left. Distant ruins and parallax clouds are independent layers.
- One focal object per screen; no extra heading where the hero already communicates purpose.
- Gold is strictly primary action / active floor; sage means completed; lavender means locked.
- Navigation and CTA positions are consistent; no separate decorative borders for every image.
- Base style: premium soft 2.5D fantasy rather than 3D chrome/glass/neon.

## 01 — Splash
**Status:** proposed / unimplemented. Hero = distant kingdom and large logo centered at y≈38%, below sparse loading progress at y≈86%.
No tower status, no buttons. Progress may be omitted for instant loading. Artwork: far sky, ruins, clouds, independent transparent logo. Text only when actual loading is measurable.

## 02 — Home (design anchor)
**Status:** implemented but pending pixel-fidelity review. Hero = visually continuous tower at x≈center, from y≈20–75%. Logo max readable width approx 310–340 on 390px viewport, positioned at top with separate floor chip. Four nearby architectural tiers shown when height allows; top and base vanish into soft clouds.
Levels carry dynamic number, game icon and compact state; active gold glow, completed green, locked lavender. Do **not** display verbose names on all levels. A compact ivory mission panel near 76–86% contains only icon + goal; remove 'Current Challenge'. Under it a glossy gold 'PLAY' pill. Games / My Mind bottom segmented bar sits above bottom safe area.
Art budget: sky; far-ruins; back tower shaft; repeatable module with matching stone cornices; small side-arches; foreground clouds; optional vegetation.
Visual acceptance: no visible horizontal cracks between modules; no label clipping; active state clearly distinguishable; perspective and lighting consistent. On scroll/advance, tower must still look continuous.

## 03 — Games Library
**Status:** implemented; visuals provisional. Header = Back + 'Games'. Segmented tabs All / Recent / Favorites at y≈11–16%; grid starts below. Exactly three columns at phone width; one icon and short label each. White ivory elevated tile surfaces with restrained shadow and consistent 12–16px spacing. Empty Recent/Favorites has a gentle tiny sprout illustration and a plain message, not a giant empty dialog. Floating bottom nav may be omitted on drill-down if consistent Back action.
Never show future games as tappable until implemented. Unavailable games may be omitted or shown as labeled 'Coming soon' previews with no tap.

## 04 — My Mind
**Status:** implemented, data audit required. Header Back + 'My Mind'. A single hero illustration (tree/sprout or brain-growth symbol) anchored in a cloud courtyard. Below: progress summary 'Floor N' from stored floor, played count from available tracked stats only. Clearly titled navigation for 'Achievements' and 'Settings' only once these pages are functional.
Avoid claims about total score, streak, achievements when none is tracked; placeholders belong in designs, not product runtime.

## 05 — Game Detail
**Status:** proposed. Header back + floor badge (optional). Main hero = large game icon with one-line title and concise mechanic, stats only when tracked. Gold Play CTA fixed near lower safe area. Distinguish tower challenge launch from library practice launch; only successful tower games progress floors.

## 06 — Settings
**Status:** proposed. Back and title, ivory grouped list. Audio and music toggles only after implementation; language/theme rows only if actually supported. Privacy Policy and About should be working routes/links. Prefer native Flutter switches rendered with shared tokens. Background reuses scene not game screenshot.

## 07 — Achievements
**Status:** proposed. Back/title and segmented category if meaningful, a 3-column compact emblem grid. Locked is neutral lavender, earned gold/sage. Unlock logic is sourced from actual persisted stats. Avoid fake values displayed in concept board.

## 08 — Victory Modal
**Status:** implemented, style provisional. Compact ivory rounded card over desaturated/frosted current scene. Gold/sage crown/trophy art above 'Floor complete' and one dynamic accomplishment line. Primary 'Next floor' and secondary 'Tower'. Do not crop pre-baked full victory picture with numbers/text; reuse independent emblem.

## Reusable components
| ID | Description | Implement with |
|---|---|---|
| C01 | Ivory rounded back icon button | Flutter shape + SVG arrow |
| C02 | Gold glossy primary pill | Flutter gradient/shadows + SVG play |
| C03 | Ivory secondary pill | Flutter decoration |
| C04 | Bottom segmented Games / My Mind | Flutter widgets + SVG |
| C05 | All / Recent / Favorites segments | Flutter |
| C06 | Small floor number chip | Flutter |
| C07 | Objective/quest compact card | Flutter + icon SVG |
| C08 | Game card | Flutter frame + icon SVG |
| C09 | Achievements emblem | independent SVG |
| C10 | Modal surface | Flutter + separate decorative WebP/SVG |
| C11 | Tower architectural repeated module | independent transparent SVG or rendered WebP |
| C12 | Parallax foreground/mid/far layers | independent transparent WebP |

## Exports and visual QA
1. Export background layers separately with no labels, UI, buttons or tower baked into them.
2. Export tower module variants from one common base template; same viewBox, silhouettes, camera, and light. Status tint alone must not change geometry.
3. Use named and normalized assets: `assets/design/{backgrounds,tower,icons,decor}/...`; every new export declared in manifest.
4. SVG icons should have compatible stroke/fill language, predictable viewBox and alpha. No font dependencies or external links.
5. Validate by showing actual Flutter screenshots at 360×800, 390×844, 430×932 and short landscape/small mobile. Compare side-by-side at **identical** dimensions.
6. Record each screen as `concept`, `approved`, `assets-ready`, `implemented`, `visually-verified`. CI success does not imply visual approval.
7. Reject screens with obvious sprite seams, distorted tower modules, clipped text, functional dead ends or fake analytics.
