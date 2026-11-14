class_name Traits
extends RefCounted
## Rasgos raros (hito 11): cuándo sale uno, cómo se aplica y cómo se hereda al fabricar.
##   - Al recolectar: chance = BASE_CHANCE + PER_DEPTH × profundidad (tope MAX_CHANCE).
##     La profundidad incluye la hora y el bonus de los eventos. Los eventos especiales
##     (árbol antiguo, veta brillante) garantizan un rasgo bueno.
##   - Al fabricar: la herramienta hereda los rasgos de los materiales elegidos, hasta
##     MAX_PER_ITEM. Los malos entran primero; después los buenos más fuertes.
##   - Reparar no los toca.

const MAX_PER_ITEM := 2
const BASE_CHANCE := 0.05
const PER_DEPTH := 0.02
const MAX_CHANCE := 0.35

const ALL: Array[TraitData] = [
	preload("res://data/traits/heartwood.tres"),
	preload("res://data/traits/light_wood.tres"),
	preload("res://data/traits/wormwood.tres"),
	preload("res://data/traits/veined_stone.tres"),
	preload("res://data/traits/river_stone.tres"),
	preload("res://data/traits/cracked_stone.tres"),
	preload("res://data/traits/red_copper.tres"),
	preload("res://data/traits/native_copper.tres"),
	preload("res://data/traits/oxidized_copper.tres"),
	preload("res://data/traits/tempered_iron.tres"),
	preload("res://data/traits/star_iron.tres"),
	preload("res://data/traits/brittle_iron.tres"),
]


static func for_material(data: ItemData) -> Array[TraitData]:
	var out: Array[TraitData] = []
	for t in ALL:
		if t.material == data:
			out.append(t)
	return out


static func chance(depth: int) -> float:
	return minf(BASE_CHANCE + PER_DEPTH * depth, MAX_CHANCE)


## Tira si sale un rasgo para este recurso. null = no salió (lo normal).
static func roll(data: ItemData, depth: int, rng: RandomNumberGenerator, guaranteed := false) -> TraitData:
	var options := for_material(data)
	if guaranteed:
		options = options.filter(func(t: TraitData) -> bool: return not t.negative)
	if options.is_empty() or (not guaranteed and rng.randf() >= chance(depth)):
		return null
	var total := 0.0
	for t in options:
		total += t.weight
	var pick := rng.randf() * total
	for t in options:
		pick -= t.weight
		if pick <= 0.0:
			return t
	return options[-1]


## Aplica los efectos de `traits` a los stats que el ítem tenga.
## skip: stats que no se tocan (al fabricar, el peso ya viene de los materiales).
static func apply(item: ItemInstance, traits: Array[TraitData], skip: PackedStringArray = []) -> void:
	for t in traits:
		for stat: String in t.effects:
			if item.stats.has(stat) and not skip.has(stat):
				var v: float = item.stats[stat] * float(t.effects[stat])
				item.stats[stat] = roundf(v) if stat == item.data.durability_stat else snappedf(v, 0.1)


## Qué rasgos pasan a la herramienta fabricada con estos materiales.
## Devuelve {"kept": Array[TraitData], "dropped": Array[TraitData]}.
## Repetidos no suman (dos maderas de corazón = un solo "Corazón de roble").
static func inherit(materials: Array[ItemInstance]) -> Dictionary:
	var unique: Array[TraitData] = []
	for m in materials:
		for t in m.traits:
			if not unique.has(t):
				unique.append(t)
	unique.sort_custom(func(a: TraitData, b: TraitData) -> bool:
		if a.negative != b.negative:
			return a.negative  # los malos primero: no se esquivan sumando buenos
		return a.strength() > b.strength())
	var kept: Array[TraitData] = []
	var dropped: Array[TraitData] = []
	for t in unique:
		if kept.size() < MAX_PER_ITEM:
			kept.append(t)
		else:
			dropped.append(t)
	return {"kept": kept, "dropped": dropped}


## Color de la marca de un ítem: rojo si tiene alguno malo, dorado si son todos buenos.
static func mark_color(item: ItemInstance) -> Color:
	for t in item.traits:
		if t.negative:
			return t.color()
	return item.traits[0].color() if not item.traits.is_empty() else Color(0, 0, 0, 0)
