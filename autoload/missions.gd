extends Node
## Tablón de misiones (GDD §6, versión MVP sin NPC): siempre hay ACTIVE_COUNT misiones.
## Al reclamar una, se aplica su mejora permanente y aparece otra un poco más difícil.
## Escucha eventos del juego (zona nueva, enemigo derrotado) para el progreso.

signal changed

const ACTIVE_COUNT := 3
const REWARDS: Array[StringName] = [&"weight", &"energy", &"health"]
const DELIVERABLES := [
	preload("res://data/items/wood.tres"),
	preload("res://data/items/stone.tres"),
	preload("res://data/items/iron.tres"),
]

var active: Array[Mission] = []
## Misiones reclamadas en total: sube la dificultad de las nuevas.
var completed := 0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	ForestSession.zone_entered.connect(_on_zone_entered)
	reset()


## Tablón nuevo (al empezar partida o en tests).
func reset() -> void:
	active.clear()
	completed = 0
	for i in ACTIVE_COUNT:
		active.append(generate(Mission.Kind.values()[i % 3]))
	changed.emit()


## Crea una misión del tipo pedido, escalada con `completed`.
func generate(kind: Mission.Kind) -> Mission:
	var m := Mission.new()
	m.kind = kind
	m.reward = REWARDS[rng.randi_range(0, REWARDS.size() - 1)]
	var tier := completed
	match kind:
		Mission.Kind.DELIVER:
			# El hierro aparece cuando ya se reclamaron un par de misiones
			var options := 3 if tier >= 2 else 2
			m.item = DELIVERABLES[rng.randi_range(0, options - 1)]
			m.count = 3 + tier
			m.min_quality = mini(30 + 5 * tier, 70)
		Mission.Kind.REACH_DEPTH:
			m.target = mini(2 + tier, 10)
		Mission.Kind.HUNT:
			m.target = 2 + tier
	return m


## Reclama una misión cumplida: entrega materiales (si corresponde), aplica la mejora
## y la reemplaza por una nueva del mismo tipo. Devuelve false si no estaba cumplida.
func claim(m: Mission) -> bool:
	if not active.has(m) or not m.is_complete():
		return false
	if m.kind == Mission.Kind.DELIVER:
		var items := m.qualifying_items()
		for i in m.count:
			GameState.remove_owned(items[i])
	var text := GameState.apply_upgrade(m.reward)
	completed += 1
	active[active.find(m)] = generate(m.kind)
	GameState.notify("Misión cumplida: %s" % text)
	changed.emit()
	return true


func ready_count() -> int:
	var n := 0
	for m in active:
		if m.is_complete():
			n += 1
	return n


# --- Eventos ---------------------------------------------------------------------

func on_enemy_killed() -> void:
	for m in active:
		if m.kind == Mission.Kind.HUNT:
			m.progress += 1
	changed.emit()


func _on_zone_entered(coord: Vector2i) -> void:
	var depth := absi(coord.x) + absi(coord.y)
	for m in active:
		if m.kind == Mission.Kind.REACH_DEPTH:
			m.progress = maxi(m.progress, depth)
	changed.emit()
