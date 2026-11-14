extends Node
## Estado PERSISTENTE entre runs (vive en el hub).
## Autoload = singleton global: accesible desde cualquier script como `GameState`.
##
## - `bag`: la mochila del jugador, grilla 6×4 con límite de peso (diseño de BarrenRoots).
##   Lo que hay adentro se puede perder al morir o colapsar (salvo el equipo).
## - `storage`: el almacén del pueblo, también en grilla (para acomodar a mano), sin límite
##   de peso y que crece sola: siempre deja una fila libre abajo.
## Nada se guarda solo: el jugador decide qué deja en el almacén y qué se lleva.

signal bag_changed
signal storage_changed
## Cambió la durabilidad o el set de herramientas/armas disponibles.
signal equipment_changed
## Se prendió/apagó la linterna o cambió el aceite.
signal lantern_changed
## Cambiaron las mejoras permanentes (recompensas de misiones).
signal upgrades_changed
signal message(text: String)

## % de lo cargado que se pierde según cómo termina el run (GDD §4).
const COLLAPSE_LOSS := 0.25
const DEATH_LOSS := 0.5

# --- Mochila (BarrenRoots: grilla 6×4 + peso, debuff de sobrepeso ×0.5) ----------
const BAG_SIZE := Vector2i(6, 4)
const MAX_WEIGHT := 18.0
const OVERWEIGHT_SPEED_MULT := 0.5
const STORAGE_SIZE := Vector2i(10, 6)  # columnas fijas; las filas crecen

var bag := GridInventory.new(BAG_SIZE)
var storage := GridInventory.new(STORAGE_SIZE, true)
var runs_completed: int = 0

# --- Mejoras permanentes (recompensas del tablón, GDD §4 "meta-progresión") -------
const UPGRADE_WEIGHT := 2.0   # kg por mejora
const UPGRADE_ENERGY := 10.0  # energía máxima por mejora
const UPGRADE_HEALTH := 2     # vida por mejora (= 1 corazón)
var bonus_weight := 0.0
var bonus_energy := 0.0
var bonus_health := 0

# --- Linterna (GDD §4.1: consume aceite mientras está prendida) --------------------
const OIL_ID := &"oil"
var lantern_on := false
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	bag.changed.connect(bag_changed.emit)
	bag.changed.connect(equipment_changed.emit)
	# Diferido: Clock es un autoload que se carga después de este
	(func() -> void: Clock.time_advanced.connect(burn_oil)).call_deferred()
	storage.changed.connect(storage_changed.emit)


## Partida nueva.
func reset() -> void:
	bag.reset(BAG_SIZE)
	storage.reset(STORAGE_SIZE)
	runs_completed = 0
	bonus_weight = 0.0
	bonus_energy = 0.0
	bonus_health = 0
	lantern_on = false
	upgrades_changed.emit()
	storage_changed.emit()
	lantern_changed.emit()


func can_carry(data: ItemData) -> bool:
	return bag.has_space(data.grid_size)


## Mete un ítem recién obtenido en la mochila. Devuelve false si no hay lugar.
func pick_up(item: ItemInstance) -> bool:
	var was_overweight := is_overweight()
	if not bag.add(item):
		notify("La mochila está llena")
		return false
	if item.has_traits():
		var t: TraitData = item.traits[0]
		notify("%s %s: %s ★ %s (%s)" % ["¡Hallazgo raro!" if not t.negative else "Mmm…",
			item.display_name(), t.display_name, t.effects_text(), "calidad %d%%" % item.quality])
		AudioManager.play(&"rare" if not t.negative else &"pop")
	else:
		notify("+ %s  (calidad %d%%)" % [item.display_name(), item.quality])
	if is_overweight() and not was_overweight:
		notify("Voy muy cargado: me muevo más lento")
	return true


func carried_weight() -> float:
	return bag.total_weight()


func max_weight() -> float:
	return MAX_WEIGHT + bonus_weight


func is_overweight() -> bool:
	return carried_weight() > max_weight()


func speed_multiplier() -> float:
	return OVERWEIGHT_SPEED_MULT if is_overweight() else 1.0


## Mochila -> almacén (en el primer lugar libre).
func deposit(item: ItemInstance) -> bool:
	return _transfer(item, bag, storage)


## Almacén -> mochila (si hay lugar).
func withdraw(item: ItemInstance) -> bool:
	return _transfer(item, storage, bag)


## Mueve un ítem de una grilla a la otra. Si no entra, queda donde estaba.
func _transfer(item: ItemInstance, from: GridInventory, to: GridInventory) -> bool:
	if not from.has(item):
		return false
	var old_pos := from.position_of(item)
	var old_rot := item.rotated
	from.remove(item)
	if to.add(item):
		return true
	item.rotated = old_rot
	from.add_at(item, old_pos)
	notify("No hay lugar en la mochila" if to == bag else "No hay lugar en el almacén")
	return false


## Atajo del cofre: guarda todos los recursos de la mochila. El equipo se queda encima.
func deposit_resources() -> int:
	var moved := 0
	for item in bag.items():
		if item.is_resource() and deposit(item):
			moved += 1
	return moved


## Tirar un ítem (desaparece).
func discard(item: ItemInstance) -> void:
	notify("Tiraste %s (calidad %d%%)" % [item.display_name(), item.quality])


## Fin de un run (volver, colapsar o morir). Lo cargado se queda en la mochila:
## guardarlo en el almacén es decisión del jugador.
func end_run() -> void:
	runs_completed += 1


