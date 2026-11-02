class_name Balance
extends Resource

## Tunable numbers for the run economy and abilities.
## Edit res://config/balance.tres in the inspector to tune without touching code.

@export_group("Economy")
## A coin is awarded each time the score passes a multiple of this.
@export var points_per_coin: int = 50

@export_group("Ability costs")
## Fruit Slot: stash the current fruit, release it later for free.
@export var slot_cost: int = 5
## Fruit Swap: reroll the next fruit into a different one.
@export var swap_cost: int = 10
## Shake Up: cover the jar and flip it around its center.
@export var shake_cost: int = 25

@export_group("Shake Up")
## Seconds for the cover to slide over the top of the jar (and back off).
@export var shake_cover_time: float = 0.4
## Jar scale while spinning, so the whole jar stays on the left of the screen. 1.0 disables the zoom.
@export_range(0.3, 1.0) var shake_zoom: float = 0.6
@export var shake_zoom_time: float = 0.3
## The jar turns a full 360° split into this many equal turns (4 = 90° each).
@export_range(1, 12) var shake_flips: int = 4
## Seconds per turn.
@export var shake_flip_time: float = 0.7
## After each turn, wait until the average fruit speed drops below this (pixels/s)...
@export var shake_settle_speed: float = 50.0
## ...but always wait at least this long...
@export var shake_settle_min: float = 0.25
## ...and never longer than this, in case something keeps rolling.
@export var shake_settle_max: float = 1.5
## Gravity multiplier while shaking, so fruit settles quickly after each turn.
@export var shake_gravity_scale: float = 2.5
## Extra fruit damping while shaking. Circles don't have rolling resistance, so without this
## fruit keeps rolling and every settle runs to shake_settle_max.
@export var shake_linear_damp: float = 1.5
@export var shake_angular_damp: float = 4.0
## Extra no-drop time once the jar is back and open.
@export var shake_extra_pause: float = 0.5
