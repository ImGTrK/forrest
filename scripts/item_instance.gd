class_name ItemInstance
extends RefCounted
## Un ejemplar concreto con sus stats rolados (port de ItemInstance.cs de BarrenRoots).
## Se crea al recolectar (DNA.generar_recurso) y nunca es un asset.

var data: ItemData
var stats: Dictionary = {}  # nombre -> float
## 0-100: qué tan buenos salieron los stats dentro de sus rangos.
var quality: int = 0
## Profundidad efectiva (distancia + hora) a la que se obtuvo.
var depth: int = 0
## Rotado 90° en la grilla (un 1x2 pasa a ocupar 2x1).
var rotated: bool = false
## Durabilidad actual (herramientas y armas). La máxima es el stat "durabilidad".
var durability: float = 0.0
var is_broken: bool = false


func _init(p_data: ItemData = null) -> void:
	data = p_data


func display_name() -> String:
	return data.display_name


## Tamaño en la grilla según la orientación actual.
func grid_size() -> Vector2i:
	var s := data.grid_size
	return Vector2i(s.y, s.x) if rotated else s


func can_rotate() -> bool:
	return data.grid_size.x != data.grid_size.y


func weight() -> float:
	if data.weight_stat != "" and stats.has(data.weight_stat):
		return stats[data.weight_stat]
	return data.base_weight


func is_resource() -> bool:
	return data.item_type == ItemData.ItemType.RESOURCE


# --- Herramientas y armas (port de "Durabilidad" de BarrenRoots) ---------------

## Poder de golpe (herramientas) o daño (armas).
func power() -> float:
	return stats.get("poder", 0.0)


func max_durability() -> float:
	return stats.get("durabilidad", 0.0)


func has_durability() -> bool:
	return max_durability() > 0.0


func durability_ratio() -> float:
	return durability / max_durability() if has_durability() else 1.0


## Buena (>60%) · Desgastada (20-60%) · Rota (0%). Igual que BarrenRoots.
func condition() -> String:
	if is_broken:
		return "Rota"
	return "Buena" if durability_ratio() > 0.6 else "Desgastada"


func condition_color() -> Color:
	if is_broken:
		return Color(0.95, 0.3, 0.25)
	return Color(0.45, 0.85, 0.35) if durability_ratio() > 0.6 else Color(0.95, 0.8, 0.25)


## Gasta durabilidad. Devuelve true si se acaba de romper.
func wear(amount: float = 1.0) -> bool:
	if not has_durability() or is_broken:
		return false
	durability = maxf(durability - amount, 0.0)
	if durability <= 0.0:
		is_broken = true
		return true
	return false


func repair_full() -> void:
	durability = max_durability()
	is_broken = false


## Texto del tooltip.
func describe() -> String:
	var lines: PackedStringArray = ["%s  ·  calidad %d%%" % [data.display_name, quality]]
	if data.tool_level > 0:
		lines.append("  nivel %d" % data.tool_level)
	if has_durability():
		lines.append("  estado: %s (%d/%d)" % [condition(), ceili(durability), roundi(max_durability())])
	for stat: String in stats:
		if stat == "durabilidad":
			continue
		var unit := " kg" if stat == data.weight_stat else ""
		var hint := "  (menos es mejor)" if data.is_inverted(stat) else ""
		lines.append("  %s %.1f%s%s" % [stat, stats[stat], unit, hint])
	if not stats.has(data.weight_stat):
		lines.append("  peso %.1f kg" % weight())
	if not has_durability():
		lines.append("  profundidad %d" % depth)
	return "\n".join(lines)
