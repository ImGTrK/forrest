class_name Harvestable
extends StaticBody2D
## Árbol / roca / veta (o arbusto decorativo si no tiene item).
## Se construye por código a partir de un SpawnEntry: es el "prefab" de todas las entidades
## recolectables. El sprite sale de SpawnEntry.texture (mide exactamente size * 16 px,
## con el origen en la esquina superior izquierda).

var entry: SpawnEntry
var entity: Dictionary  # referencia al dict dentro de ZoneData (para marcar alive = false)
var depth: int = 0

## Poder de golpe a mano (sin herramienta). Árbol (dureza 6) = 4 golpes a mano.
const HAND_POWER := 1.5
const TOOL_NAMES := {&"axe": "un hacha", &"pickaxe": "un pico"}

var _hp: float = 1.0
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
	_hp = entry.hardness
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
	if entry.item != null:
		add_to_group("interactable")


func get_interact_rect() -> Rect2:
	return Rect2(global_position, _px_size)


func set_focused(value: bool) -> void:
	_focused = value
	queue_redraw()


## Golpes que faltan con la herramienta actual (para tests y feedback).
func hits_left() -> int:
	var tool := GameState.best_tool(entry.tool_type)
	return ceili(_hp / (tool.power() if tool else HAND_POWER))


func interact(_by: Node) -> void:
	# Sin lugar en la mochila no se golpea (y no se gasta energía).
	if not GameState.can_carry(entry.item):
		GameState.notify("La mochila está llena: no entra %s" % entry.item.display_name)
		return
	# Herramienta: la mejor del tipo que haya en la mochila (no rota)
	var tool := GameState.best_tool(entry.tool_type)
	var level := tool.data.tool_level if tool else 0
	if level < entry.min_tool_level:
		GameState.notify("Necesito %s de nivel %d o más" % [
			TOOL_NAMES.get(entry.tool_type, "una herramienta"), entry.min_tool_level])
		return
	Energy.spend_action()
	_hp -= tool.power() if tool else HAND_POWER
	GameState.wear(tool)
	_flash = 1.0
	if _hp > 0.0:
		return
	var item := DNA.generar_recurso(entry.item, depth, ForestSession.rng)
	entity.alive = false
	GameState.pick_up(item)
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
