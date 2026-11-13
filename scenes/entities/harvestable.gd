class_name Harvestable
extends StaticBody2D
## Árbol / roca / veta (o arbusto decorativo si no tiene resource_type).
## Se construye por código a partir de un SpawnEntry: es el "prefab" de todas las entidades
## recolectables. Cuando haya sprites, se agrega un Sprite2D acá y se borra _draw().

var entry: SpawnEntry
var entity: Dictionary  # referencia al dict dentro de ZoneData (para marcar alive = false)
var depth: int = 0

var _hits_left: int = 1
var _flash: float = 0.0
var _focused := false
var _px_size := Vector2.ZERO


func setup(p_entry: SpawnEntry, p_entity: Dictionary, p_depth: int) -> void:
	entry = p_entry
	entity = p_entity
	depth = p_depth


func _ready() -> void:
	_px_size = Vector2(entry.size * PlaceholderTiles.TILE)
	_hits_left = entry.hits
	var shape := RectangleShape2D.new()
	shape.size = _px_size - Vector2(4, 4)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = _px_size / 2.0
	add_child(col)
	if entry.resource_type != null:
		add_to_group("interactable")


func get_interact_rect() -> Rect2:
	return Rect2(global_position, _px_size)


func set_focused(value: bool) -> void:
	_focused = value
	queue_redraw()


func interact(_by: Node) -> void:
	_hits_left -= 1
	_flash = 1.0
	if _hits_left > 0:
		return
	var item := DNA.generar_recurso(entry.resource_type, depth, ForestSession.rng)
	entity.alive = false
	GameState.add_to_run(item)
	queue_free()


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(_flash - delta * 5.0, 0.0)
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2(2, 2), _px_size - Vector2(4, 4))
	draw_rect(r, entry.color.lerp(Color.WHITE, _flash * 0.6))
	if entry.resource_type != null:
		# Marquita del color del recurso que da
		draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(4, 4)), entry.resource_type.color)
	if _focused:
		draw_rect(r.grow(1), Color.WHITE, false, 1.0)