# --- Herramientas y armas -----------------------------------------------------
# No hay slots de equipo: se usa automáticamente la mejor herramienta/arma que esté
# en la MOCHILA (no rota). Llevarla cuesta lugar y peso: es parte de la decisión.

## Mejor herramienta del tipo (&"axe", &"pickaxe") en la mochila: mayor nivel, después más poder.
func best_tool(tool_type: StringName) -> ItemInstance:
	if tool_type == &"":
		return null
	return _best_in(bag.items(), func(it: ItemInstance) -> bool:
		return it.data.item_type == ItemData.ItemType.TOOL and it.data.tool_type == tool_type)


func best_weapon() -> ItemInstance:
	return _best_in(bag.items(), func(it: ItemInstance) -> bool:
		return it.data.item_type == ItemData.ItemType.WEAPON)


## Igual que best_tool pero mirando también el almacén (para comparar en el crafting).
func best_owned_like(data: ItemData) -> ItemInstance:
	return _best_in(owned_items(), func(it: ItemInstance) -> bool:
		return it.data.item_type == data.item_type and it.data.tool_type == data.tool_type)


func _best_in(items: Array[ItemInstance], filter: Callable) -> ItemInstance:
	var best: ItemInstance = null
	for it in items:
		if it.is_broken or not filter.call(it):
			continue
		if best == null or it.data.tool_level > best.data.tool_level 				or (it.data.tool_level == best.data.tool_level and it.power() > best.power()):
			best = it
	return best


## Gasta durabilidad de una herramienta/arma y avisa si se rompió.
func wear(item: ItemInstance, amount: float = 1.0) -> void:
	if item == null:
		return
	if item.wear(amount):
		notify("¡Se rompió %s! Repará en la mesa del pueblo" % item.display_name())
	equipment_changed.emit()


## Todo lo que el jugador tiene (mochila + almacén), para el crafting en el pueblo.
func owned_items() -> Array[ItemInstance]:
	var all := bag.items()
	all.append_array(storage.items())
	return all


## Saca un ítem de donde esté (mochila o almacén).
func remove_owned(item: ItemInstance) -> bool:
	return bag.remove(item) or storage.remove(item)


## Ítem nuevo (crafteado): a la mochila; si no entra, al almacén.
func receive(item: ItemInstance) -> String:
	if bag.add(item):
		return "mochila"
	storage.add(item)
	return "almacén"


# --- Linterna y aceite ---------------------------------------------------------

func lantern() -> ItemInstance:
	return best_tool(&"light")


func oil_items() -> Array[ItemInstance]:
	var out: Array[ItemInstance] = []
	for it in bag.items():
		if it.data.id == OIL_ID and it.durability > 0.0:
			out.append(it)
	return out


## Minutos de luz que quedan en el aceite de la mochila.
func oil_minutes() -> float:
	var total := 0.0
	for it in oil_items():
		total += it.durability
	return total


## Radio de visión que da la linterna prendida (0 si está apagada).
func light_radius() -> float:
	var l := lantern()
	return l.stats.get("radio", 0.0) if lantern_on and l else 0.0


func toggle_lantern() -> bool:
	if lantern_on:
		set_lantern(false)
		return false
	if lantern() == null:
		notify("No tengo linterna (se fabrica en la mesa)")
		return false
	if oil_minutes() <= 0.0:
		notify("No tengo aceite para la linterna")
		return false
	set_lantern(true)
	return true


func set_lantern(on: bool) -> void:
	if on == lantern_on:
		return
	lantern_on = on
	lantern_changed.emit()


## Quema aceite con el reloj (se llama con los minutos que pasan). Se gasta primero
## el frasco más vacío; los que se agotan desaparecen.
func burn_oil(minutes: float) -> void:
	if not lantern_on:
		return
	if lantern() == null:
		set_lantern(false)
		return
	var left := minutes
	while left > 0.0:
		var oils := oil_items()
		if oils.is_empty():
			set_lantern(false)
			notify("Se acabó el aceite: la linterna se apagó")
			return
		oils.sort_custom(func(a: ItemInstance, b: ItemInstance) -> bool: return a.durability < b.durability)
		var oil := oils[0]
		var used := minf(left, oil.durability)
		oil.durability -= used
		left -= used
		if oil.durability <= 0.0:
			bag.remove(oil)
	lantern_changed.emit()


# --- Mejoras permanentes -------------------------------------------------------

## kind: &"weight", &"energy" o &"health".
func apply_upgrade(kind: StringName) -> String:
	match kind:
		&"weight":
			bonus_weight += UPGRADE_WEIGHT
		&"energy":
			bonus_energy += UPGRADE_ENERGY
		&"health":
			bonus_health += UPGRADE_HEALTH
	upgrades_changed.emit()
	return upgrade_text(kind)


static func upgrade_text(kind: StringName) -> String:
	match kind:
		&"weight":
			return "+%d kg de capacidad" % UPGRADE_WEIGHT
		&"energy":
			return "+%d de energía máxima" % UPGRADE_ENERGY
		&"health":
			return "+1 corazón"
	return "?"


## Colapso / muerte: pierde una fracción al azar de lo cargado. El equipo nunca se pierde.
func lose_run_fraction(fraction: float, p_rng: RandomNumberGenerator) -> int:
	var losable: Array[ItemInstance] = []
	for item in bag.items():
		if not item.data.is_equipment():
			losable.append(item)
	var to_lose := floori(losable.size() * clampf(fraction, 0.0, 1.0))
	for i in to_lose:
		var item: ItemInstance = losable.pop_at(p_rng.randi_range(0, losable.size() - 1))
		bag.remove(item)
	return to_lose


func notify(text: String) -> void:
	message.emit(text)
