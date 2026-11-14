extends Node2D
## Static 640x360 composition for checking native sprite readability in Godot.
## Open ArtPreview.tscn with F6; the project viewport and nearest filter apply.

const TILE := 16
const TILES_X := 40
const TILES_Y := 22


func _ready() -> void:
	var ground := TerrainTiles.make_layer()
	add_child(ground)
	for y in TILES_Y:
		for x in TILES_X:
			var tile := TerrainTiles.GRASS
			if x == 0 or x == TILES_X - 1 or y == 0 or y == TILES_Y - 1:
				tile = TerrainTiles.WALL
			elif (abs(y - 11) <= 1 and x >= 2 and x <= 34) or (abs(x - 31) <= 1 and y >= 5 and y <= 11):
				tile = TerrainTiles.PATH
			ground.set_cell(Vector2i(x, y), 0, Vector2i(tile, 0))

	_place("world/tree.png", Vector2(64, 48))
	_place("world/tree.png", Vector2(192, 64))
	_place("world/tree.png", Vector2(464, 80))
	_place("world/tree.png", Vector2(448, 224))
	_place("world/bush.png", Vector2(128, 80))
	_place("world/bush.png", Vector2(384, 64))
	_place("world/rock.png", Vector2(144, 208))
	_place("world/iron_vein.png", Vector2(352, 208))
	_place("world/chest.png", Vector2(512, 208))
	_place("world/board.png", Vector2(544, 64))
	_place("world/bench.png", Vector2(96, 256))
	_place("world/bed.png", Vector2(48, 240))
	_place_sheet("player/player.png", Vector2(240, 172), 16, 9, 0, Vector2(0, -6))
	_place_sheet("enemies/enemy_basic.png", Vector2(368, 168), 4, 4, 0)


func _place(relative: String, pos: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/sprites/" + relative)
	sprite.centered = false
	sprite.position = pos
	add_child(sprite)


func _place_sheet(relative: String, pos: Vector2, columns: int, rows: int,
		frame: int, offset: Vector2 = Vector2.ZERO) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/sprites/" + relative)
	sprite.hframes = columns
	sprite.vframes = rows
	sprite.frame = frame
	sprite.position = pos + offset
	add_child(sprite)
