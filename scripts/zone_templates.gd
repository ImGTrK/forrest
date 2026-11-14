class_name ZoneTemplates
extends RefCounted
## Plantillas de zona (hito 9): le dan personalidad a cada zona del bosque.
## Cada una dice qué "manchas" de suelo tiene, cómo cambia la tabla de spawns y qué decoración
## reparte en grupos. Se elige una por zona, con peso según la profundidad.
##
## Para sumar una plantilla: agregar una entrada acá (no hace falta tocar el generador,
## salvo que necesite un tipo de mancha nuevo en `features`).
##
## Campos:
##   weight / weight_per_depth  peso en el sorteo (lo raro se vuelve más común al profundizar)
##   min_depth                  no aparece antes de esta profundidad efectiva
##   features                   manchas de suelo: [tipo, cantidad]. Tipos: dark, clearing, pond, ruins
##   spawn_mult                 multiplica el peso de cada SpawnEntry por id (árboles, rocas…)
##   deco                       [id de decoración, grupos, ítems por grupo (min, max), (opcional) &"ruin"
##                              = los grupos arrancan sobre o al lado de las losas de ruina]
##   event_mult                 multiplica la chance de evento raro
##   event_bias                 multiplica el peso de un evento en particular

const TEMPLATES := {
	&"bosque": {
		"weight": 4.0, "weight_per_depth": -0.25, "min_depth": 0,
		"features": [[&"dark", 2]],
		"spawn_mult": {},
		"deco": [[&"deco_flowers", 3, Vector2i(2, 4)], [&"deco_tall_grass", 2, Vector2i(2, 4)],
			[&"bush", 3, Vector2i(1, 3)], [&"deco_mushrooms", 1, Vector2i(1, 2)], [&"deco_stump", 1, Vector2i(1, 1)]],
		"event_mult": 1.0, "event_bias": {},
	},
	&"claro": {
		"weight": 2.0, "weight_per_depth": 0.0, "min_depth": 0,
		"features": [[&"clearing", 1]],
		"spawn_mult": {&"tree": 0.4, &"rock": 0.8, &"enemy_charger": 1.5},
		"deco": [[&"deco_flowers", 5, Vector2i(2, 5)], [&"deco_tall_grass", 2, Vector2i(2, 3)],
			[&"deco_stump", 2, Vector2i(1, 1)], [&"bush", 2, Vector2i(1, 2)]],
		"event_mult": 0.8, "event_bias": {&"camp": 2.0},
	},
	&"arboleda": {
		"weight": 2.0, "weight_per_depth": 0.1, "min_depth": 0,
		"features": [[&"dark", 4]],
		"spawn_mult": {&"tree": 2.5, &"rock": 0.4, &"enemy_spitter": 1.4, &"enemy_charger": 0.6},
		"deco": [[&"deco_mushrooms", 3, Vector2i(1, 3)], [&"deco_log", 2, Vector2i(1, 1)],
			[&"bush", 3, Vector2i(2, 3)], [&"deco_tall_grass", 2, Vector2i(2, 3)]],
		"event_mult": 1.0, "event_bias": {&"ancient_tree": 3.0},
	},
	&"estanque": {
		"weight": 1.5, "weight_per_depth": 0.0, "min_depth": 0,
		"features": [[&"pond", 1], [&"dark", 1]],
		"spawn_mult": {&"tree": 0.8, &"enemy_spitter": 1.6},
		"deco": [[&"deco_lilypad", 2, Vector2i(2, 3)], [&"deco_tall_grass", 3, Vector2i(2, 4)],
			[&"deco_flowers", 2, Vector2i(2, 3)], [&"bush", 1, Vector2i(1, 2)]],
		"event_mult": 0.8, "event_bias": {},
	},
	&"ruinas": {
		"weight": 0.5, "weight_per_depth": 0.2, "min_depth": 1,
		"features": [[&"ruins", 1]],
		"spawn_mult": {&"tree": 0.6, &"rock": 1.4},
		"deco": [[&"deco_ruin_pillar", 3, Vector2i(1, 2), &"ruin"], [&"deco_ruin_wall", 2, Vector2i(1, 1), &"ruin"],
			[&"deco_tall_grass", 2, Vector2i(2, 3)], [&"deco_flowers", 1, Vector2i(1, 3)]],
		"event_mult": 2.0, "event_bias": {&"lost_chest": 3.0},
	},
	&"pedregal": {
		"weight": 0.5, "weight_per_depth": 0.25, "min_depth": 1,
		"features": [[&"clearing", 1]],
		"spawn_mult": {&"rock": 2.2, &"copper_vein": 2.0, &"iron_vein": 2.0, &"tree": 0.5, &"enemy_charger": 1.8},
		"deco": [[&"deco_boulder", 3, Vector2i(1, 1)], [&"bush", 1, Vector2i(1, 2)],
			[&"deco_tall_grass", 1, Vector2i(2, 3)]],
		"event_mult": 1.2, "event_bias": {&"shiny_vein": 3.0},
	},
}

## Eventos raros: peso base y profundidad efectiva mínima.
const EVENTS := {
	&"ancient_tree": {"weight": 1.0, "min_depth": 0},
	&"lost_chest": {"weight": 1.0, "min_depth": 0},
	&"shiny_vein": {"weight": 0.8, "min_depth": 1},
	&"camp": {"weight": 0.8, "min_depth": 1},
}
## Chance de evento por zona: base + por profundidad efectiva, con tope.
const EVENT_CHANCE := 0.10
const EVENT_CHANCE_PER_DEPTH := 0.03
const EVENT_CHANCE_MAX := 0.45


static func pick(depth: int, rng: RandomNumberGenerator) -> StringName:
	var ids: Array[StringName] = []
	var weights: Array[float] = []
	for id: StringName in TEMPLATES:
		var t: Dictionary = TEMPLATES[id]
		if depth < int(t.min_depth):
			continue
		ids.append(id)
		weights.append(maxf(0.1, float(t.weight) + float(t.weight_per_depth) * depth))
	return ids[_pick_index(weights, rng)]


static func pick_event(template: StringName, depth: int, rng: RandomNumberGenerator) -> StringName:
	var t: Dictionary = TEMPLATES[template]
	var chance := minf(EVENT_CHANCE + EVENT_CHANCE_PER_DEPTH * depth, EVENT_CHANCE_MAX) * float(t.event_mult)
	if rng.randf() >= chance:
		return &""
	var ids: Array[StringName] = []
	var weights: Array[float] = []
	for id: StringName in EVENTS:
		if depth < int(EVENTS[id].min_depth):
			continue
		ids.append(id)
		weights.append(float(EVENTS[id].weight) * float(t.event_bias.get(id, 1.0)))
	if ids.is_empty():
		return &""
	return ids[_pick_index(weights, rng)]


static func _pick_index(weights: Array[float], rng: RandomNumberGenerator) -> int:
	var total := 0.0
	for w in weights:
		total += w
	var r := rng.randf() * total
	for i in weights.size():
		r -= weights[i]
		if r <= 0.0:
			return i
	return weights.size() - 1
