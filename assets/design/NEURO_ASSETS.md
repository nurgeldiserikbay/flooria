# Neuro Playground — starter SVG assets

These are lightweight editable SVG prototypes for the planned neuron-map redesign. They do not replace the existing Flooria visuals or implement gameplay.

- `neuro-avatar-top.svg`: top-down robot avatar (map token).
- `neuro-icon-memory.svg`: memory.
- `neuro-icon-logic.svg`: logic.
- `neuro-icon-math.svg`: mathematics.
- `neuro-icon-speed.svg`: speed.
- `neuro-node-active.svg`: active/cleared neuron.

Flutter already declares `assets/design/` and uses `flutter_svg`. Load with `SvgPicture.asset('assets/design/neuro-avatar-top.svg')`.

Connections, locked nodes, gradients, buttons, panels and radar charts should be implemented as dynamic Flutter drawing/widgets (or SVG/CSS in a future web frontend) rather than baked screenshots. Maintain a flat dark-indigo + bright color visual system and keep gameplay and navigation functional.

This batch contains vector sources, not cropped sprites from a concept image. No game screens have been changed.
