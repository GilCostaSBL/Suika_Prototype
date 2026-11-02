class_name FruitData
extends RefCounted

## Tier table for the 11 Suika fruits, smallest to largest.

## Only tiers 0..SPAWN_TIER_MAX can be dropped by the player.
const SPAWN_TIER_MAX := 4

const TIERS := [
	{"name": "Cherry", "radius": 22.0, "color": Color(0.86, 0.12, 0.24)},
	{"name": "Strawberry", "radius": 30.0, "color": Color(0.98, 0.33, 0.33)},
	{"name": "Grape", "radius": 40.0, "color": Color(0.58, 0.35, 0.85)},
	{"name": "Dekopon", "radius": 48.0, "color": Color(1.0, 0.68, 0.16)},
	{"name": "Persimmon", "radius": 60.0, "color": Color(0.95, 0.47, 0.13)},
	{"name": "Apple", "radius": 74.0, "color": Color(0.9, 0.2, 0.18)},
	{"name": "Pear", "radius": 86.0, "color": Color(0.93, 0.88, 0.45)},
	{"name": "Peach", "radius": 100.0, "color": Color(1.0, 0.72, 0.75)},
	{"name": "Pineapple", "radius": 114.0, "color": Color(0.98, 0.85, 0.2)},
	{"name": "Melon", "radius": 134.0, "color": Color(0.6, 0.85, 0.35)},
	{"name": "Watermelon", "radius": 160.0, "color": Color(0.2, 0.6, 0.25)},
]


static func count() -> int:
	return TIERS.size()


static func radius(tier: int) -> float:
	return TIERS[tier]["radius"]


static func color(tier: int) -> Color:
	return TIERS[tier]["color"]


static func name_of(tier: int) -> String:
	return TIERS[tier]["name"]


## Score for merging two fruits of this tier: triangular numbers 1, 3, 6, 10, ...
static func merge_score(tier: int) -> int:
	@warning_ignore("integer_division")
	return (tier + 1) * (tier + 2) / 2
