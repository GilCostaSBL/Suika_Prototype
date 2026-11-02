extends Node2D

## Core Suika loop: drop, merge, score, game over, plus the per-run coin economy and abilities.

enum Ability { SLOT, SWAP, SHAKE }

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

@export var balance: Balance = preload("res://config/balance.tres")

@onready var fruits: Node2D = $Fruits
@onready var shake_up: ShakeUp = $ShakeUp
@onready var score_label: Label = $UI/ScoreLabel
@onready var game_over_label: Label = $UI/GameOverLabel
@onready var ability_panel: AbilityPanel = $UI/AbilityPanel

var score: int = 0
var coins: int = 0
## Total coins handed out this run, so each score milestone pays exactly once.
var coins_awarded: int = 0
## Tier stored by the Fruit Slot, or -1 when the slot is empty.
var held_tier: int = -1
## Upcoming fruits: [0] is in the dropper, [1] is the "Next" preview.
var queue: Array[int] = []
var drop_x: float = (JAR_LEFT + JAR_RIGHT) / 2.0
var cooldown: float = 0.0
var danger_timer: float = 0.0
var is_over: bool = false
var rng := RandomNumberGenerator.new()

var current_tier: int:
	get:
		return queue[0]
var next_tier: int:
	get:
		return queue[1]


func _ready() -> void:
	rng.randomize()
	_build_jar()
	_fill_queue()
	shake_up.setup(balance, Rect2(JAR_LEFT, JAR_TOP, JAR_RIGHT - JAR_LEFT, JAR_BOTTOM - JAR_TOP), WALL_THICKNESS, JAR_COLOR, fruits)
	shake_up.finished.connect(_on_shake_finished)
	ability_panel.ability_pressed.connect(activate_ability)
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
	_check_merges()
	if not shake_up.active:
		_handle_keyboard(delta)
		_check_danger(delta)
	queue_redraw()


func _handle_keyboard(delta: float) -> void:
	var axis := Input.get_axis("move_left", "move_right")
	if axis != 0.0:
		# Start from the clamped position so there's no dead zone after hitting a wall.
		drop_x = clampf(_clamped_drop_x(current_tier) + axis * KEY_MOVE_SPEED * delta, JAR_LEFT, JAR_RIGHT)
	if Input.is_action_just_pressed("drop"):
		_drop()
	for id in Ability.values():
		if Input.is_action_just_pressed("ability_%d" % (id + 1)):
			activate_ability(id)


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


func _fill_queue() -> void:
	while queue.size() < 2:
		queue.append(_roll_tier())


func _advance_queue() -> void:
	queue.pop_front()
	_fill_queue()


func _drop() -> void:
	if cooldown > 0.0 or shake_up.active:
		return
	_spawn_fruit(current_tier, Vector2(_clamped_drop_x(current_tier), DROP_Y))
	_advance_queue()
	cooldown = DROP_COOLDOWN
	_update_ui()


func _clamped_drop_x(tier: int) -> float:
	var r := FruitData.radius(tier)
	return clampf(drop_x, JAR_LEFT + r, JAR_RIGHT - r)


func _spawn_fruit(tier: int, pos: Vector2) -> Fruit:
	var fruit := Fruit.new()
	fruit.tier = tier
	fruit.position = pos
	# Fruit born mid-shake must not fall asleep while gravity is rotating.
	fruit.can_sleep = not shake_up.active
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
	a.queue_free()
	b.queue_free()
	# Two watermelons simply vanish.
	if tier + 1 < FruitData.count():
		_spawn_fruit.call_deferred(tier + 1, pos)
	_add_score(FruitData.merge_score(tier))


func _add_score(points: int) -> void:
	score += points
	@warning_ignore("integer_division")
	var earned := score / balance.points_per_coin
	if earned > coins_awarded:
		coins += earned - coins_awarded
		coins_awarded = earned
	_update_ui()


func ability_cost(id: int) -> int:
	match id:
		Ability.SLOT:
			return balance.slot_cost
		Ability.SWAP:
			return balance.swap_cost
		_:
			return balance.shake_cost


## Returns true if the ability fired. Abilities are paid per use and reset with the run.
func activate_ability(id: int) -> bool:
	if is_over or shake_up.active:
		return false
	if id == Ability.SLOT and held_tier >= 0:
		# Releasing the stored fruit is free: it goes back into the dropper.
		queue.push_front(held_tier)
		held_tier = -1
		_update_ui()
		return true
	if coins < ability_cost(id):
		return false
	coins -= ability_cost(id)
	match id:
		Ability.SLOT:
			held_tier = current_tier
			_advance_queue()
		Ability.SWAP:
			queue[1] = _roll_tier_except(queue[1])
		Ability.SHAKE:
			shake_up.start()
	_update_ui()
	return true


func _roll_tier_except(tier: int) -> int:
	var roll := rng.randi_range(0, FruitData.SPAWN_TIER_MAX - 1)
	return roll + 1 if roll >= tier else roll


func _on_shake_finished() -> void:
	# Everything just got tossed around: give all fruit a fresh settle grace.
	for child in fruits.get_children():
		var fruit := child as Fruit
		if fruit:
			fruit.age = 0.0
	danger_timer = 0.0
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
	_update_ui()
	queue_redraw()


func _restart() -> void:
	get_tree().reload_current_scene()


func _update_ui() -> void:
	score_label.text = "Score: %d" % score
	var costs: Array[int] = []
	for id in Ability.values():
		costs.append(ability_cost(id))
	var next_coin_at := (coins_awarded + 1) * balance.points_per_coin
	ability_panel.refresh(coins, next_coin_at, costs, held_tier, is_over or shake_up.active)


func _draw() -> void:
	draw_rect(Rect2(JAR_LEFT, JAR_TOP, JAR_RIGHT - JAR_LEFT, JAR_BOTTOM - JAR_TOP), JAR_INSIDE_COLOR)
	draw_rect(Rect2(JAR_LEFT - WALL_THICKNESS, JAR_TOP, WALL_THICKNESS, JAR_BOTTOM - JAR_TOP + WALL_THICKNESS), JAR_COLOR)
	draw_rect(Rect2(JAR_RIGHT, JAR_TOP, WALL_THICKNESS, JAR_BOTTOM - JAR_TOP + WALL_THICKNESS), JAR_COLOR)
	draw_rect(Rect2(JAR_LEFT, JAR_BOTTOM, JAR_RIGHT - JAR_LEFT, WALL_THICKNESS), JAR_COLOR)

	# The danger line pulses brighter the closer the game is to ending.
	var danger := DANGER_COLOR
	danger.a = 0.35 + 0.65 * clampf(danger_timer / GAME_OVER_TIME, 0.0, 1.0)
	draw_dashed_line(Vector2(JAR_LEFT, DANGER_Y), Vector2(JAR_RIGHT, DANGER_Y), danger, 3.0, 14.0)

	# The dropper and preview live outside the jar, so hide them while the view spins.
	if is_over or shake_up.active:
		return
	Fruit.draw_fruit(self, NEXT_PREVIEW_POS, next_tier)
	var x := _clamped_drop_x(current_tier)
	draw_line(Vector2(x, DROP_Y), Vector2(x, JAR_BOTTOM), Color(0, 0, 0, 0.12), 2.0)
	var alpha := 1.0 if cooldown <= 0.0 else 0.4
	Fruit.draw_fruit(self, Vector2(x, DROP_Y), current_tier, alpha)
