class_name LostChest
extends Interactable
## Cofre perdido (evento raro del hito 9): al abrirlo da recursos con buen ADN.
## Queda abierto: si volvés a la zona en el mismo run, sigue vacío (se guarda en la entidad).

## Cuántos recursos trae.
const LOOT_COUNT := 3

var entry: SpawnEntry
var entity: Dictionary
var depth: int = 0


func setup(p_entry: SpawnEntry, p_entity: Dictionary, p_depth: int) -> void:
	entry = p_entry
	entity = p_entity
	depth = p_depth
	size = Vector2(entry.size * TerrainTiles.TILE)
	texture = entry.texture  # 2 frames: cerrado, abierto
	if not entity.has("loot"):
		entity["loot"] = LOOT_COUNT


func _ready() -> void:
	super._ready()
	_sprite.hframes = 2
	_update_frame()


func is_open() -> bool:
	return int(entity.get("loot", 0)) <= 0


func _on_interact(_by: Node) -> void:
	if is_open():
		GameState.notify("El cofre está vacío")
		return
	var pool: Array[ItemData] = [load("res://data/items/wood.tres"), load("res://data/items/stone.tres")]
	if depth + entry.loot_bonus >= 3:
		pool.append(load("res://data/items/iron.tres"))
	while int(entity.loot) > 0:
		var data := pool[ForestSession.rng.randi_range(0, pool.size() - 1)]
		var item := DNA.generar_recurso(data, depth + entry.loot_bonus, ForestSession.rng)
		if not GameState.pick_up(item):
			break  # lo que no entra queda en el cofre
		entity.loot = int(entity.loot) - 1
	_update_frame()


func _update_frame() -> void:
	_sprite.frame = 1 if is_open() else 0
