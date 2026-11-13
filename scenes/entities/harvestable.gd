class_name Harvestable
extends StaticBody2D
## Árbol / roca / veta (o arbusto decorativo si no tiene resource_type).
## Se construye por código a partir de un SpawnEntry: es el "prefab" de todas las entidades
## recolectables. El sprite sale de SpawnEntry.texture (mide exactamente size * 16 px,
## con el origen en la esquina superior izquierda).

var entry: SpawnEntry
var entity: Dictionary  # referencia al dict dentro de ZoneData (para marcar alive = false)
var depth: int = 0

var _hits_left: int = 1
var _flash: float = 0.0
var _focused := false
var _px_size := Vector2.ZERO
var _sprite: Sprite2D


func setup(p_entry: SpawnEntry, p_entity: Dictionary, p_depth: int) -> void:
	entry = p_entry
	entity = p_entity
	depth = p_depth


func _ready() -> void:
	_px_size = Vector2(entry.size * TerrainTiles.TILE)
	_hits_left = entry.hits
	var shape := RectangleShape2D.new()
	shape.size = _px_size - Vector2(4, 4)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = _px_size / 2.0
	add_child(col)
	if entry.texture:
		_sprite = Sprite2D.new()
		_sprite.texture = entry.texture
		_sprite.centered = false
		add_child(_sprite)
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
		if _sprite:
			# Destello + sacudida al golpear
			_sprite.modulate = Color.WHITE.lerp(Color(1.8, 1.8, 1.8), _flash)
			_sprite.position.x = sin(_flash * 30.0) * _flash
		queue_redraw()


func _draw() -> void:
	if _focused:
		draw_rect(Rect2(Vector2.ZERO, _px_size).grow(1), Color.WHITE, false, 1.0)
	if _sprite:
		return
	# Sin textura: rectángulo de color
	var r := Rect2(Vector2(2, 2), _px_size - Vector2(4, 4))
	draw_rect(r, entry.color.lerp(Color.WHITE, _flash * 0.6))
