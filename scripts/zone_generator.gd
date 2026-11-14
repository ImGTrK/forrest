class_name ZoneGenerator
extends RefCounted
## Generación procedural por PRESUPUESTO DE DIFICULTAD (GDD §2).
##
##   presupuesto = (BASE_BUDGET + profundidad * BUDGET_PER_DEPTH) * dificultad_por_hora
##   rareza      = profundidad + bonus_por_hora   (pesos, min_depth y ADN)
##
## El presupuesto se "gasta" tirando entidades de una tabla ponderada hasta agotarlo.
## Escalar la dificultad = cambiar un número; no hacen falta tablas por nivel.
##
## Hito 9 — bosque vivo. Orden de generación de una zona:
##   1. puertas (anti-encierro)          4. recursos y enemigos (presupuesto, pesos de la plantilla)
##   2. plantilla (ZoneTemplates)        5. decoración en grupos (según la plantilla)
##   3. suelo: cerco, manchas, caminos   6. evento raro (a veces)

## 40x40 tiles de 16 px = 640x640 px: el ancho coincide exacto con el viewport (640),
## así la zona se ve entera de lado a lado y solo hay scroll vertical.
## (Era 50x50 en el GDD original; se achicó porque se sentía vacía y lenta.)
const ZONE_TILES := 40
## La puerta ocupa 4 tiles centrados en el lado (con 40: tiles 18..21).
const DOOR_MIN := ZONE_TILES / 2 - 2
const DOOR_MAX := ZONE_TILES / 2 + 1
const DOOR_CHANCE := 0.45
const BASE_BUDGET := 6
const BUDGET_PER_DEPTH := 3
## Grosor del cerco que rodea la zona (2: las piezas de transición necesitan regiones de 2+).
const WALL_THICKNESS := 2

const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

## Lo que se compra con presupuesto.
const SPAWN_TABLE := [
	preload("res://data/spawns/tree.tres"),
	preload("res://data/spawns/rock.tres"),
	preload("res://data/spawns/iron_vein.tres"),
	preload("res://data/spawns/enemy_basic.tres"),
	preload("res://data/spawns/enemy_spitter.tres"),
	preload("res://data/spawns/enemy_charger.tres"),
]

## Decoración y eventos por id (las plantillas los nombran por id).
const EXTRAS := {
	&"bush": preload("res://data/spawns/bush.tres"),
	&"deco_flowers": preload("res://data/spawns/deco_flowers.tres"),
	&"deco_tall_grass": preload("res://data/spawns/deco_tall_grass.tres"),
	&"deco_mushrooms": preload("res://data/spawns/deco_mushrooms.tres"),
	&"deco_stump": preload("res://data/spawns/deco_stump.tres"),
	&"deco_log": preload("res://data/spawns/deco_log.tres"),
	&"deco_boulder": preload("res://data/spawns/deco_boulder.tres"),
	&"deco_ruin_pillar": preload("res://data/spawns/deco_ruin_pillar.tres"),
	&"deco_ruin_wall": preload("res://data/spawns/deco_ruin_wall.tres"),
	&"deco_lilypad": preload("res://data/spawns/deco_lilypad.tres"),
	&"campfire": preload("res://data/spawns/campfire.tres"),
	&"camp_tent": preload("res://data/spawns/camp_tent.tres"),
	&"ancient_tree": preload("res://data/spawns/ancient_tree.tres"),
	&"shiny_vein": preload("res://data/spawns/shiny_vein.tres"),
	&"lost_chest": preload("res://data/spawns/lost_chest.tres"),
	&"enemy_basic": preload("res://data/spawns/enemy_basic.tres"),
	&"enemy_spitter": preload("res://data/spawns/enemy_spitter.tres"),
}
## Centros de los 4 cuadrantes (lejos de los corredores en cruz del medio).
const QUADRANTS: Array[Vector2i] = [Vector2i(10, 10), Vector2i(29, 10), Vector2i(10, 29), Vector2i(29, 29)]

