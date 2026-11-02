---
date: 2026-11-02
status: accepted
tags: [decision]
---

# 0002 — Shake Up rotates the view, not the jar

## Context
The Shake Up flips the jar around its center four times. Rotating the jar's physics bodies quickly risks fruit tunnelling through the walls. A 600×900 jar spinning at full size would also sweep past the left screen edge and over the ability panel.

## Decision
- The jar's physics never move. `ShakeUp` rotates and scales the viewport's `canvas_transform` around the jar center, and rotates the physics space's gravity the opposite way. On screen this looks the same as the jar flipping.
- While spinning, the view zooms to 0.6 so the rotating jar stays on the left side. UI on the `CanvasLayer` is unaffected.
- The 360° turn is split into equal steps (4 × 90°). After each step the sequence waits until the **average** fruit speed drops below a threshold, with a min and max wait. Waiting for every fruit to stop stalled on single bouncing fruit, often fresh from a merge.
- During the shake, gravity is boosted ×2.5 and fruit gets extra linear/angular damping, so it settles quickly. Godot circles have no rolling resistance, so without damping fruit kept rolling and every wait ran to the max. Fruit uses continuous collision detection.
- The sequence is a step list run from `_physics_process` rather than a Tween, because "wait until settled" has no fixed length.
- A cover collision shape closes the jar top while the jar is turned.

## Consequences
- The viewport and physics space outlive the scene, so `ShakeUp` resets the view and gravity on `_exit_tree` (for example on restart mid-shake).
- Anything drawn in world space outside the jar (dropper, next preview) is hidden during the shake.
- All timings are in `config/balance.tres`.
