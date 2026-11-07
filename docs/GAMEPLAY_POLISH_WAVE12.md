# Flooria — Wave 12: Tower Shift and Hue Sort

This wave improves two distinct puzzle experiences, with no engine changes,
score revisions, level generation changes, registry changes or saved progress
migration.

## Tower Shift

- When a disk is selected, towers that can legally receive it gain a soft
  mint surface, a green outline and a small checkmark.
- The selected tower remains violet with a short press-depth transition.
- A disallowed move leaves the state intact and briefly shakes the hint.
- Accessible labels describe peg letter, disk count, selection and whether
  the peg is a valid destination.
- Existing shared game controls and puzzle rules remain unchanged.

## Hue Sort

- Gradient boards use softer borders and shadows.
- Accessible tile labels distinguish the row, column, fixed reference status
  and selection state.
- Swaps, selected-tile scaling, board completion and tile padding honour
  the system reduced-motion preference.

## Verification

- [x] Widget coverage at levels 1 and 90 on 360x640 and 390x844 screens.
- [x] Tower legal-target highlights, rejected placement and deselection.
- [x] Hue fixed-tile labelling, selection and swap count.
- [x] Reduced-motion widget durations.
- [ ] Visual review on a physical Android phone.
- [ ] 1.5x font and landscape visual review.
- [ ] Tablet layouts, frame times, screen readers and finger targets.
- [ ] Short playtests with children and adults.

Passing CI is not independent proof of visual quality or device performance.