const Mat := TerrainTiles.Mat


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
	z.template = ZoneTemplates.pick(z.loot_depth(), rng)
	z.paint_seed = rng.randi()
	var occupied := corridor_cells(z)
	_build_ground(z, occupied, rng)
	_populate(z, occupied, rng)
	_decorate(z, occupied, rng)
	_place_event(z, occupied, rng)
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


## Cerco de WALL_THICKNESS tiles alrededor, abierto en las puertas.
static func is_wall(z: ZoneData, c: Vector2i) -> bool:
	var far := ZONE_TILES - WALL_THICKNESS
	if c.x < WALL_THICKNESS and not (z.has_door(Vector2i.LEFT) and in_door_gap(c.y)):
		return true
	if c.x >= far and not (z.has_door(Vector2i.RIGHT) and in_door_gap(c.y)):
		return true
	if c.y < WALL_THICKNESS and not (z.has_door(Vector2i.UP) and in_door_gap(c.x)):
		return true
	if c.y >= far and not (z.has_door(Vector2i.DOWN) and in_door_gap(c.x)):
		return true
	return false


## Celdas de camino: de cada puerta al centro. Se reservan (nada se spawnea encima),
## así todas las puertas de una zona siempre quedan conectadas entre sí.
static func corridor_cells(z: ZoneData) -> Dictionary:
	var cells := {}
	var mid := ZONE_TILES / 2
	var rects: Array[Rect2i] = [Rect2i(DOOR_MIN, DOOR_MIN, 4, 4)]  # centro
	if z.has_door(Vector2i.LEFT):
		rects.append(Rect2i(0, DOOR_MIN, mid + 1, 4))
	if z.has_door(Vector2i.RIGHT):
		rects.append(Rect2i(DOOR_MIN, DOOR_MIN, ZONE_TILES - DOOR_MIN, 4))
	if z.has_door(Vector2i.UP):
		rects.append(Rect2i(DOOR_MIN, 0, 4, mid + 1))
	if z.has_door(Vector2i.DOWN):
		rects.append(Rect2i(DOOR_MIN, DOOR_MIN, 4, ZONE_TILES - DOOR_MIN))
	for r in rects:
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				cells[Vector2i(x, y)] = true
	return cells


# --- Suelo -------------------------------------------------------------------

## Pinta el material de cada celda: manchas de la plantilla, cerco en el borde y caminos.
## El agua y el cerco quedan ocupados (no se puede poner nada encima).
static func _build_ground(z: ZoneData, occupied: Dictionary, rng: RandomNumberGenerator) -> void:
	var n := ZONE_TILES
	z.ground.resize(n * n)
	z.ground.fill(Mat.GRASS)
	var corridors := corridor_cells(z)
	var quads: Array = QUADRANTS.duplicate()
	_shuffle(quads, rng)
	var t: Dictionary = ZoneTemplates.TEMPLATES[z.template]
	for f: Array in t.features:
		for i in int(f[1]):
			var q: Vector2i = quads.pop_back() if not quads.is_empty() else QUADRANTS[rng.randi_range(0, 3)]
			q += Vector2i(rng.randi_range(-2, 2), rng.randi_range(-2, 2))
			match f[0]:
				&"dark":
					_blob(z, q, rng.randf_range(3.0, 5.5), rng.randf_range(2.5, 4.5), Mat.DARK, corridors, 0)
				&"clearing":
					_blob(z, q, rng.randf_range(4.0, 6.0), rng.randf_range(3.0, 5.0), Mat.DIRT, corridors, 0)
				&"pond":
					_blob(z, q, rng.randf_range(3.5, 5.0), rng.randf_range(2.8, 4.0), Mat.WATER, corridors, 2)
				&"ruins":
					var w := rng.randi_range(6, 9)
					var h := rng.randi_range(5, 7)
					for y in range(q.y - h / 2, q.y - h / 2 + h):
						for x in range(q.x - w / 2, q.x - w / 2 + w):
							_set_ground(z, Vector2i(x, y), Mat.RUIN, corridors, 0)
	for y in n:
		for x in n:
			var c := Vector2i(x, y)
			if is_wall(z, c):
				z.ground[x + y * n] = Mat.HEDGE
			elif corridors.has(c):
				z.ground[x + y * n] = Mat.PATH
	TerrainTiles.clean_thin(z.ground, Vector2i(n, n))
	for y in n:
		for x in n:
			var m := z.ground[x + y * n]
			if m == Mat.WATER or m == Mat.HEDGE:
				occupied[Vector2i(x, y)] = true


