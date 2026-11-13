class_name Hub
extends Node2D
## Hub fijo y persistente (GDD §3): dos "casillas" diseñadas a mano.
##   - Izquierda: casilla de gestión (almacén C, cama B, mesa M).
##   - Derecha: casilla de acceso al bosque (salida por el borde este).
##
## El layout está en ASCII para poder leerlo/editarlo rápido. Cuando tengas tu tileset,
## lo ideal es pintarlo a mano en el editor con un TileMapLayer y borrar LAYOUT.
##   W pared   . piso   g pasto   p camino
##   C almacén   B cama (ocupa esta celda y la de abajo)   M mesa de crafting (esta y la de la derecha)
##   T tablón de misiones (2x2 desde esta celda)
##   P inicio del juego   F llegada al volver del bosque

signal leave(dir: Vector2i)
signal chest_opened
signal bed_used
signal bench_used
signal board_used

const TILE := TerrainTiles.TILE

const LAYOUT: Array[String] = [
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
	"W......................WgggggggggggggggggggggggW",
	"W......................WgggggggggggggggggggggggW",
	"W.............B........WgggggggggggggggggggggggW",
	"W......................WgggggggggggggggggggggggW",
	"W......................WgggggggggggggggggggggggW",
	"W......................WgggggggggggggggggggggggW",
	"W......................WgggggggggggggggggggggggW",
	"W.....C....M...........WggggggggggggggTggggggggW",
	"W......................WgggggggggggggggggggggggW",
	"W......................WgggggggggggggggggggggggW",
	"W.......................ggggggggggggggggpppppppp",
	"W..........P............gggggggggggggggggpppFppp",
	"W.......................ggggggggggggggggpppppppp",
	"W......................WgggggggggggggggggggggggW",
	"W......................WgggggggggggggggggggggggW",
	"W......................WgggggggggggggggggggggggW",
	"W......................WgggggggggggggggggggggggW",
	"W......................WgggggggggggggggggggggggW",
	"W......................WgggggggggggggggggggggggW",
	"W......................WgggggggggggggggggggggggW",
	"W......................WgggggggggggggggggggggggW",
	"W......................WgggggggggggggggggggggggW",
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
]

var player: Player

var _size := Vector2i.ZERO
var _spawns := {}


func _ready() -> void:
	var layer := TerrainTiles.make_layer()
	add_child(layer)
	_size = Vector2i(LAYOUT[0].length(), LAYOUT.size())

	for y in LAYOUT.size():
		var row := LAYOUT[y]
		if row.length() != _size.x:
			push_error("Hub LAYOUT: la fila %d mide %d, se esperaba %d" % [y, row.length(), _size.x])
		for x in row.length():
			var cell := Vector2i(x, y)
			var ch := row[x]
			var tile := TerrainTiles.FLOOR
			if ch == "W":
				tile = TerrainTiles.WALL
			elif ch == "g":
				tile = TerrainTiles.GRASS
			elif ch == "p" or ch == "F":
				tile = TerrainTiles.PATH
			layer.set_cell(cell, 0, Vector2i(tile, 0))

			var center := Vector2(cell * TILE) + Vector2(TILE, TILE) / 2.0
			if ch == "C":
				_spawn_chest(cell)
			elif ch == "P":
				_spawns["start"] = center
			elif ch == "F":
				_spawns["forest"] = center
			elif ch == "B":
				_spawn_bed(cell)
			elif ch == "M":
				_spawn_bench(cell)
			elif ch == "T":
				tile = TerrainTiles.GRASS
				layer.set_cell(cell, 0, Vector2i(tile, 0))
				_spawn_board(cell)

	_add_label("Bosque  →", Vector2((_size.x - 7) * TILE, 9 * TILE))


func get_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(_size * TILE))


func get_spawn(spawn_name: String) -> Vector2:
	return _spawns.get(spawn_name, Vector2(_size * TILE) / 2.0)


func _physics_process(_delta: float) -> void:
	if player and player.global_position.x > _size.x * TILE + 2:
		leave.emit(Vector2i.RIGHT)


func _spawn_chest(cell: Vector2i) -> void:
	var chest := Chest.new()
	chest.position = Vector2(cell * TILE)
	chest.used.connect(chest_opened.emit)
	add_child(chest)


func _spawn_bed(cell: Vector2i) -> void:
	var bed := Bed.new()
	bed.position = Vector2(cell * TILE)
	bed.used.connect(bed_used.emit)
	add_child(bed)
	# Al despertar / colapsar se aparece al pie de la cama
	_spawns["bed"] = Vector2(cell * TILE) + Vector2(TILE / 2.0, TILE * 2.5)


func _spawn_bench(cell: Vector2i) -> void:
	var bench := Bench.new()
	bench.position = Vector2(cell * TILE)
	bench.used.connect(bench_used.emit)
	add_child(bench)


func _spawn_board(cell: Vector2i) -> void:
	var board := Board.new()
	board.position = Vector2(cell * TILE)
	board.used.connect(board_used.emit)
	add_child(board)


func _add_label(text: String, pos: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", 8)
	add_child(label)
