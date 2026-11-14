class_name Mission
extends RefCounted
## Un objetivo del tablón (GDD §6). Tipos:
## - DELIVER: entregar N ejemplares de un recurso con calidad mínima (mochila o almacén)
## - REACH_DEPTH: pisar una zona a profundidad N
## - HUNT: derrotar N enemigos (desde que apareció la misión)
## - CRAFT (hito 11): fabricar una herramienta o arma de calidad ≥ N (desde que apareció)
## - TRAIT (hito 11): entregar N recursos con un rasgo bueno
## En las de entrega el jugador elige qué ejemplares da (por defecto, los peores).
## Recompensa: una mejora permanente (GameState.apply_upgrade).

enum Kind { DELIVER, REACH_DEPTH, HUNT, CRAFT, TRAIT }

var kind: Kind
var reward: StringName  # &"weight", &"energy", &"health"
# DELIVER
var item: ItemData
var count := 0
var min_quality := 0
# REACH_DEPTH / HUNT
var target := 0
var progress := 0


func title() -> String:
	match kind:
		Kind.DELIVER:
			return "Entregar %d %s (calidad ≥ %d%%)" % [count, item.display_name, min_quality]
		Kind.REACH_DEPTH:
			return "Llegar a profundidad %d" % target
		Kind.CRAFT:
			return "Fabricar una herramienta o arma de calidad ≥ %d%%" % target
		Kind.TRAIT:
			return "Entregar %d %s con rasgo bueno ★" % [count, "recurso" if count == 1 else "recursos"]
		_:
			return "Derrotar %d enemigos" % target


func progress_text() -> String:
	if needs_items():
		return "%d/%d" % [mini(qualifying_items().size(), count), count]
	if kind == Kind.CRAFT:
		return "hecho" if progress > 0 else "pendiente"
	return "%d/%d" % [mini(progress, target), target]


func is_complete() -> bool:
	if needs_items():
		return qualifying_items().size() >= count
	if kind == Kind.CRAFT:
		return progress > 0
	return progress >= target


## Las que se cumplen entregando ítems (y por eso dejan elegir cuáles).
func needs_items() -> bool:
	return kind == Kind.DELIVER or kind == Kind.TRAIT


func accepts(it: ItemInstance) -> bool:
	match kind:
		Kind.DELIVER:
			return it.data == item and it.quality >= min_quality
		Kind.TRAIT:
			return it.is_resource() and it.traits.any(func(t: TraitData) -> bool: return not t.negative)
	return false


## Ejemplares que sirven para entregar (peor calidad primero: la selección por defecto
## entrega lo justo y se guarda lo mejor).
func qualifying_items() -> Array[ItemInstance]:
	var out: Array[ItemInstance] = []
	if not needs_items():
		return out
	for it in GameState.owned_items():
		if accepts(it):
			out.append(it)
	# Los que tienen rasgo bueno van al final: la selección por defecto no los regala
	# (salvo en la misión de rasgo, donde todos lo tienen)
	out.sort_custom(func(a: ItemInstance, b: ItemInstance) -> bool:
		var ga := _good_traits(a)
		var gb := _good_traits(b)
		if ga != gb:
			return ga < gb
		return a.quality < b.quality)
	return out


static func _good_traits(it: ItemInstance) -> int:
	return it.traits.filter(func(t: TraitData) -> bool: return not t.negative).size()


func to_dict() -> Dictionary:
	return {
		"kind": kind, "reward": String(reward),
		"item": item.resource_path if item else "",
		"count": count, "min_quality": min_quality, "target": target, "progress": progress,
	}


static func from_dict(d: Dictionary) -> Mission:
	var m := Mission.new()
	m.kind = int(d.get("kind", 0)) as Kind
	m.reward = StringName(d.get("reward", "weight"))
	var path: String = d.get("item", "")
	if path != "" and ResourceLoader.exists(path):
		m.item = load(path)
	m.count = int(d.get("count", 0))
	m.min_quality = int(d.get("min_quality", 0))
	m.target = int(d.get("target", 0))
	m.progress = int(d.get("progress", 0))
	if m.kind == Kind.DELIVER and m.item == null:
		return null
	if m.kind == Kind.TRAIT and m.count <= 0:
		m.count = 1
	return m
