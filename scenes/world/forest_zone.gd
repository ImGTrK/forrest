class_name ForestZone
extends Node2D
## Construye en pantalla una zona del bosque a partir de su ZoneData (que vive en la cache).
## Transición tipo Isaac: cuando el jugador sale por una puerta, se emite `leave(dir)`
## y Main carga la zona vecina.

signal leave(dir: Vector2i)

const TILE := PlaceholderTiles.TILE
const SIZE := ZoneGenerator.ZONE_TILES

var zone: ZoneData
var player: Player


func setup(p_zone: ZoneData, p_player: Player) -> void:
	zone = p_zone
	player = p_player


func _ready() -> void:
	var layer := PlaceholderTiles.make_layer()
	# Más profundo = más oscuro: la dificultad se ve, no es sólo un número.
	layer.modulate = Color.WHITE.darkened(clampf(zone.depth * 0.05, 0.0, 0.45))
	add_child(layer)

	var paths := ZoneGenerator.corridor_cells(zone)
	for y in SIZE:
		for x in SIZE:
			var c := Vector2i(x, y)
			var tile := PlaceholderTiles.GRASS
			if ZoneGenerator.is_wall(zone, c):
				tile = PlaceholderTiles.WALL
			elif paths.has(c):
				tile = PlaceholderTiles.PATH
			layer.set_cell(c, 0, Vector2i(tile, 0))

	for e in zone.entities:
		if not e.alive:
			continue  # ya recolectado en este run
		var h := Harvestable.new()
		h.setup(e.entry, e, zone.depth)
		h.position = Vector2(e.tile * TILE)
		add_child(h)


func get_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(SIZE, SIZE) * TILE)


## Posición justo adentro de la puerta `entry_dir`.
func get_entry_position(entry_dir: Vector2i) -> Vector2:
	var full := SIZE * TILE
	var mid := full / 2.0
	var inset := TILE * 1.5
	if entry_dir == Vector2i.LEFT:
		return Vector2(inset, mid)
	if entry_dir == Vector2i.RIGHT:
		return Vector2(full - inset, mid)
	if entry_dir == Vector2i.UP:
		return Vector2(mid, inset)
	return Vector2(mid, full - inset)


func _physics_process(_delta: float) -> void:
	if player == null:
		return
	var p := player.global_position
	var limit := SIZE * TILE
	if p.x < -2:
		leave.emit(Vector2i.LEFT)
	elif p.x > limit + 2:
		leave.emit(Vector2i.RIGHT)
	elif p.y < -2:
		leave.emit(Vector2i.UP)
	elif p.y > limit + 2:
		leave.emit(Vector2i.DOWN)
