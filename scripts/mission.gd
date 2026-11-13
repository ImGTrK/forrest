class_name Mission
extends RefCounted
## Un objetivo del tablón (GDD §6). Tres tipos:
## - DELIVER: entregar N ejemplares de un recurso con calidad mínima (mochila o almacén)
## - REACH_DEPTH: pisar una zona a profundidad N
## - HUNT: derrotar N enemigos (desde que apareció la misión)
## Recompensa: una mejora permanente (GameState.apply_upgrade).

enum Kind { DELIVER, REACH_DEPTH, HUNT }

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
		_:
			return "Derrotar %d enemigos" % target


func progress_text() -> String:
	if kind == Kind.DELIVER:
		return "%d/%d" % [mini(qualifying_items().size(), count), count]
	return "%d/%d" % [mini(progress, target), target]


func is_complete() -> bool:
	if kind == Kind.DELIVER:
		return qualifying_items().size() >= count
	return progress >= target


## Ejemplares que sirven para entregar (peor calidad primero: se entrega lo justo).
func qualifying_items() -> Array[ItemInstance]:
	var out: Array[ItemInstance] = []
	if kind != Kind.DELIVER:
		return out
	for it in GameState.owned_items():
		if it.data == item and it.quality >= min_quality:
			out.append(it)
	out.sort_custom(func(a: ItemInstance, b: ItemInstance) -> bool: return a.quality < b.quality)
	return out
