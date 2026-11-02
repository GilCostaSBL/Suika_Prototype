class_name ShakeUp
extends Node2D

## The "Shake Up" ultimate: a cover slides over the jar, then the jar flips around its center.
## The jar never moves physically. The view rotates (the viewport's canvas transform) and
## gravity rotates to match, so fruit can't tunnel through fast-moving walls.

signal finished

var active: bool = false

var _balance: Balance
var _jar: Rect2
var _wall: float
var _color: Color
var _fruits: Node
var _cover_shape: CollisionShape2D
var _default_gravity: Vector2
var _default_gravity_strength: float

# Tweened values: view rotation (radians), view scale, and cover progress (0 open, 1 closed).
var _angle: float = 0.0
var _zoom: float = 1.0
var _cover: float = 0.0


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
	_set_fruits_awake(true)
	var b := _balance
	_set_gravity_strength(_default_gravity_strength * b.shake_gravity_scale)
	var t := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	t.tween_property(self, "_cover", 1.0, b.shake_cover_time)
	t.tween_callback(_set_cover_solid.bind(true))
	t.tween_property(self, "_zoom", b.shake_zoom, b.shake_zoom_time)
	var total := 0.0
	for i in b.shake_flips:
		total += deg_to_rad(b.shake_flip_degrees)
		t.tween_property(self, "_angle", total, b.shake_flip_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_interval(b.shake_flip_pause)
	# Always land upright, even if the flip settings don't add up to whole turns.
	var leftover := fposmod(total, TAU)
	if leftover > 0.001:
		t.tween_property(self, "_angle", total + TAU - leftover, b.shake_flip_time).set_trans(Tween.TRANS_SINE)
		t.tween_interval(b.shake_flip_pause)
	t.tween_property(self, "_zoom", 1.0, b.shake_zoom_time)
	t.tween_callback(_set_cover_solid.bind(false))
	t.tween_property(self, "_cover", 0.0, b.shake_cover_time)
	t.tween_interval(b.shake_extra_pause)
	t.tween_callback(_finish)


func _physics_process(_delta: float) -> void:
	if not active:
		return
	var center := _jar.get_center()
	var view := Transform2D(_angle, Vector2(_zoom, _zoom), 0.0, Vector2.ZERO)
	view.origin = center - view.basis_xform(center)
	get_viewport().canvas_transform = view
	# The view shows the world rotated by _angle, so rotate gravity back to keep "down" on screen.
	_set_gravity(_default_gravity.rotated(-_angle))
	queue_redraw()


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
			fruit.can_sleep = not awake
			if awake:
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
