extends SceneTree
## Test headless del generador. Correr con:
##   godot --headless --path . --script res://tests/test_generation.gd
## Simula muchos runs con caminatas aleatorias y verifica las reglas del GDD §3.

const HUB := Vector2i(-1, 0)
const RUNS := 200
const STEPS := 60

var _failures := 0


func _init() -> void:
	var stats := {"zones": 0, "depth_sum_budget": {}, "iron_before_min_depth": 0}
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
			for e in z.entities:
				var entry_res: SpawnEntry = e.entry
				if z.depth < entry_res.min_depth:
					stats.iron_before_min_depth += 1
			var b: Dictionary = stats.depth_sum_budget
			if not b.has(z.depth):
				b[z.depth] = []
			b[z.depth].append(z.entities.size())
		_check(zones[Vector2i.ZERO].has_door(Vector2i.LEFT), "la zona (0,0) no conecta con el hub")

	_check(stats.iron_before_min_depth == 0, "apareció una entidad antes de su min_depth")

	# El contenido debe crecer con la profundidad
	var b: Dictionary = stats.depth_sum_budget
	var prev := -1.0
	print("profundidad -> entidades promedio (incluye decoración)")
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
	var wood: ResourceType = load("res://data/resources/wood.tres")
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 1
	var q0 := 0.0
	var q6 := 0.0
	for i in 500:
		q0 += DNA.generar_recurso(wood, 0, rng2).quality
		q6 += DNA.generar_recurso(wood, 6, rng2).quality
	print("calidad promedio madera: prof 0 = %.0f%%, prof 6 = %.0f%%" % [q0 / 500, q6 / 500])
	_check(q6 > q0, "la profundidad no mejora el ADN")

	print("zonas generadas: %d en %d runs" % [stats.zones, RUNS])
	print("RESULTADO: ", "OK" if _failures == 0 else "%d FALLAS" % _failures)
	quit(1 if _failures > 0 else 0)


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
