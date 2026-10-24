# Neuro Playground — additional SVG asset pack

This batch extends `NEURO_ASSETS.md` without overwriting the existing Flooria tower or screens.

## Game tiles (96 viewBox)

- `neuro-icon-colors.svg`, `neuro-icon-sequence.svg`, `neuro-icon-maze.svg`
- `neuro-icon-reaction.svg`, `neuro-icon-pattern.svg`, `neuro-icon-word.svg`
- `neuro-icon-sudoku.svg`, `neuro-icon-2048.svg`, `neuro-icon-trail.svg`, `neuro-icon-fifteen.svg`

## Map tokens (96 viewBox)

- `neuro-node-locked.svg`, `neuro-node-available.svg`, `neuro-node-current.svg`, `neuro-node-special.svg`
- Previous batch: `neuro-node-active.svg`

## Player and branding

- `neuro-avatar-top-move.svg`, `neuro-avatar-top-selected.svg`
- Previous batch: `neuro-avatar-top.svg`
- `neuro-brand-symbol.svg`

## Rewards

- `neuro-reward-star.svg`, `neuro-reward-coin.svg`, `neuro-reward-gem.svg`, `neuro-reward-heart.svg`

## Navigation (64 viewBox)

- `neuro-nav-map.svg`, `neuro-nav-games.svg`, `neuro-nav-analytics.svg`, `neuro-nav-records.svg`, `neuro-nav-profile.svg`, `neuro-nav-settings.svg`

## Implementation notes

Flutter asset directory already declared in `pubspec.yaml`. Use `SvgPicture.asset('assets/design/neuro-nav-map.svg')` via existing `flutter_svg` dependency.

SVG files are original vector prototypes, not pixel-cut extracts of AI mockups. The map's paths, radar chart, gradients and interaction states should be implemented as procedural UI. For movement tween along curves, animate one avatar widget along a path rather than generating many sprite PNGs.

No UI code, game logic or current Flooria navigation has been modified by the asset commits. Visual verification in the running app remains necessary.
