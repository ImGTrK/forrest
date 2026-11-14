extends SceneTree
## Test headless del generador. Correr con:
##   godot --headless --path . --script res://tests/test_generation.gd
## Simula muchos runs con caminatas aleatorias y verifica las reglas del GDD §3.

const HUB := Vector2i(-1, 0)
const RUNS := 200
const STEPS := 60

var _failures := 0


func _init() -> void:
	var stats := {"zones": 0, "depth_sum_budget": {}, "iron_before_min_depth": 0, "templates": {}, "events": {}}
	for run in RUNS:
		var rng := RandomNumberGenerator.new()
		rng.seed = run
		var zones := {}
		var cur := Vector2i.ZERO
		var entry := Vector2i.LEFT
		zones[cur] = ZoneGenerator.generate(cur, entry, zones, rng, HUB)
		for step in STEPS:
			var z: ZoneData = zones[cur]
			var open: Array[Vector2i] = []
			for d: Vector2i in z.doors:
				if z.doors[d] and cur + d != HUB:
					open.append(d)
			_check(not open.is_empty() or _has_frontier(zones), "run %d: sin salida en %s" % [run, cur])
			if open.is_empty():
				break
			var d := open[rng.randi_range(0, open.size() - 1)]
			cur += d
			if not zones.has(cur):
				zones[cur] = ZoneGenerator.generate(cur, -d, zones, rng, HUB)
		stats.zones += zones.size()

		# Coherencia: si A tiene puerta hacia B (generada), B tiene puerta hacia A.
		for c: Vector2i in zones:
			var z: ZoneData = zones[c]
			_check(z.depth == absi(c.x) + absi(c.y), "profundidad mal calculada")
			for d: Vector2i in z.doors:
				if zones.has(c + d):
					_check(z.doors[d] == (zones[c + d] as ZoneData).has_door(-d),
						"run %d: puertas incoherentes entre %s y %s" % [run, c, c + d])
			var bought := 0
			for e in z.entities:
				var entry_res: SpawnEntry = e.entry
				if z.depth < entry_res.min_depth:
					stats.iron_before_min_depth += 1
				if entry_res.cost > 0:
					bought += 1
			var b: Dictionary = stats.depth_sum_budget
			if not b.has(z.depth):
				b[z.depth] = []
			b[z.depth].append(bought)
			_check_ground(z, run)
			stats.templates[z.template] = stats.templates.get(z.template, 0) + 1
			if z.event != &"":
				stats.events[z.event] = stats.events.get(z.event, 0) + 1
		_check(zones[Vector2i.ZERO].has_door(Vector2i.LEFT), "la zona (0,0) no conecta con el hub")

	_check(stats.iron_before_min_depth == 0, "apareció una entidad antes de su min_depth")

	# El contenido debe crecer con la profundidad
	var b: Dictionary = stats.depth_sum_budget
	var prev := -1.0
	print("profundidad -> recursos/enemigos promedio (sin decoración)")
	for depth in range(0, 7):
		if not b.has(depth):
			continue
		var arr: Array = b[depth]
		var avg := 0.0
		for n: int in arr:
			avg += n
		avg /= arr.size()
		print("  %d -> %.1f" % [depth, avg])
		_check(avg >= prev - 0.5, "el contenido no escala con la profundidad (%d)" % depth)
		prev = avg

	# Hora del día: más dificultad => más presupuesto; más rareza => hierro desde el inicio
	var rng_h := RandomNumberGenerator.new()
	rng_h.seed = 99
	var day_zone := ZoneGenerator.generate(Vector2i(1, 0), Vector2i.LEFT, {}, rng_h, HUB, 1.0, 0)
	var night_zone := ZoneGenerator.generate(Vector2i(1, 0), Vector2i.LEFT, {}, rng_h, HUB, 2.0, 3)
	print("presupuesto zona prof. 1: día = %d, madrugada = %d" % [day_zone.budget, night_zone.budget])
	_check(night_zone.budget > day_zone.budget, "la hora no escala el presupuesto")
	var iron_at_night := 0
	for i in 100:
		var z := ZoneGenerator.generate(Vector2i.ZERO, Vector2i.LEFT, {}, rng_h, HUB, 2.0, 3)
		for e in z.entities:
			if (e.entry as SpawnEntry).id == &"iron_vein":
				iron_at_night += 1
	print("vetas de hierro en la zona (0,0) de madrugada, 100 tiradas: %d" % iron_at_night)
	_check(iron_at_night > 0, "la rareza por hora no habilita hierro cerca del hub")

	# ADN: la profundidad mejora la calidad promedio
	var wood: ItemData = load("res://data/items/wood.tres")
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 1
	var q0 := 0.0
	var q6 := 0.0
	for i in 500:
		q0 += DNA.generar_recurso(wood, 0, rng2).quality
		q6 += DNA.generar_recurso(wood, 6, rng2).quality
	print("calidad promedio madera: prof 0 = %.0f%%, prof 6 = %.0f%%" % [q0 / 500, q6 / 500])
	_check(q6 > q0, "la profundidad no mejora el ADN")

	# Hito 9: todas las plantillas y eventos aparecen, con frecuencias razonables
	print("plantillas: ", stats.templates)
	print("eventos: ", stats.events)
	for id: StringName in ZoneTemplates.TEMPLATES:
		_check(stats.templates.get(id, 0) > 0, "la plantilla %s nunca apareció" % id)
	for id: StringName in ZoneTemplates.EVENTS:
		_check(stats.events.get(id, 0) > 0, "el evento %s nunca apareció" % id)
	var total_events := 0
	for k in stats.events:
		total_events += stats.events[k]
	var ratio: float = float(total_events) / float(stats.zones)
	print("zonas con evento: %.0f%%" % (ratio * 100.0))
	_check(ratio > 0.05 and ratio < 0.5, "frecuencia de eventos fuera de rango (%.2f)" % ratio)

	print("zonas generadas: %d en %d runs" % [stats.zones, RUNS])
	print("RESULTADO: ", "OK" if _failures == 0 else "%d FALLAS" % _failures)
	quit(1 if _failures > 0 else 0)


