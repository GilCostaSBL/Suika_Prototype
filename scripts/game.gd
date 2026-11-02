extends Node2D

## Core Suika loop: drop, merge, score, game over.

const JAR_LEFT := 60.0
const JAR_RIGHT := 660.0
const JAR_TOP := 300.0
const JAR_BOTTOM := 1200.0
const WALL_THICKNESS := 40.0
const DANGER_Y := 380.0
const DROP_Y := 250.0
const DROP_COOLDOWN := 0.5
## New fruits get this long before they can trigger game over.
const SETTLE_TIME := 1.0
## How long a fruit must stay above the danger line to end the game.
const GAME_OVER_TIME := 2.0
const NEXT_PREVIEW_POS := Vector2(620.0, 125.0)
## Dropper speed when moved with the keyboard, in pixels per second.
const KEY_MOVE_SPEED := 700.0

const JAR_COLOR := Color(0.55, 0.38, 0.25)
const JAR_INSIDE_COLOR := Color(1.0, 0.97, 0.9)
const DANGER_COLOR := Color(0.85, 0.15, 0.15)

@onready var fruits: Node2D = $Fruits
@onready var score_label: Label = $UI/ScoreLabel
@onready var game_over_label: Label = $UI/GameOverLabel

var score: int = 0
var current_tier: int = 0
var next_tier: int = 0
var drop_x: float = (JAR_LEFT + JAR_RIGHT) / 2.0
var cooldown: float = 0.0
var danger_timer: float = 0.0
var is_over: bool = false
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	_build_jar()
	current_tier = _roll_tier()
	next_tier = _roll_tier()
	_update_ui()


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		_restart()
		return
	if is_over:
		if Input.is_action_just_pressed("drop"):
			_restart()
		return
	cooldown = maxf(cooldown - delta, 0.0)
	_handle_keyboard(delta)
	_check_merges()
	_check_danger(delta)
	queue_redraw()


func _handle_keyboard(delta: float) -> void:
	var axis := Input.get_axis("move_left", "move_right")
	if axis != 0.0:
		# Start from the clamped position so there's no dead zone after hitting a wall.
		drop_x = clampf(_clamped_drop_x(current_tier) + axis * KEY_MOVE_SPEED * delta, JAR_LEFT, JAR_RIGHT)
	if Input.is_action_just_pressed("drop"):
		_drop()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		drop_x = get_global_mouse_position().x
	var mouse := event as InputEventMouseButton
	if mouse and mouse.button_index == MOUSE_BUTTON_LEFT and not mouse.pressed:
		if is_over:
			_restart()
		else:
			_drop()


func _build_jar() -> void:
	var body := StaticBody2D.new()
	add_child(body)
	# Side walls run to the top of the screen so fruit can't bounce out.
	var side_height := JAR_BOTTOM
	_add_wall(body, Vector2(JAR_LEFT - WALL_THICKNESS / 2.0, side_height / 2.0), Vector2(WALL_THICKNESS, side_height))
	_add_wall(body, Vector2(JAR_RIGHT + WALL_THICKNESS / 2.0, side_height / 2.0), Vector2(WALL_THICKNESS, side_height))
	var floor_width := JAR_RIGHT - JAR_LEFT + WALL_THICKNESS * 2.0
	_add_wall(body, Vector2((JAR_LEFT + JAR_RIGHT) / 2.0, JAR_BOTTOM + WALL_THICKNESS / 2.0), Vector2(floor_width, WALL_THICKNESS))


func _add_wall(body: StaticBody2D, center: Vector2, size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = center
	body.add_child(collision)


func _roll_tier() -> int:
	return rng.randi_range(0, FruitData.SPAWN_TIER_MAX)


func _drop() -> void:
	if cooldown > 0.0:
		return
	_spawn_fruit(current_tier, Vector2(_clamped_drop_x(current_tier), DROP_Y))
	current_tier = next_tier
	next_tier = _roll_tier()
	cooldown = DROP_COOLDOWN


func _clamped_drop_x(tier: int) -> float:
	var r := FruitData.radius(tier)
	return clampf(drop_x, JAR_LEFT + r, JAR_RIGHT - r)


func _spawn_fruit(tier: int, pos: Vector2) -> Fruit:
	var fruit := Fruit.new()
	fruit.tier = tier
	fruit.position = pos
	fruits.add_child(fruit)
	return fruit


func _check_merges() -> void:
	for child in fruits.get_children():
		var fruit := child as Fruit
		if fruit == null or fruit.merging:
			continue
		for body in fruit.get_colliding_bodies():
			var other := body as Fruit
			if other and not other.merging and other.tier == fruit.tier:
				_merge(fruit, other)
				break


func _merge(a: Fruit, b: Fruit) -> void:
	a.merging = true
	b.merging = true
	var tier := a.tier
	var pos := (a.global_position + b.global_position) / 2.0
	score += FruitData.merge_score(tier)
	a.queue_free()
	b.queue_free()
	# Two watermelons simply vanish.
	if tier + 1 < FruitData.count():
		_spawn_fruit.call_deferred(tier + 1, pos)
	_update_ui()


func _check_danger(delta: float) -> void:
	var above := false
	for child in fruits.get_children():
		var fruit := child as Fruit
		if fruit and not fruit.merging and fruit.age > SETTLE_TIME and fruit.top_y() < DANGER_Y:
			above = true
			break
	danger_timer = danger_timer + delta if above else 0.0
	if danger_timer >= GAME_OVER_TIME:
		_game_over()


func _game_over() -> void:
	is_over = true
	for child in fruits.get_children():
		var fruit := child as Fruit
		if fruit:
			fruit.freeze = true
	game_over_label.visible = true
	queue_redraw()


func _restart() -> void:
	get_tree().reload_current_scene()


func _update_ui() -> void:
	score_label.text = "Score: %d" % score


func _draw() -> void:
	draw_rect(Rect2(JAR_LEFT, JAR_TOP, JAR_RIGHT - JAR_LEFT, JAR_BOTTOM - JAR_TOP), JAR_INSIDE_COLOR)
	draw_rect(Rect2(JAR_LEFT - WALL_THICKNESS, JAR_TOP, WALL_THICKNESS, JAR_BOTTOM - JAR_TOP + WALL_THICKNESS), JAR_COLOR)
	draw_rect(Rect2(JAR_RIGHT, JAR_TOP, WALL_THICKNESS, JAR_BOTTOM - JAR_TOP + WALL_THICKNESS), JAR_COLOR)
	draw_rect(Rect2(JAR_LEFT, JAR_BOTTOM, JAR_RIGHT - JAR_LEFT, WALL_THICKNESS), JAR_COLOR)

	# The danger line pulses brighter the closer the game is to ending.
	var danger := DANGER_COLOR
	danger.a = 0.35 + 0.65 * clampf(danger_timer / GAME_OVER_TIME, 0.0, 1.0)
	draw_dashed_line(Vector2(JAR_LEFT, DANGER_Y), Vector2(JAR_RIGHT, DANGER_Y), danger, 3.0, 14.0)

	Fruit.draw_fruit(self, NEXT_PREVIEW_POS, next_tier)

	if is_over:
		return
	var x := _clamped_drop_x(current_tier)
	draw_line(Vector2(x, DROP_Y), Vector2(x, JAR_BOTTOM), Color(0, 0, 0, 0.12), 2.0)
	var alpha := 1.0 if cooldown <= 0.0 else 0.4
	Fruit.draw_fruit(self, Vector2(x, DROP_Y), current_tier, alpha)
