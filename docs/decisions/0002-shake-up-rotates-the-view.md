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
- Gravity is boosted ×2.5 during the shake so fruit crosses the jar within each pause, and fruit uses continuous collision detection.
- A cover collision shape closes the jar top while the jar is upside down.

## Consequences
- The viewport and physics space outlive the scene, so `ShakeUp` resets the view and gravity on `_exit_tree` (for example on restart mid-shake).
- Anything drawn in world space outside the jar (dropper, next preview) is hidden during the shake.
- All timings are in `config/balance.tres`.
