# Flooria — Wave 11: peg-jump clarity and mirrored character motion

This wave polishes two distinct game modules without changing their engines,
level generation, scores, map or persisted progress.

## Peg Solitaire

- The selected peg is visually raised; legal jump destinations glow in a
  different colour and use a distinct ring icon.
- Pegs use a restrained glossy material treatment, while empty board holes
  remain visible.
- Tapping the selected peg again immediately clears its highlight. Before
  this update the engine did deselect correctly, but the screen skipped a
  rebuild because the action result was `ignored`.
- Invalid selections shake the hint line without changing the puzzle state.
- Board cells expose row, column, occupancy and available landing states.

## Clone Shift

- Both mirrored explorers glide to their next positions rather than
  teleporting; goals and blocked terrain are distinguishable by silhouette
  and surface treatment.
- Movement is kept independent for the two avatars. The existing mirrored
  horizontal control and move budget are unchanged.
- Directional input with no positional change gives a brief hint response.
- Board cells expose rows, columns, goals, walls and explorer positions.

## QA and remaining work

- [x] Add tests at level 1 and level 90 on 360x640 and 390x844.
- [x] Verify restart, legal jump, deselection, paired clone movement,
  and reduced-motion behavior.
- [ ] Inspect the final layout on physical Android phones.
- [ ] Check enlarged text, screen-reader gestures, latency, and frame times.
- [ ] Run short play sessions with children and adults to evaluate fun,
  clarity and difficulty — widget tests alone cannot validate enjoyment.