## Reglas del suelo (hito 9): caminos libres, nada sobre agua/cerco, sin franjas de 1 tile,
## y desde el centro se llega caminando a todas las puertas.
func _check_ground(z: ZoneData, run: int) -> void:
	var n := ZoneGenerator.ZONE_TILES
	var Mat := TerrainTiles.Mat
	for c: Vector2i in ZoneGenerator.corridor_cells(z):
		if z.ground_at(c) != Mat.PATH:
			_check(false, "run %d: corredor sin camino en %s (%s)" % [run, c, z.coord])
			return
	var blocked := {}
	for e in z.entities:
		var entry: SpawnEntry = e.entry
		for y in entry.size.y:
			for x in entry.size.x:
				var c: Vector2i = e.tile + Vector2i(x, y)
				var g := z.ground_at(c)
				if entry.placement == &"water":
					_check(g == Mat.WATER, "run %d: nenúfar fuera del agua" % run)
				else:
					_check(g != Mat.WATER and g != Mat.HEDGE, "run %d: %s sobre agua/cerco en %s" % [run, entry.id, c])
				if entry.solid and not entry.is_enemy:
					blocked[c] = true
	for y in n:
		for x in n:
			var m := z.ground[x + y * n]
			if m == Mat.GRASS:
				continue
			var same := func(dx: int, dy: int) -> bool: return z.ground_at(Vector2i(x + dx, y + dy)) == m or (x + dx < 0 or y + dy < 0 or x + dx >= n or y + dy >= n)
			var thin: bool = (not same.call(0, -1) and not same.call(0, 1)) or (not same.call(-1, 0) and not same.call(1, 0))
			if thin:
				_check(false, "run %d: franja de 1 tile de %d en (%d,%d)" % [run, m, x, y])
				return
	# BFS desde el centro
	var start := Vector2i(n / 2, n / 2)
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var nc := c + d
			if nc.x < 0 or nc.y < 0 or nc.x >= n or nc.y >= n or seen.has(nc) or blocked.has(nc):
				continue
			var g := z.ground_at(nc)
			if g == Mat.WATER or g == Mat.HEDGE:
				continue
			seen[nc] = true
			queue.append(nc)
	for d: Vector2i in z.doors:
		if not z.doors[d]:
			continue
		var door := Vector2i(n / 2, n / 2) + d * (n / 2 - 1)
		door = door.clamp(Vector2i.ZERO, Vector2i(n - 1, n - 1))
		_check(seen.has(door), "run %d: la puerta %s de %s no se alcanza caminando" % [run, d, z.coord])


## ¿Queda alguna puerta (en cualquier zona) que lleve a una celda sin generar?
func _has_frontier(zones: Dictionary) -> bool:
	for c: Vector2i in zones:
		var z: ZoneData = zones[c]
		for d: Vector2i in z.doors:
			if z.doors[d] and not zones.has(c + d) and c + d != HUB:
				return true
	return false


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failures += 1
		if _failures <= 10:
			push_error(msg)
