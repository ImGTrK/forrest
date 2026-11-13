class_name Bench
extends StaticBody2D
## Mesa de crafting del pueblo. Al interactuar emite `used`; Main abre la CraftingUI.

signal used

const SIZE := Vector2(32, 16)  # 2x1 tiles
const TEXTURE := preload("res://assets/sprites/world/bench.png")  # 32x16

var _focused := false


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = SIZE - Vector2(2, 2)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = SIZE / 2.0
	add_child(col)
	var sprite := Sprite2D.new()
	sprite.texture = TEXTURE
	sprite.centered = false
	add_child(sprite)
	add_to_group("interactable")


func get_interact_rect() -> Rect2:
	return Rect2(global_position, SIZE)


func set_focused(value: bool) -> void:
	_focused = value
	queue_redraw()


func interact(_by: Node) -> void:
	used.emit()


func _draw() -> void:
	if _focused:
		draw_rect(Rect2(Vector2.ZERO, SIZE).grow(1), Color.WHITE, false, 1.0)
