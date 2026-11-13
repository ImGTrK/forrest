class_name Board
extends Interactable
## Tablón de misiones del pueblo (GDD §6, sin NPC). Al interactuar emite `used`;
## Main abre la MissionBoardUI. Muestra un "!" si hay misiones para reclamar.


func _init() -> void:
	size = Vector2(32, 32)  # 2x2 tiles
	texture = preload("res://assets/sprites/world/board.png")  # 32x32
	label_text = "Misiones  [E]"
	label_offset = Vector2(-6, -22)


func _ready() -> void:
	super._ready()
	Missions.changed.connect(queue_redraw)
	GameState.bag_changed.connect(queue_redraw)
	GameState.storage_changed.connect(queue_redraw)


## Solo las patas (abajo) bloquean el paso.
func _collision_rect() -> Rect2:
	return Rect2(Vector2(1, size.y - 12), Vector2(size.x - 2, 12))


func _draw_overlay() -> void:
	if Missions.ready_count() > 0:
		# Aviso de misión lista para reclamar (placeholder)
		draw_rect(Rect2(size.x / 2.0 - 2, -10, 4, 6), Color(0.95, 0.8, 0.3))
		draw_rect(Rect2(size.x / 2.0 - 2, -3, 4, 2), Color(0.95, 0.8, 0.3))
