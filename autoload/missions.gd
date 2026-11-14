extends Node
## Tablón de misiones (GDD §6, versión MVP sin NPC): siempre hay ACTIVE_COUNT misiones.
## Al reclamar una, se aplica su mejora permanente y aparece otra un poco más difícil.
## Hito 11: la que aparece puede ser de otro tipo (no repite los que ya están en el tablón)
## y en las de entrega se elige qué ejemplares dar.
## Escucha eventos del juego (zona nueva, enemigo derrotado) para el progreso.

signal changed

const ACTIVE_COUNT := 3
const REWARDS: Array[StringName] = [&"weight", &"energy", &"health"]
const DELIVERABLES := [
	preload("res://data/items/wood.tres"),
	preload("res://data/items/stone.tres"),
	preload("res://data/items/copper.tres"),
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


## Restaura el tablón desde el guardado. Si falta alguna, se completa con nuevas.
func load_state(p_completed: int, raw: Array) -> void:
	completed = p_completed
	active.clear()
	for d in raw:
		var m := Mission.from_dict(d)
		if m:
			active.append(m)
	while active.size() < ACTIVE_COUNT:
		active.append(generate(Mission.Kind.values()[active.size() % 3]))
	changed.emit()


## Crea una misión del tipo pedido, escalada con `completed`.
func generate(kind: Mission.Kind) -> Mission:
	var m := Mission.new()
	m.kind = kind
	m.reward = REWARDS[rng.randi_range(0, REWARDS.size() - 1)]
	var tier := completed
	match kind:
		Mission.Kind.DELIVER:
			# El cobre aparece tras un par de misiones reclamadas y el hierro más adelante
			var options := 2 + (1 if tier >= 2 else 0) + (1 if tier >= 4 else 0)
			m.item = DELIVERABLES[rng.randi_range(0, options - 1)]
			m.count = 3 + tier
			m.min_quality = mini(30 + 5 * tier, 70)
		Mission.Kind.REACH_DEPTH:
			m.target = mini(2 + tier, 10)
		Mission.Kind.HUNT:
			m.target = 2 + tier
		Mission.Kind.CRAFT:
			m.target = mini(45 + 5 * tier, 85)
		Mission.Kind.TRAIT:
			m.count = 1 if tier < 4 else 2
	return m


## Tipo de la misión que reemplaza a una reclamada: alguno que no esté ya en el tablón.
## Las de fabricar y de rasgo aparecen desde la primera misión cumplida.
func next_kind(replacing: Mission) -> Mission.Kind:
	var taken: Array = []
	for m in active:
		if m != replacing:
			taken.append(m.kind)
	var pool: Array = []
	for k: Mission.Kind in Mission.Kind.values():
		if taken.has(k):
			continue
		if (k == Mission.Kind.CRAFT or k == Mission.Kind.TRAIT) and completed < 1:
			continue
		pool.append(k)
	return pool[rng.randi_range(0, pool.size() - 1)] if not pool.is_empty() else replacing.kind


## Reclama una misión cumplida: entrega materiales (si corresponde), aplica la mejora
## y la reemplaza por una nueva. Devuelve false si no estaba cumplida.
## chosen: los ejemplares que eligió el jugador (vacío = los peores que sirvan).
func claim(m: Mission, chosen: Array = []) -> bool:
	if not active.has(m) or not m.is_complete():
		return false
	if m.needs_items():
		var give := default_choice(m)
		if is_valid_choice(m, chosen):
			give = chosen
		for it: ItemInstance in give:
			GameState.remove_owned(it)
	var text := GameState.apply_upgrade(m.reward)
	completed += 1
	var kind := next_kind(m)
	active[active.find(m)] = generate(kind)
	GameState.notify("Misión cumplida: %s" % text)
	changed.emit()
	return true


## Selección por defecto al entregar: los `count` peores que sirven.
func default_choice(m: Mission) -> Array:
	return m.qualifying_items().slice(0, m.count)


func is_valid_choice(m: Mission, chosen: Array) -> bool:
	if chosen.size() != m.count:
		return false
	var ok := m.qualifying_items()
	for it in chosen:
		if not ok.has(it) or chosen.count(it) > 1:
			return false
	return true


func ready_count() -> int:
	var n := 0
	for m in active:
		if m.is_complete():
			n += 1
	return n


# --- Eventos ---------------------------------------------------------------------

## Lo llama Crafting.craft: cuenta para "fabricar con calidad ≥ X".
func on_crafted(item: ItemInstance) -> void:
	if not item.data.is_equipment():
		return
	for m in active:
		if m.kind == Mission.Kind.CRAFT and item.quality >= m.target:
			m.progress = 1
	changed.emit()


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
