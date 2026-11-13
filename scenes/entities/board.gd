class_name Board
extends StaticBody2D
## Tablón de misiones del pueblo (GDD §6, sin NPC). Al interactuar emite `used`;
## Main abre la MissionBoardUI. Muestra un "!" si hay misiones para reclamar.

signal used

const SIZE := Vector2(32, 32)  # 2x2 tiles
const TEXTURE := preload("res://assets/sprites/world/board.png")  # 32x32

var _focused := false


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(SIZE.x - 2, 12)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(SIZE.x / 2.0, SIZE.y - 6)  # solo las patas bloquean
	add_child(col)
	var sprite := Sprite2D.new()
	sprite.texture = TEXTURE
	sprite.centered = false
	add_child(sprite)
	add_to_group("interactable")
	Missions.changed.connect(queue_redraw)
	GameState.bag_changed.connect(queue_redraw)
	GameState.storage_changed.connect(queue_redraw)


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
	if Missions.ready_count() > 0:
		# Aviso de misión lista para reclamar (placeholder)
		draw_rect(Rect2(SIZE.x / 2.0 - 2, -10, 4, 6), Color(0.95, 0.8, 0.3))
		draw_rect(Rect2(SIZE.x / 2.0 - 2, -3, 4, 2), Color(0.95, 0.8, 0.3))
