class_name Hub
extends Node2D
## Pueblo: hub fijo y persistente (GDD §3). Desde el hito 9 usa el mismo suelo por materiales
## que el bosque (transiciones automáticas) y su decoración.
##   - Izquierda: plaza de piedra compacta con almacén C, cama B y mesa M.
##   - Derecha: camino al bosque (salida por el borde este), tablón T y un estanque.
##
## El layout está en ASCII para poder leerlo y editarlo rápido (cada fila mide lo mismo).
##  Suelo:  H cerco   . pasto   , pasto oscuro   p camino   f piso de la plaza   w agua
##  Props:  C almacén   B cama (1×2)   M mesa (2×1)   T tablón (2×2)
##  Lugares: P inicio del juego   F llegada al volver del bosque
##  Decoración: t árbol (2×2)   a arbusto   o flores   g pasto alto   s tocón   r roca grande (2×2)
##              l nenúfar (sobre agua)
## Las letras de props y decoración toman el suelo de la celda de su izquierda.

signal leave(dir: Vector2i)
signal chest_opened
signal bed_used
signal bench_used
signal board_used

const TILE := TerrainTiles.TILE
const Mat := TerrainTiles.Mat

const LAYOUT: Array[String] = [
	"HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH",
	"HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH",
	"HH............................................HH",
	"HH.t....o.............t..............,,t,,,,..HH",
	"HH...fffffffffffff.t......t..........,,,,,,,..HH",
	"HH...ffBffffffffff...................,,,,,t,..HH",
	"HH...ffffffCffMfff..........o..ppT...,,,,,,,..HH",
	"HH...fffffffffffff..o...a......pp....,,,,,,,..HH",
	"HH...fffffffffffff.............pp...o.........HH",
	"HH...fffffffffffff.............pp......a......HH",
	"HH.......ppppppppppppppppppppppppppppppppppppppp",
	"HH.......pppppppppppppppppppppppppppppppppppFppp",
	"HH.......ppPpppppppppppppppppppppppppppppppppppp",
	"HH.......ppppppppppppppppppppppppppppppppppppppp",
	"HH.g............g............g.........g......HH",
	"HH....o..........a...o.........wwwwwww........HH",
	"HH.............o..............wwwwwwwww.......HH",
	"HH.,t,,,,,.............t......wwwlwwwww..t....HH",
	"HH.,,,,t,,...o...............awwwwwwlww....r..HH",
	"HH.,,,,,,,..........g.........wwwwwwwww.a.....HH",
	"HH.,,,,,,,.a.....so........o...wwwwwww......o.HH",
	"HH............................................HH",
	"HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH",
	"HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH",
]

const GROUND_CHARS := {
	"H": Mat.HEDGE, ".": Mat.GRASS, ",": Mat.DARK, "p": Mat.PATH, "F": Mat.PATH,
	"f": Mat.FLOOR, "w": Mat.WATER, "l": Mat.WATER,
}
## Decoración: letra -> id en ZoneGenerator.EXTRAS (el árbol se arma aparte: no se puede talar).
const DECO_CHARS := {
	"a": &"bush", "o": &"deco_flowers", "g": &"deco_tall_grass", "s": &"deco_stump",
	"r": &"deco_boulder", "l": &"deco_lilypad",
}

var player: Player

var _size := Vector2i.ZERO
var _spawns := {}


func _ready() -> void:
	_size = Vector2i(LAYOUT[0].length(), LAYOUT.size())
	var ground := PackedByteArray()
	ground.resize(_size.x * _size.y)
	for y in _size.y:
		var row := LAYOUT[y]
		if row.length() != _size.x:
			push_error("Hub LAYOUT: la fila %d mide %d, se esperaba %d" % [y, row.length(), _size.x])
		for x in _size.x:
			var ch := row[x]
			var m: int = GROUND_CHARS.get(ch, -1)
			if m < 0:  # prop o decoración: toma el suelo de la izquierda
				m = ground[x - 1 + y * _size.x] if x > 0 else Mat.GRASS
			ground[x + y * _size.x] = m

	var layer := TerrainTiles.make_layer()
	add_child(layer)
	TerrainTiles.paint_ground(layer, ground, _size, 1234)

	for y in _size.y:
		for x in _size.x:
			var cell := Vector2i(x, y)
			var ch := LAYOUT[y][x]
			var center := Vector2(cell * TILE) + Vector2(TILE, TILE) / 2.0
			match ch:
				"C": _spawn_chest(cell)
				"B": _spawn_bed(cell)
				"M": _spawn_bench(cell)
				"T": _spawn_board(cell)
				"P": _spawns["start"] = center
				"F": _spawns["forest"] = center
				"t": _spawn_deco(_tree_deco(), cell)
				_:
					if DECO_CHARS.has(ch):
						_spawn_deco(ZoneGenerator.EXTRAS[DECO_CHARS[ch]], cell)

	_add_label("Bosque  →", Vector2((_size.x - 7) * TILE, 8 * TILE + 4))


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


## Decoración (no se usa con E). La entidad es local: el pueblo no se guarda en la cache.
func _spawn_deco(entry: SpawnEntry, cell: Vector2i) -> void:
	var h := Harvestable.new()
	h.setup(entry, {"alive": true, "tile": cell}, 0)
	h.position = Vector2(cell * TILE)
	add_child(h)


## Árbol del pueblo: mismo sprite que el del bosque pero sin ítem (no se tala).
func _tree_deco() -> SpawnEntry:
	var e: SpawnEntry = (load("res://data/spawns/tree.tres") as SpawnEntry).duplicate()
	e.item = null
	e.id = &"hub_tree"
	return e


func _add_label(text: String, pos: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", 8)
	add_child(label)
