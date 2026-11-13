class_name ZoneGenerator
extends RefCounted
## Generación procedural por PRESUPUESTO DE DIFICULTAD (GDD §2).
##
##   presupuesto = (BASE_BUDGET + profundidad * BUDGET_PER_DEPTH) * dificultad_por_hora
##   rareza      = profundidad + bonus_por_hora   (pesos, min_depth y ADN)
##
## El presupuesto se "gasta" tirando entidades de una tabla ponderada hasta agotarlo.
## Escalar la dificultad = cambiar un número; no hacen falta tablas por nivel.

const ZONE_TILES := 50  # 50x50 tiles de 16px = 800x800px (GDD §3)
const DOOR_MIN := 23  # la puerta ocupa los tiles 23..26 del lado (centrada)
const DOOR_MAX := 26
const DOOR_CHANCE := 0.45
const BASE_BUDGET := 6
const BUDGET_PER_DEPTH := 3
const DECORATION_RANGE := Vector2i(8, 16)

const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

const SPAWN_TABLE := [
	preload("res://data/spawns/tree.tres"),
	preload("res://data/spawns/rock.tres"),
	preload("res://data/spawns/iron_vein.tres"),
	preload("res://data/spawns/bush.tres"),
]


## `difficulty` y `rarity` vienen del reloj (Clock); el generador no lo conoce para
## poder testearse solo.
static func generate(coord: Vector2i, entry_dir: Vector2i, zones: Dictionary,
		rng: RandomNumberGenerator, hub_coord: Vector2i,
		difficulty: float = 1.0, rarity: int = 0) -> ZoneData:
	var z := ZoneData.new()
	z.coord = coord
	z.depth = absi(coord.x) + absi(coord.y)
	z.difficulty = difficulty
	z.rarity = rarity
	_roll_doors(z, entry_dir, zones, rng, hub_coord)
	_populate(z, rng)
	return z


# --- Puertas ---------------------------------------------------------------

## Reglas (GDD §3 "Conectividad"):
## - La puerta por la que se entra siempre existe.
## - Si el vecino ya fue generado, se respeta lo que él decidió (coherencia en ambos lados).
## - Si no, se tira al azar.
## - Garantía anti-encierro: si hay vecinos sin generar, al menos una puerta lleva a uno.
static func _roll_doors(z: ZoneData, entry_dir: Vector2i, zones: Dictionary,
		rng: RandomNumberGenerator, hub_coord: Vector2i) -> void:
	var unexplored: Array[Vector2i] = []
	for dir in DIRS:
		var neighbor := z.coord + dir
		if dir == entry_dir:
			z.doors[dir] = true
		elif neighbor == hub_coord:
			z.doors[dir] = false
		elif zones.has(neighbor):
			z.doors[dir] = (zones[neighbor] as ZoneData).has_door(-dir)
		else:
			z.doors[dir] = rng.randf() < DOOR_CHANCE
			unexplored.append(dir)

	if unexplored.is_empty():
		return
	for dir in unexplored:
		if z.doors[dir]:
			return
	z.doors[unexplored[rng.randi_range(0, unexplored.size() - 1)]] = true


static func in_door_gap(i: int) -> bool:
	return i >= DOOR_MIN and i <= DOOR_MAX


static func is_wall(z: ZoneData, c: Vector2i) -> bool:
	var last := ZONE_TILES - 1
	if c.x == 0:
		return not (z.has_door(Vector2i.LEFT) and in_door_gap(c.y))
	if c.x == last:
		return not (z.has_door(Vector2i.RIGHT) and in_door_gap(c.y))
	if c.y == 0:
		return not (z.has_door(Vector2i.UP) and in_door_gap(c.x))
	if c.y == last:
		return not (z.has_door(Vector2i.DOWN) and in_door_gap(c.x))
	return false


