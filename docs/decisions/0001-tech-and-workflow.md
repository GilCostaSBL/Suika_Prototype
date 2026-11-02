---
date: 2026-11-02
status: accepted
tags: [decision]
---

# 0001 — Tech stack and workflow

## Context
This is a learning project: rebuild Suika, add twists, and evaluate Claude Code as a workflow tool.

## Decision
- **Engine:** Godot 4.7.2 (standard build), **GDScript**.
- **Renderer:** GL Compatibility. It is enough for 2D and keeps web export possible.
- **Viewport:** 720×1280 portrait, `canvas_items` stretch.
- **Version control:** git, one repo per game (`Projects/SuikaV2` is the root), hosted on GitHub, **trunk-based**: small commits straight to `main`.
- **Docs:** Obsidian vault in `docs/`, versioned with the code.

## Consequences
- Trunk-based means no PR review gate. Each commit must leave the game runnable.
- Claude can validate scripts headless (`--headless --import` / `--check-only`), but visual and feel checks need a human playtest.
