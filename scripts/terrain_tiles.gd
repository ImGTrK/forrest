class_name TerrainTiles
extends RefCounted
## TileSet del terreno, armado por código a partir de assets/tilesets/terrain.png.
##
## El PNG es una tira de 16x16 por tile. El ORDEN de las columnas importa:
##   0 pasto · 1 pared · 2 piso (hub) · 3 camino
## Para meter tu arte: pisá terrain.png con el mismo tamaño (64x16) y orden.
## Si más adelante querés variantes/autotiling, conviene pasar a un TileSet .tres
## pintado en el editor; sólo cambia get_tileset().

const TILE := 16
const TEXTURE := preload("res://assets/tilesets/terrain.png")

enum { GRASS, WALL, FLOOR, PATH }
const TILE_COUNT := 4

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
	for i in TILE_COUNT:
		src.create_tile(Vector2i(i, 0))

	# Sólo la pared tiene colisión
	var h := TILE / 2.0
	var wall := src.get_tile_data(Vector2i(WALL, 0), 0)
	wall.add_collision_polygon(0)
	wall.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)]))

	_cache = ts
	return ts


static func make_layer() -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.tile_set = get_tileset()
	return layer
