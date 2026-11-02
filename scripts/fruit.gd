class_name Fruit
extends RigidBody2D

## A single physics fruit. The game script detects merges via get_colliding_bodies().

var tier: int = 0
## Set by the game from the balance config before the fruit enters the tree.
var bounce: float = 0.05
## Set once this fruit is consumed by a merge, so it can't merge twice.
var merging: bool = false
## Seconds since spawn; young fruits don't count toward game over.
var age: float = 0.0


func _ready() -> void:
	var r := FruitData.radius(tier)
	var shape := CircleShape2D.new()
	shape.radius = r
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

	mass = r * r / 400.0
	var material := PhysicsMaterial.new()
	material.friction = 0.4
	material.bounce = bounce
	physics_material_override = material
	# Shake Up boosts gravity; continuous collision keeps fast small fruit from tunnelling.
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	contact_monitor = true
	max_contacts_reported = 8


func _physics_process(delta: float) -> void:
	age += delta


func top_y() -> float:
	return global_position.y - FruitData.radius(tier)


func _draw() -> void:
	Fruit.draw_fruit(self, Vector2.ZERO, tier)


## Shared drawing so the dropper and next-preview match the physics fruit.
static func draw_fruit(canvas: CanvasItem, pos: Vector2, fruit_tier: int, alpha: float = 1.0) -> void:
	var r := FruitData.radius(fruit_tier)
	var c := FruitData.color(fruit_tier)
	c.a = alpha
	canvas.draw_circle(pos, r, c)
	var outline := c.darkened(0.35)
	canvas.draw_arc(pos, r - 1.5, 0.0, TAU, 48, outline, 3.0, true)
	var shine := c.lightened(0.45)
	canvas.draw_circle(pos + Vector2(-r, -r) * 0.35, r * 0.18, shine)
