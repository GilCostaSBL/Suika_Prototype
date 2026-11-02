class_name HelpOverlay
extends CanvasLayer

## The round "?" button and the How to Play screen. Opening the screen pauses the game.
## This layer keeps processing while paused (PROCESS_MODE_ALWAYS) so its buttons and keys still work.

const TEXT_COLOR := Color(0.3, 0.2, 0.12)
const BROWN := Color(0.55, 0.38, 0.25)
const CREAM := Color(1.0, 0.97, 0.9)
const FRUIT_COLUMNS := 6

@export var balance: Balance = preload("res://config/balance.tres")

var help_button: Button
var screen: Control
var fruit_grid: GridContainer


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_button()
	_build_screen()
	screen.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("help"):
		toggle()
		get_viewport().set_input_as_handled()
	elif is_open() and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func is_open() -> bool:
	return screen.visible


func toggle() -> void:
	if is_open():
		close()
	else:
		open()


func open() -> void:
	screen.visible = true
	get_tree().paused = true


func close() -> void:
	screen.visible = false
	get_tree().paused = false


func _build_button() -> void:
	help_button = Button.new()
	help_button.text = "?"
	help_button.tooltip_text = "How to play (H)"
	# Never take keyboard focus, or Space would press it instead of dropping fruit.
	help_button.focus_mode = Control.FOCUS_NONE
	help_button.position = Vector2(1088, 28)
	help_button.custom_minimum_size = Vector2(72, 72)
	help_button.size = help_button.custom_minimum_size
	help_button.add_theme_font_size_override("font_size", 44)
	_style_button(help_button, 36)
	help_button.pressed.connect(toggle)
	add_child(help_button)


func _build_screen() -> void:
	screen = Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(screen)

	# The dim backdrop also swallows clicks so nothing underneath reacts.
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	screen.add_child(dim)

	var panel := PanelContainer.new()
	panel.position = Vector2(120, 40)
	panel.custom_minimum_size = Vector2(960, 1200)
	panel.size = panel.custom_minimum_size
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = CREAM
	panel_style.border_color = BROWN
	panel_style.set_border_width_all(6)
	panel_style.set_corner_radius_all(16)
	panel_style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", panel_style)
	screen.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 20)
	panel.add_child(layout)

	var title := _label("How to Play", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	_fill_content(content)

	var back := Button.new()
	back.text = "Back"
	back.focus_mode = Control.FOCUS_NONE
	back.custom_minimum_size = Vector2(260, 72)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.add_theme_font_size_override("font_size", 32)
	_style_button(back, 14)
	back.pressed.connect(close)
	layout.add_child(back)


func _fill_content(content: VBoxContainer) -> void:
	content.add_child(_label("Objective", 30))
	content.add_child(_paragraph(
		"Drop fruit into the jar. Two identical fruits that touch merge into the next bigger one and score points. "
		+ "Two Watermelons merging vanish for a big bonus. "
		+ "Game over if fruit stays above the red dashed line for 2 seconds."))

	content.add_child(_label("Controls", 30))
	content.add_child(_paragraph(
		"Move:  ← → / A D / mouse          Drop:  Space / ↓ / S / click\n"
		+ "Abilities:  1 2 3 / buttons          Restart:  R          Help:  H (Esc closes)"))

	content.add_child(_label("Coins and abilities", 30))
	content.add_child(_paragraph(
		"Earn 1 coin every %d points; each ability use costs coins. Everything resets each game.\n" % balance.points_per_coin
		+ "•  Fruit Slot (%d): stash the current fruit, release it later for free.\n" % balance.slot_cost
		+ "•  Fruit Swap (%d): reroll the next fruit.\n" % balance.swap_cost
		+ "•  Shake Up (%d): cover the jar and spin it around to shuffle the fruit." % balance.shake_cost))

	content.add_child(_label("Fruits, smallest to largest", 30))
	content.add_child(_paragraph("Only the first %d can come out of the dropper." % (FruitData.SPAWN_TIER_MAX + 1)))
	fruit_grid = GridContainer.new()
	fruit_grid.columns = FRUIT_COLUMNS
	fruit_grid.add_theme_constant_override("h_separation", 8)
	fruit_grid.add_theme_constant_override("v_separation", 8)
	content.add_child(fruit_grid)
	for tier in FruitData.count():
		fruit_grid.add_child(_fruit_cell(tier))


func _fruit_cell(tier: int) -> Control:
	var cell := VBoxContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_theme_constant_override("separation", 2)
	var icon := FruitIcon.new()
	icon.show_box = false
	icon.tier = tier
	icon.custom_minimum_size = Vector2(0, 64)
	cell.add_child(icon)
	var name_label := _label("%d. %s" % [tier + 1, FruitData.name_of(tier)], 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.add_child(name_label)
	return cell


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	return label


func _paragraph(text: String) -> Label:
	var label := _label(text, 24)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(TEXT_COLOR, 0.9))
	return label


func _style_button(button: Button, radius: int) -> void:
	for state in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = BROWN
		if state == "hover":
			box.bg_color = BROWN.lightened(0.15)
		elif state == "pressed":
			box.bg_color = BROWN.darkened(0.2)
		box.set_corner_radius_all(radius)
		button.add_theme_stylebox_override(state, box)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(color_name, Color.WHITE)
