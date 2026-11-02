class_name AbilityPanel
extends PanelContainer

## Right-hand panel: coin balance and one button per ability. Emits presses; the game decides.

signal ability_pressed(id: int)

const NAMES := ["Fruit Slot", "Fruit Swap", "Shake Up"]
const TEXT_COLOR := Color(0.3, 0.2, 0.12)
const BUTTON_COLOR := Color(0.55, 0.38, 0.25)

@onready var coins_label: Label = $Layout/CoinsLabel
@onready var buttons_box: VBoxContainer = $Layout/AbilityButtons

var _buttons: Array[Button] = []
var _held_icon: FruitIcon


func _ready() -> void:
	for id in NAMES.size():
		var button := _make_button(id)
		_buttons.append(button)
		if id == 0:
			# The Fruit Slot shows its stored fruit next to the button.
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(button)
			_held_icon = FruitIcon.new()
			_held_icon.custom_minimum_size = Vector2(100, 100)
			row.add_child(_held_icon)
			buttons_box.add_child(row)
		else:
			buttons_box.add_child(button)


func _make_button(id: int) -> Button:
	var button := Button.new()
	# Never take keyboard focus, or Space/arrows would drive the button instead of the game.
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 100)
	# Long labels must never resize the panel.
	button.clip_text = true
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.7))
	button.add_theme_stylebox_override("normal", _style(BUTTON_COLOR))
	button.add_theme_stylebox_override("hover", _style(BUTTON_COLOR.lightened(0.15)))
	button.add_theme_stylebox_override("pressed", _style(BUTTON_COLOR.darkened(0.2)))
	button.add_theme_stylebox_override("disabled", _style(Color(BUTTON_COLOR, 0.35)))
	button.pressed.connect(ability_pressed.emit.bind(id))
	return button


func _style(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(12)
	box.set_content_margin_all(12)
	return box


## locked: no ability can be used right now (game over or Shake Up running).
func refresh(coins: int, next_coin_at: int, costs: Array[int], held_tier: int, locked: bool) -> void:
	if not is_node_ready():
		await ready
	coins_label.text = "Coins: %d\nnext coin at %d pts" % [coins, next_coin_at]
	for id in _buttons.size():
		var button := _buttons[id]
		var key := "[%d] " % (id + 1)
		if id == 0 and held_tier >= 0:
			button.text = "%sRelease\n%s" % [key, FruitData.name_of(held_tier)]
			button.disabled = locked
		else:
			button.text = "%s%s\n%d coins" % [key, NAMES[id], costs[id]]
			button.disabled = locked or coins < costs[id]
	_held_icon.tier = held_tier
