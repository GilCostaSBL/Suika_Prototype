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
- **Controls:** ←/→ or A/D move the dropper, Space/↓/S drop, 1/2/3 abilities, R restart; mouse aim + click also works.
- **Layout:** jar on the left, abilities panel on the right.
- **Physics:** `RigidBody2D` circles inside a `StaticBody2D` jar; merges are detected by polling contacts between equal tiers.

## 2. Abilities and economy (implemented)
All numbers live in `config/balance.tres` (edit in the Godot inspector).

- **Coins:** 1 coin each time the score passes a multiple of 50.
- **Per run:** coins and abilities reset on restart; nothing carries over.
- **Paid per use:** each press spends the cost; there is no separate "buy then use" step.

| # | Ability | Cost | Effect |
|---|---|---|---|
| 1 | **Fruit Slot** | 5 | Stash the fruit in the dropper; the queue moves on. Pressing again (free) puts the stashed fruit back in the dropper. One stash per payment. |
| 2 | **Fruit Swap** | 10 | Reroll the *next* fruit into a different one. |
| 3 | **Shake Up** (ultimate) | 25 | No drops allowed; a cover slides over the jar, the view zooms out, and the jar turns 360° around its center in four 90° steps. After each step it waits for the fruit to settle before turning again. Fruit tumbles (and can merge). Afterwards every fruit gets a fresh settle grace before it can cause game over. Takes ~8–10 s depending on how full the jar is. |

Abilities are disabled while a Shake Up runs and after game over. See [decision 0002](../decisions/0002-shake-up-rotates-the-view.md) for how the turn is done.

**Future:** art for a locked/unlocked state per ability so players can see at a glance what they can afford (currently buttons simply grey out).

## 3. Twists backlog

### Gameplay modifiers
- Bomb fruit (clears the area around it), wildcard (merges with anything), ice block (needs two hits), gravity flip.

### Roguelite runs
- A run is a series of rounds with score targets. Between rounds, pick 1 of 3 upgrades: wider jar, longer preview, score multiplier, cheaper abilities.

### Modes
- Classic, Timed, Daily seeded challenge, Endless with a rising danger line.

### More ability ideas
- Pop a single fruit, slow-motion drop.

## 4. Open questions
- Should coin milestones scale (e.g. 50, 100, 200…) instead of a flat 50?
- Target platform: desktop only, or also web/mobile?

## 5. Milestones
1. **M1 — Core clone:** drop, merge, score, game over. _Done 2026-11-02._
2. **M2 — Abilities:** coins, Fruit Slot, Fruit Swap, Shake Up. _Implemented 2026-11-02; awaiting playtest._
3. **M3 — Juice:** sounds, particles, screen shake, combo text.
4. **M4 — Roguelite loop.**
5. **M5 — Modes.**