## Mancha elíptica de un material. `gap` = celdas libres que deja alrededor de los corredores.
static func _blob(z: ZoneData, center: Vector2i, rx: float, ry: float, m: int, corridors: Dictionary, gap: int) -> void:
	for y in range(center.y - ceili(ry) - 1, center.y + ceili(ry) + 2):
		for x in range(center.x - ceili(rx) - 1, center.x + ceili(rx) + 2):
			var v := Vector2((x - center.x) / rx, (y - center.y) / ry)
			if v.length() <= 1.0:
				_set_ground(z, Vector2i(x, y), m, corridors, gap)


## Cambia el material de una celda si no pisa el borde ni (con margen `gap`) un corredor.
static func _set_ground(z: ZoneData, c: Vector2i, m: int, corridors: Dictionary, gap: int) -> void:
	var n := ZONE_TILES
	var lo := WALL_THICKNESS + 1
	if c.x < lo or c.y < lo or c.x >= n - lo or c.y >= n - lo:
		return
	for dy in range(-gap, gap + 1):
		for dx in range(-gap, gap + 1):
			if corridors.has(c + Vector2i(dx, dy)):
				return
	z.ground[c.x + c.y * n] = m


static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


# --- Contenido -------------------------------------------------------------

static func _populate(z: ZoneData, occupied: Dictionary, rng: RandomNumberGenerator) -> void:
	var budget := roundi((BASE_BUDGET + z.depth * BUDGET_PER_DEPTH) * z.difficulty)
	var loot := z.loot_depth()
	z.budget = budget
	var mult: Dictionary = ZoneTemplates.TEMPLATES[z.template].spawn_mult

	var buyable: Array[SpawnEntry] = []
	for e: SpawnEntry in SPAWN_TABLE:
		if e.cost > 0 and loot >= e.min_depth:
			buyable.append(e)

	# Gastar el presupuesto
	while budget > 0:
		var options := buyable.filter(func(e: SpawnEntry) -> bool: return e.cost <= budget)
		if options.is_empty():
			break
		var entry := _weighted_pick(options, loot, rng, mult)
		var tile := _find_free_tile(entry.size, occupied, rng)
		if tile.x < 0:
			break  # zona llena
		_place(z, entry, tile, occupied)
		budget -= entry.cost


## Decoración de la plantilla, en grupos (no consume presupuesto).
static func _decorate(z: ZoneData, occupied: Dictionary, rng: RandomNumberGenerator) -> void:
	var t: Dictionary = ZoneTemplates.TEMPLATES[z.template]
	for d: Array in t.deco:
		var entry: SpawnEntry = EXTRAS[d[0]]
		var count: Vector2i = d[2]
		var near_ruin: bool = d.size() > 3 and d[3] == &"ruin"
		for g in int(d[1]):
			var center := _deco_anchor(z, entry, occupied, rng, near_ruin)
			if center.x < 0:
				continue
			for i in rng.randi_range(count.x, count.y):
				var tile := center
				if i > 0:
					tile += Vector2i(rng.randi_range(-2, 2), rng.randi_range(-2, 2))
				if _deco_fits(z, entry, tile, occupied):
					_place(z, entry, tile, occupied)


## Punto de partida de un grupo de decoración.
static func _deco_anchor(z: ZoneData, entry: SpawnEntry, occupied: Dictionary, rng: RandomNumberGenerator,
		near_ruin := false) -> Vector2i:
	var lo := WALL_THICKNESS + 1
	for attempt in 80:
		var tile := Vector2i(rng.randi_range(lo, ZONE_TILES - lo - entry.size.x),
			rng.randi_range(lo, ZONE_TILES - lo - entry.size.y))
		if near_ruin and not _near(z, tile, Mat.RUIN, 1):
			continue
		if _deco_fits(z, entry, tile, occupied):
			return tile
	return Vector2i(-1, -1)


