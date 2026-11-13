class_name Minimap
extends Control
## Minimapa de run estilo Isaac (GDD §4.1): dibuja las zonas ya generadas
## (sale gratis de la cache de ForestSession) centrado en la zona actual.
## Las "patitas" son puertas; una patita que no lleva a ningún cuadro = camino sin explorar.

const CELL := 10.0
const GAP := 4.0

const COL_BG := Color(0, 0, 0, 0.55)
const COL_VISITED := Color(0.65, 0.7, 0.65)
const COL_CURRENT := Color(1, 1, 1)
const COL_HUB := Color(0.85, 0.7, 0.4)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	ForestSession.zone_entered.connect(func(_c: Vector2i) -> void: queue_redraw())
	ForestSession.run_reset.connect(queue_redraw)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COL_BG)
	var area := Rect2(Vector2.ZERO, size).grow(-3)
	var step := CELL + GAP
	var center := size / 2.0
	var cur := ForestSession.current

	var hub_p := center + Vector2(ForestSession.HUB_COORD - cur) * step
	if area.has_point(hub_p):
		draw_rect(Rect2(hub_p - Vector2(CELL, CELL) / 2.0, Vector2(CELL, CELL)), COL_HUB)

	for c: Vector2i in ForestSession.zones:
		var z: ZoneData = ForestSession.zones[c]
		var p := center + Vector2(c - cur) * step
		if not area.has_point(p):
			continue
		var col := COL_CURRENT if c == cur else COL_VISITED
		draw_rect(Rect2(p - Vector2(CELL, CELL) / 2.0, Vector2(CELL, CELL)), col)
		for dir: Vector2i in z.doors:
			if z.doors[dir]:
				var d := Vector2(dir)
				draw_line(p + d * CELL / 2.0, p + d * (CELL / 2.0 + GAP / 2.0), col, 2.0)
