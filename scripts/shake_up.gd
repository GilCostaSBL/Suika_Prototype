class_name ShakeUp
extends Node2D

## The "Shake Up" ultimate: a cover slides over the jar, then the jar turns 360° around its
## center in equal steps, waiting for the fruit to settle after each one.
## The jar never moves physically. The view rotates (the viewport's canvas transform) and
## gravity rotates to match, so fruit can't tunnel through fast-moving walls.
##
## The sequence is a list of steps run from _physics_process rather than a Tween, because
## "wait until the fruit settles" has no fixed length.

signal finished

var active: bool = false
## Turns completed (including settling) in the current shake. Used by tests.
var flips_done: int = 0

var _balance: Balance
var _jar: Rect2
var _wall: float
var _color: Color
var _fruits: Node
var _cover_shape: CollisionShape2D
var _default_gravity: Vector2
var _default_gravity_strength: float

# Animated values: view rotation (radians), view scale, and cover progress (0 open, 1 closed).
var _angle: float = 0.0
var _zoom: float = 1.0
var _cover: float = 0.0

# Pending steps. Each is one of:
#   {"prop": name, "to": value, "time": seconds}  animate a property with ease in/out
#   {"settle": true}                              wait for the fruit to stop moving
#   {"wait": seconds}                             plain pause
#   {"call": callable}                            run once, instantly
var _steps: Array[Dictionary] = []
var _step_time: float = 0.0
var _step_from: float = 0.0


func setup(balance: Balance, jar: Rect2, wall: float, color: Color, fruits: Node) -> void:
	_balance = balance
	_jar = jar
	_wall = wall
	_color = color.darkened(0.2)
	_fruits = fruits
	_default_gravity = ProjectSettings.get_setting("physics/2d/default_gravity_vector")
	_default_gravity_strength = ProjectSettings.get_setting("physics/2d/default_gravity")

	var body := StaticBody2D.new()
	add_child(body)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(jar.size.x + wall * 2.0, wall)
	_cover_shape = CollisionShape2D.new()
	_cover_shape.shape = shape
	_cover_shape.position = Vector2(jar.get_center().x, jar.position.y - wall / 2.0)
	_cover_shape.disabled = true
	body.add_child(_cover_shape)
	_reset_world()


func _exit_tree() -> void:
	# The viewport and physics space outlive this scene (e.g. restart mid-shake), so undo our changes.
	_reset_world()


func start() -> void:
	if active:
		return
	active = true
	flips_done = 0
	_set_fruits_awake(true)
	var b := _balance
	_set_gravity_strength(_default_gravity_strength * b.shake_gravity_scale)
	_steps.clear()
	_steps.append({"prop": "_cover", "to": 1.0, "time": b.shake_cover_time})
	_steps.append({"call": _set_cover_solid.bind(true)})
	_steps.append({"prop": "_zoom", "to": b.shake_zoom, "time": b.shake_zoom_time})
	for i in b.shake_flips:
		_steps.append({"prop": "_angle", "to": TAU * (i + 1) / b.shake_flips, "time": b.shake_flip_time})
		_steps.append({"settle": true})
	_steps.append({"prop": "_zoom", "to": 1.0, "time": b.shake_zoom_time})
	_steps.append({"call": _set_cover_solid.bind(false)})
	_steps.append({"prop": "_cover", "to": 0.0, "time": b.shake_cover_time})
	_steps.append({"wait": b.shake_extra_pause})
	_begin_step()


func _physics_process(delta: float) -> void:
	if not active:
		return
	_advance_steps(delta)
	if active:
		_apply_view()
	queue_redraw()


func _begin_step() -> void:
	_step_time = 0.0
	if not _steps.is_empty() and _steps[0].has("prop"):
		_step_from = get(_steps[0]["prop"])


func _advance_steps(delta: float) -> void:
	while not _steps.is_empty():
		var step: Dictionary = _steps[0]
		_step_time += delta
		# Only the first step this frame consumes time; follow-up steps start fresh.
		delta = 0.0
		if step.has("prop"):
			var weight := 1.0 if step["time"] <= 0.0 else clampf(_step_time / step["time"], 0.0, 1.0)
			set(step["prop"], lerpf(_step_from, step["to"], smoothstep(0.0, 1.0, weight)))
			if weight < 1.0:
				return
		elif step.has("settle"):
			var settled := _step_time >= _balance.shake_settle_min and _fruits_settled()
			if not settled and _step_time < _balance.shake_settle_max:
				return
			flips_done += 1
		elif step.has("wait"):
			if _step_time < step["wait"]:
				return
		elif step.has("call"):
			(step["call"] as Callable).call()
		_steps.pop_front()
		_begin_step()
	_finish()


## Uses the average speed, so one fruit still bouncing (e.g. fresh from a merge) doesn't stall the turn.
func _fruits_settled() -> bool:
	var total := 0.0
	var count := 0
	for child in _fruits.get_children():
		var fruit := child as RigidBody2D
		if fruit:
			total += fruit.linear_velocity.length()
			count += 1
	return count == 0 or total / count <= _balance.shake_settle_speed


func _apply_view() -> void:
	var center := _jar.get_center()
	var view := Transform2D(_angle, Vector2(_zoom, _zoom), 0.0, Vector2.ZERO)
	view.origin = center - view.basis_xform(center)
	get_viewport().canvas_transform = view
	# The view shows the world rotated by _angle, so rotate gravity back to keep "down" on screen.
	_set_gravity(_default_gravity.rotated(-_angle))


func _finish() -> void:
	active = false
	_angle = 0.0
	_zoom = 1.0
	_reset_world()
	_set_fruits_awake(false)
	queue_redraw()
	finished.emit()


func _set_cover_solid(solid: bool) -> void:
	_cover_shape.disabled = not solid


func _set_fruits_awake(awake: bool) -> void:
	for child in _fruits.get_children():
		var fruit := child as RigidBody2D
		if fruit:
			prepare_fruit(fruit)


## Puts a fruit in the right state for the current shake. Call it for fruit spawned mid-shake too.
func prepare_fruit(fruit: RigidBody2D) -> void:
	# Fruit must not fall asleep while gravity is rotating.
	fruit.can_sleep = not active
	fruit.linear_damp = _balance.shake_linear_damp if active else 0.0
	fruit.angular_damp = _balance.shake_angular_damp if active else 0.0
	if active:
		fruit.sleeping = false


func _set_gravity(direction: Vector2) -> void:
	PhysicsServer2D.area_set_param(get_world_2d().space, PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR, direction)


func _set_gravity_strength(strength: float) -> void:
	PhysicsServer2D.area_set_param(get_world_2d().space, PhysicsServer2D.AREA_PARAM_GRAVITY, strength)


func _reset_world() -> void:
	if _balance == null or not is_inside_tree():
		return
	get_viewport().canvas_transform = Transform2D.IDENTITY
	_set_gravity(_default_gravity)
	_set_gravity_strength(_default_gravity_strength)


func _draw() -> void:
	if _cover <= 0.0:
		return
	# The cover slides in from the right edge of the jar.
	var width := _jar.size.x + _wall * 2.0
	var left := _jar.position.x - _wall
	var rect := Rect2(left + (1.0 - _cover) * width, _jar.position.y - _wall, _cover * width, _wall)
	draw_rect(rect, _color)
	draw_rect(rect, _color.darkened(0.3), false, 3.0)
