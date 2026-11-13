class_name DNA
extends RefCounted
## ADN de recursos (heredado de BarrenRoots, GDD §2 y §5.1).
## Al recolectar, cada stat se tira al azar dentro del rango del ItemData.
## La profundidad mejora la tirada: se tira "el mejor de N", con N = 1 + profundidad/3 (máx. 3).
## "Mejor" = más alto, salvo en stats invertidos (ej. peso), donde mejor = más bajo.


static func generar_recurso(tipo: ItemData, depth: int, rng: RandomNumberGenerator) -> ItemInstance:
	var rolls := clampi(1 + floori(depth / 3.0), 1, 3)
	var item := ItemInstance.new(tipo)
	var quality_sum := 0.0
	for stat_name: String in tipo.stats:
		var r: Vector2 = tipo.stats[stat_name]
		var inverted := tipo.is_inverted(stat_name)
		var best := r.y if inverted else r.x
		for i in rolls:
			var roll := rng.randf_range(r.x, r.y)
			best = minf(best, roll) if inverted else maxf(best, roll)
		item.stats[stat_name] = snappedf(best, 0.1)
		var normalized := inverse_lerp(r.x, r.y, best)
		quality_sum += (1.0 - normalized) if inverted else normalized
	item.quality = roundi(100.0 * quality_sum / maxi(tipo.stats.size(), 1))
	item.depth = depth
	return item