## Celdas de camino: de cada puerta al centro. Se reservan (nada se spawnea encima),
## así todas las puertas de una zona siempre quedan conectadas entre sí.
static func corridor_cells(z: ZoneData) -> Dictionary:
	var cells := {}
	var mid := ZONE_TILES / 2  # 25
	var rects: Array[Rect2i] = [Rect2i(DOOR_MIN, DOOR_MIN, 4, 4)]  # centro
	if z.has_door(Vector2i.LEFT):
		rects.append(Rect2i(1, DOOR_MIN, mid, 4))
	if z.has_door(Vector2i.RIGHT):
		rects.append(Rect2i(DOOR_MIN, DOOR_MIN, ZONE_TILES - 1 - DOOR_MIN, 4))
	if z.has_door(Vector2i.UP):
		rects.append(Rect2i(DOOR_MIN, 1, 4, mid))
	if z.has_door(Vector2i.DOWN):
		rects.append(Rect2i(DOOR_MIN, DOOR_MIN, 4, ZONE_TILES - 1 - DOOR_MIN))
	for r in rects:
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				cells[Vector2i(x, y)] = true
	return cells


# --- Contenido -------------------------------------------------------------

static func _populate(z: ZoneData, rng: RandomNumberGenerator) -> void:
	var occupied := corridor_cells(z)
	var budget := roundi((BASE_BUDGET + z.depth * BUDGET_PER_DEPTH) * z.difficulty)
	var loot := z.loot_depth()
	z.budget = budget

	var buyable: Array[SpawnEntry] = []
	var decorations: Array[SpawnEntry] = []
	for e: SpawnEntry in SPAWN_TABLE:
		if e.cost <= 0:
			decorations.append(e)
		elif loot >= e.min_depth:
			buyable.append(e)

	# Gastar el presupuesto
	while budget > 0:
		var options := buyable.filter(func(e: SpawnEntry) -> bool: return e.cost <= budget)
		if options.is_empty():
			break
		var entry := _weighted_pick(options, loot, rng)
		var tile := _find_free_tile(entry.size, occupied, rng)
		if tile.x < 0:
			break  # zona llena
		_place(z, entry, tile, occupied)
		budget -= entry.cost

	# Decoración gratis (no consume presupuesto)
	if not decorations.is_empty():
		for i in rng.randi_range(DECORATION_RANGE.x, DECORATION_RANGE.y):
			var entry: SpawnEntry = decorations[rng.randi_range(0, decorations.size() - 1)]
			var tile := _find_free_tile(entry.size, occupied, rng)
			if tile.x >= 0:
				_place(z, entry, tile, occupied)


static func _weight(e: SpawnEntry, depth: int) -> float:
	return e.weight + e.weight_per_depth * depth


static func _weighted_pick(options: Array, depth: int, rng: RandomNumberGenerator) -> SpawnEntry:
	var total := 0.0
	for e: SpawnEntry in options:
		total += _weight(e, depth)
	var r := rng.randf() * total
	for e: SpawnEntry in options:
		r -= _weight(e, depth)
		if r <= 0.0:
			return e
	return options.back()


## Busca una posición libre con 1 tile de margen alrededor. Devuelve (-1,-1) si no encuentra.
static func _find_free_tile(size: Vector2i, occupied: Dictionary, rng: RandomNumberGenerator) -> Vector2i:
	for attempt in 40:
		var tile := Vector2i(
			rng.randi_range(2, ZONE_TILES - 2 - size.x),
			rng.randi_range(2, ZONE_TILES - 2 - size.y))
		var free := true
		for y in range(tile.y - 1, tile.y + size.y + 1):
			for x in range(tile.x - 1, tile.x + size.x + 1):
				if occupied.has(Vector2i(x, y)):
					free = false
					break
			if not free:
				break
		if free:
			return tile
	return Vector2i(-1, -1)


static func _place(z: ZoneData, entry: SpawnEntry, tile: Vector2i, occupied: Dictionary) -> void:
	for y in range(tile.y, tile.y + entry.size.y):
		for x in range(tile.x, tile.x + entry.size.x):
			occupied[Vector2i(x, y)] = true
	z.entities.append({"entry": entry, "tile": tile, "alive": true})