## Lo blando (flores, pasto alto) puede ir pegado a otras cosas; lo sólido pide 1 tile de margen.
## Los nenúfares solo van sobre el agua, sin tocar la orilla.
static func _deco_fits(z: ZoneData, entry: SpawnEntry, tile: Vector2i, occupied: Dictionary) -> bool:
	if entry.placement == &"water":
		if z.ground_at(tile) != Mat.WATER or _has_entity_at(z, tile):
			return false
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if z.ground_at(tile + d) != Mat.WATER:
				return false
		return true
	var margin := 1 if entry.solid else 0
	for y in range(tile.y - margin, tile.y + entry.size.y + margin):
		for x in range(tile.x - margin, tile.x + entry.size.x + margin):
			var c := Vector2i(x, y)
			var g := z.ground_at(c)
			if occupied.has(c) or g == Mat.WATER or g == Mat.HEDGE or g == Mat.PATH:
				return false
	return true


## ¿Hay celdas del material m a r tiles o menos?
static func _near(z: ZoneData, c: Vector2i, m: int, r: int) -> bool:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if z.ground_at(c + Vector2i(dx, dy)) == m:
				return true
	return false


static func _has_entity_at(z: ZoneData, c: Vector2i) -> bool:
	for e in z.entities:
		if Rect2i(e.tile, (e.entry as SpawnEntry).size).has_point(c):
			return true
	return false


# --- Eventos raros ----------------------------------------------------------

static func _place_event(z: ZoneData, occupied: Dictionary, rng: RandomNumberGenerator) -> void:
	var ev := ZoneTemplates.pick_event(z.template, z.loot_depth(), rng)
	if ev == &"":
		return
	if ev == &"camp":
		# Claro de 6×5: carpa, fogata en el medio, cofre y tres enemigos alrededor
		var area := _find_free_tile(Vector2i(6, 5), occupied, rng)
		if area.x < 0:
			return
		var fire := area + Vector2i(3, 3)
		_place(z, EXTRAS[&"camp_tent"], area, occupied)
		_place(z, EXTRAS[&"campfire"], fire, occupied)
		_place(z, EXTRAS[&"lost_chest"], area + Vector2i(5, 1), occupied)
		# Guardias: dos erizos y, desde profundidad 2, un Lanzador detrás de la fogata
		for off: Vector2i in [Vector2i(-2, 1), Vector2i(2, 1), Vector2i(0, -2)]:
			var guard: StringName = &"enemy_spitter" if off.y < 0 and z.loot_depth() >= 2 else &"enemy_basic"
			z.entities.append({"entry": EXTRAS[guard], "tile": fire + off, "alive": true})
		z.event = ev
		return
	var entry: SpawnEntry = EXTRAS[ev]
	var tile := _find_free_tile(entry.size, occupied, rng)
	if tile.x < 0:
		return
	_place(z, entry, tile, occupied)
	z.event = ev


# --- Utilidades ----------------------------------------------------------------

static func _weight(e: SpawnEntry, depth: int, mult: Dictionary = {}) -> float:
	return (e.weight + e.weight_per_depth * depth) * float(mult.get(e.id, 1.0))


static func _weighted_pick(options: Array, depth: int, rng: RandomNumberGenerator, mult: Dictionary = {}) -> SpawnEntry:
	var total := 0.0
	for e: SpawnEntry in options:
		total += _weight(e, depth, mult)
	var r := rng.randf() * total
	for e: SpawnEntry in options:
		r -= _weight(e, depth, mult)
		if r <= 0.0:
			return e
	return options.back()


## Busca una posición libre con 1 tile de margen alrededor. Devuelve (-1,-1) si no encuentra.
static func _find_free_tile(size: Vector2i, occupied: Dictionary, rng: RandomNumberGenerator) -> Vector2i:
	var lo := WALL_THICKNESS + 1
	for attempt in 40:
		var tile := Vector2i(
			rng.randi_range(lo, ZONE_TILES - lo - size.x),
			rng.randi_range(lo, ZONE_TILES - lo - size.y))
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
