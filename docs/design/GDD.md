---
tags: [design]
status: draft
---

# Game Design Document

## 1. Core game (faithful recreation)
Drop fruit from the top of a jar. Two identical fruits that touch merge into the next tier. Game over when fruit stays above the danger line.

- **Tiers (11):** cherry → strawberry → grape → dekopon → persimmon → apple → pear → peach → pineapple → melon → watermelon
- **Spawn pool:** only the 5 smallest tiers can be dropped.
- **Next preview:** show the next fruit.
- **Scoring:** merging tier *n* awards a triangular-number score (1, 3, 6, 10, …). Two watermelons merging vanish.
- **Controls:** ←/→ or A/D move the dropper, Space/↓/S drop, R restart; mouse aim + click also works.
- **Layout:** jar on the left, abilities panel on the right (buttons defined later).
- **Physics:** `RigidBody2D` circles inside a `StaticBody2D` jar; merge on `body_entered` between equal tiers.

## 2. Twists (backlog, to be narrowed down)

### Gated player abilities
Unlocked or bought during a run, each with limited uses.
- **Hold slot:** store the current fruit and swap it in later (like Tetris hold).
- **Purchasable swap:** spend currency to reroll the *next* fruit.
- _Ideas:_ shake the jar, pop a single fruit, slow-motion drop.

### Gameplay modifiers
- Bomb fruit (clears the area around it), wildcard (merges with anything), ice block (needs two hits), gravity flip.

### Roguelite runs
- A run is a series of rounds with score targets. Between rounds, pick 1 of 3 upgrades: wider jar, longer preview, score multiplier, extra hold slot.
- The currency earned from merges pays for abilities (see above).

### Modes
- Classic, Timed, Daily seeded challenge, Endless with a rising danger line.

## 3. Open questions
- Which currency drives purchases: score, or a separate coin dropped by merges?
- Do abilities carry between runs (meta-progression) or stay within one run?
- Target platform: desktop only, or also web/mobile (portrait 720×1280 is set up for both)?

## 4. Milestones
1. **M1 — Core clone:** drop, merge, score, game over. _Implemented 2026-11-02; awaiting playtest._
2. **M2 — Juice:** sounds, particles, screen shake, combo text.
3. **M3 — Abilities:** hold slot and swap.
4. **M4 — Roguelite loop.**
5. **M5 — Modes.**
