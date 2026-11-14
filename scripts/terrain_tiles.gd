class_name TerrainTiles
extends RefCounted
## TileSet del terreno, armado por código a partir de assets/tilesets/terrain.png (256×128).
## Mapa completo del PNG en docs/GUIA_ARTE_Y_SONIDO.md §2.1.
##
## Dos formas de pintar:
##  - tile suelto: layer.set_cell(celda, 0, Vector2i(GRASS, 0)) (lo usa el pueblo)
##  - por materiales: paint_ground() recibe qué material hay en cada celda y elige solo la pieza
##    (borde, esquina externa/interna o centro) mirando los vecinos, más variantes al azar.
##    Es un autotile propio y simple (≈ Rule Tile de Unity) con 13 piezas por material.

const TILE := 16
const TEXTURE := preload("res://assets/tilesets/terrain.png")
const ATLAS_SIZE := Vector2i(16, 8)

## Columnas de la fila 0 (compatibles con la versión de 64×16).
enum { GRASS, WALL, FLOOR, PATH }

## Materiales del suelo del bosque (ZoneData.ground guarda uno por celda).
enum Mat { GRASS, PATH, DIRT, WATER, DARK, HEDGE, RUIN, FLOOR }

## Origen de cada juego de transición (5×3 tiles) dentro del atlas.
const SETS := {
	Mat.PATH: Vector2i(0, 2), Mat.DIRT: Vector2i(5, 2), Mat.WATER: Vector2i(10, 2),
	Mat.DARK: Vector2i(0, 5), Mat.HEDGE: Vector2i(5, 5), Mat.RUIN: Vector2i(10, 5),
}
## Tiles "centro" de cada material con su peso: el primero es la base tranquila.
const CENTERS := {
	Mat.GRASS: [[Vector2i(0, 0), 12.0], [Vector2i(5, 1), 5.0], [Vector2i(8, 0), 0.7], [Vector2i(9, 0), 0.5],
		[Vector2i(10, 0), 0.4], [Vector2i(11, 0), 0.3]],
	Mat.PATH: [[Vector2i(3, 0), 8.0], [Vector2i(12, 0), 1.0], [Vector2i(6, 1), 1.0]],
	Mat.DIRT: [[Vector2i(4, 0), 6.0], [Vector2i(13, 0), 1.5]],
	Mat.WATER: [[Vector2i(6, 0), 6.0], [Vector2i(2, 1), 1.0]],
	Mat.DARK: [[Vector2i(5, 0), 5.0], [Vector2i(15, 0), 1.5]],
	Mat.HEDGE: [[Vector2i(1, 0), 6.0], [Vector2i(0, 1), 1.0], [Vector2i(1, 1), 2.0]],
	Mat.RUIN: [[Vector2i(7, 0), 5.0], [Vector2i(3, 1), 1.0], [Vector2i(4, 1), 1.5]],
	# Piso del pueblo: sin juego de transición (es una plaza construida, de bordes rectos)
	Mat.FLOOR: [[Vector2i(FLOOR, 0), 6.0], [Vector2i(14, 0), 1.0]],
}
## Pieza -> posición dentro del juego de 5×3.
const PIECES := {
	&"otl": Vector2i(0, 0), &"t": Vector2i(1, 0), &"otr": Vector2i(2, 0), &"itl": Vector2i(3, 0), &"itr": Vector2i(4, 0),
	&"l": Vector2i(0, 1), &"c": Vector2i(1, 1), &"r": Vector2i(2, 1), &"ibl": Vector2i(3, 1), &"ibr": Vector2i(4, 1),
	&"obl": Vector2i(0, 2), &"b": Vector2i(1, 2), &"obr": Vector2i(2, 2),
}
## Materiales que no se pueden pisar.
const SOLID := [Mat.HEDGE, Mat.WATER]
## En las piezas de borde, cuántos px de pasto hay del lado de afuera (sin colisión).
const MARGIN := 5

static var _cache: TileSet


static func get_tileset() -> TileSet:
	if _cache:
		return _cache
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	var src := TileSetAtlasSource.new()
	src.texture = TEXTURE
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, 0)
	for y in ATLAS_SIZE.y:
		for x in ATLAS_SIZE.x:
			src.create_tile(Vector2i(x, y))
	# Colisión: pared/cerco y agua (centros completos, piezas de borde solo en su parte)
	_collide(src, Vector2i(WALL, 0), &"c")
	for m in SOLID:
		for entry: Array in CENTERS[m]:
			_collide(src, entry[0], &"c")
		for piece: StringName in PIECES:
			_collide(src, SETS[m] + PIECES[piece], piece)
	_cache = ts
	return ts


