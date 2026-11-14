class_name Harvestable
extends Interactable
## Árbol / roca / veta (o arbusto decorativo si no tiene item).
## Se construye por código a partir de un SpawnEntry: es el "prefab" de todas las entidades
## recolectables. El sprite sale de SpawnEntry.texture (mide exactamente size * 16 px,
## con el origen en la esquina superior izquierda).

## Poder de golpe a mano (sin herramienta). Árbol (dureza 6) = 4 golpes a mano.
const HAND_POWER := 1.5
const TOOL_NAMES := {&"axe": "un hacha", &"pickaxe": "un pico"}

var entry: SpawnEntry
var entity: Dictionary  # referencia al dict dentro de ZoneData (para marcar alive = false)
var depth: int = 0

var _hp: float = 1.0
var _flash: HitFlash


func setup(p_entry: SpawnEntry, p_entity: Dictionary, p_depth: int) -> void:
	entry = p_entry
	entity = p_entity
	depth = p_depth
	size = Vector2(entry.size * TerrainTiles.TILE)
	texture = entry.texture


func _ready() -> void:
	super._ready()
	_hp = entry.hardness
	# Si la textura es una tira de variantes (ej. tree.png = 3 árboles de 32×32), se usa una.
	# La elección sale de la posición de la entidad: la misma zona se ve igual al volver.
	if _sprite and texture.get_width() > int(size.x):
		var frames := int(texture.get_width() / size.x)
		_sprite.hframes = frames
		_sprite.frame = posmod(hash(entity.get("tile", Vector2i.ZERO)), frames)
	_flash = HitFlash.new(_sprite)
	add_child(_flash)


func _collision_rect() -> Rect2:
	return Rect2(Vector2(2, 2), size - Vector2(4, 4))


## Los arbustos decorativos (sin ítem) no se pueden golpear.
func is_interactive() -> bool:
	return entry.item != null


## Golpes que faltan con la herramienta actual (para tests y feedback).
func hits_left() -> int:
	var tool := GameState.best_tool(entry.tool_type)
	return ceili(_hp / (tool.power() if tool else HAND_POWER))


func _on_interact(_by: Node) -> void:
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
	_flash.flash(Color(1.8, 1.8, 1.8), 0.2, 1.0)  # destello + sacudida al golpear
	if _hp > 0.0:
		return
	var item := DNA.generar_recurso(entry.item, depth, ForestSession.rng)
	entity.alive = false
	GameState.pick_up(item)
	queue_free()


func _draw_overlay() -> void:
	if _sprite:
		return
	# Sin textura: rectángulo de color
	var k := _flash.amount() if _flash else 0.0
	draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), entry.color.lerp(Color.WHITE, k * 0.6))
