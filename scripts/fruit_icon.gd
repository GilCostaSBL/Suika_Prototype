class_name FruitIcon
extends Control

## Draws a fruit (scaled to fit) inside a slot box. tier = -1 shows an empty slot.

var tier: int = -1:
	set(value):
		tier = value
		queue_redraw()


func _draw() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.55, 0.38, 0.25, 0.12)
	box.border_color = Color(0.55, 0.38, 0.25, 0.6)
	box.set_border_width_all(3)
	box.set_corner_radius_all(12)
	draw_style_box(box, Rect2(Vector2.ZERO, size))
	if tier < 0:
		return
	var fit := (minf(size.x, size.y) / 2.0 - 8.0) / FruitData.radius(tier)
	draw_set_transform(size / 2.0, 0.0, Vector2.ONE * minf(fit, 1.0))
	Fruit.draw_fruit(self, Vector2.ZERO, tier)