## Rectángulo sólido de una pieza (en coords del tile, 0..16): todo menos el margen de pasto.
## Lados con margen de pasto en cada pieza (las esquinas internas y el centro son sólidos enteros).
const GRASS_SIDES := {
	&"otl": [SIDE_TOP, SIDE_LEFT], &"t": [SIDE_TOP], &"otr": [SIDE_TOP, SIDE_RIGHT],
	&"l": [SIDE_LEFT], &"r": [SIDE_RIGHT],
	&"obl": [SIDE_BOTTOM, SIDE_LEFT], &"b": [SIDE_BOTTOM], &"obr": [SIDE_BOTTOM, SIDE_RIGHT],
}


static func _solid_rect(piece: StringName) -> Rect2:
	var r := Rect2(0, 0, TILE, TILE)
	for side: int in GRASS_SIDES.get(piece, []):
		r = r.grow_side(side, -MARGIN)
	return r


static func _collide(src: TileSetAtlasSource, atlas: Vector2i, piece: StringName) -> void:
	var r := _solid_rect(piece)
	var h := TILE / 2.0
	var data := src.get_tile_data(atlas, 0)
	if data.get_collision_polygons_count(0) > 0:
		return
	data.add_collision_polygon(0)
	data.set_collision_polygon_points(0, 0, PackedVector2Array([
		r.position - Vector2(h, h), Vector2(r.end.x, r.position.y) - Vector2(h, h),
		r.end - Vector2(h, h), Vector2(r.position.x, r.end.y) - Vector2(h, h)]))


static func make_layer() -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.tile_set = get_tileset()
	return layer


## Qué pieza usar en una celda, mirando si los vecinos son del mismo material.
## `same` es una función (dx, dy) -> bool. Afuera del mapa cuenta como "mismo".
static func piece_for(same: Callable) -> StringName:
	var u: bool = same.call(0, -1)
	var d: bool = same.call(0, 1)
	var l: bool = same.call(-1, 0)
	var r: bool = same.call(1, 0)
	if not u and not l: return &"otl"
	if not u and not r: return &"otr"
	if not d and not l: return &"obl"
	if not d and not r: return &"obr"
	if not u: return &"t"
	if not d: return &"b"
	if not l: return &"l"
	if not r: return &"r"
	if not same.call(-1, -1): return &"itl"
	if not same.call(1, -1): return &"itr"
	if not same.call(-1, 1): return &"ibl"
	if not same.call(1, 1): return &"ibr"
	return &"c"


## Pinta un suelo de `size` celdas. ground[i] = Mat de la celda (x + y * size.x).
## `seed_value` hace que las variantes sean siempre las mismas para una zona.
static func paint_ground(layer: TileMapLayer, ground: PackedByteArray, size: Vector2i, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for y in size.y:
		for x in size.x:
			var m := ground[x + y * size.x]
			var piece := &"c"
			if m != Mat.GRASS and SETS.has(m):
				piece = piece_for(func(dx: int, dy: int) -> bool:
					var nx := x + dx
					var ny := y + dy
					if nx < 0 or ny < 0 or nx >= size.x or ny >= size.y:
						return true
					return ground[nx + ny * size.x] == m)
			var atlas: Vector2i
			if piece == &"c":
				atlas = _pick_center(m, rng)
			else:
				atlas = SETS[m] + PIECES[piece]
				rng.randf()  # mantener la secuencia estable
			layer.set_cell(Vector2i(x, y), 0, atlas)


static func _pick_center(m: int, rng: RandomNumberGenerator) -> Vector2i:
	var opts: Array = CENTERS[m]
	var total := 0.0
	for o: Array in opts:
		total += o[1]
	var r := rng.randf() * total
	for o: Array in opts:
		r -= o[1]
		if r <= 0.0:
			return o[0]
	return opts[0][0]


## Limpia franjas de 1 celda de ancho (las piezas necesitan regiones de 2+): se vuelven pasto.
static func clean_thin(ground: PackedByteArray, size: Vector2i, keep: Array = []) -> void:
	for pass_i in 3:
		var changed := false
		for y in size.y:
			for x in size.x:
				var m := ground[x + y * size.x]
				if m == Mat.GRASS or m in keep:
					continue
				var same := func(dx: int, dy: int) -> bool:
					var nx := x + dx
					var ny := y + dy
					if nx < 0 or ny < 0 or nx >= size.x or ny >= size.y:
						return true
					return ground[nx + ny * size.x] == m
				var thin_v: bool = not same.call(0, -1) and not same.call(0, 1)
				var thin_h: bool = not same.call(-1, 0) and not same.call(1, 0)
				if thin_v or thin_h:
					ground[x + y * size.x] = Mat.GRASS
					changed = true
		if not changed:
			break
