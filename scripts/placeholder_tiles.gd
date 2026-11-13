class_name PlaceholderTiles
extends RefCounted
## TileSet generado por código con cuadrados de color, para no depender del arte todavía.
## Cuando metas tu arte: creá un TileSet en el editor (o un .tres) con el mismo orden de
## tiles en el atlas y devolvelo desde get_tileset(); el resto del código no cambia.

const TILE := 16

enum { GRASS, WALL, FLOOR, PATH }

const COLORS: Array[Color] = [
	Color("3b7d3a"),  # GRASS
	Color("1d3320"),  # WALL
	Color("8a7356"),  # FLOOR (madera del hub)
	Color("7d8f4e"),  # PATH
]

static var _cache: TileSet


static func get_tileset() -> TileSet:
	if _cache:
		return _cache

	var img := Image.create(TILE * COLORS.size(), TILE, false, Image.FORMAT_RGBA8)
	for i in COLORS.size():
		var base := COLORS[i]
		img.fill_rect(Rect2i(i * TILE, 0, TILE, TILE), base)
		# Borde sutil para que se note la grilla
		var edge := base.darkened(0.12)
		img.fill_rect(Rect2i(i * TILE, TILE - 1, TILE, 1), edge)
		img.fill_rect(Rect2i(i * TILE + TILE - 1, 0, 1, TILE), edge)

	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()

	var src := TileSetAtlasSource.new()
	src.texture = ImageTexture.create_from_image(img)
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, 0)
	for i in COLORS.size():
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
