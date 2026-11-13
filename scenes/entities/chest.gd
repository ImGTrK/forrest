class_name Chest
extends StaticBody2D
## Almacén del hub. Al interactuar emite `opened`; Main abre la UI del almacén.

signal opened

const SIZE := Vector2(16, 16)

var _focused := false


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = SIZE - Vector2(2, 2)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = SIZE / 2.0
	add_child(col)
	add_to_group("interactable")


func get_interact_rect() -> Rect2:
	return Rect2(global_position, SIZE)


func set_focused(value: bool) -> void:
	_focused = value
	queue_redraw()


func interact(_by: Node) -> void:
	opened.emit()


func _draw() -> void:
	var r := Rect2(Vector2(1, 3), SIZE - Vector2(2, 4))
	draw_rect(r, Color("6b4423"))
	draw_rect(Rect2(1, 7, SIZE.x - 2, 2), Color("d4a640"))
	if _focused:
		draw_rect(r.grow(1), Color.WHITE, false, 1.0)
