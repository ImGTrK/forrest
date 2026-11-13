class_name DNA
extends RefCounted
## ADN de recursos (heredado de BarrenRoots, GDD §2 y §5.1).
## Al recolectar, cada stat se tira al azar dentro del rango del ResourceType.
## La profundidad mejora la tirada: se tira "el mejor de N", con N = 1 + profundidad/3 (máx. 3).
## Así lo lejano da mejores rolls sin tocar los rangos.


static func generar_recurso(tipo: ResourceType, depth: int, rng: RandomNumberGenerator) -> Dictionary:
	var rolls := clampi(1 + floori(depth / 3.0), 1, 3)
	var stats := {}
	var quality_sum := 0.0
	for stat_name: String in tipo.stats:
		var r: Vector2 = tipo.stats[stat_name]
		var best := r.x
		for i in rolls:
			best = maxf(best, rng.randf_range(r.x, r.y))
		stats[stat_name] = snappedf(best, 0.1)
		quality_sum += inverse_lerp(r.x, r.y, best)
	var quality := roundi(100.0 * quality_sum / maxi(tipo.stats.size(), 1))
	return {
		"type": tipo.id,
		"name": tipo.display_name,
		"stats": stats,
		"quality": quality,
		"depth": depth,
	}
