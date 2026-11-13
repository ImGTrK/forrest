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
# Hito 5: durabilidad para herramientas
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


## Texto del tooltip.
func describe() -> String:
	var lines: PackedStringArray = ["%s  ·  calidad %d%%" % [data.display_name, quality]]
	for stat: String in stats:
		var unit := " kg" if stat == data.weight_stat else ""
		var hint := "  (menos es mejor)" if data.is_inverted(stat) else ""
		lines.append("  %s %.1f%s%s" % [stat, stats[stat], unit, hint])
	if not stats.has(data.weight_stat):
		lines.append("  peso %.1f kg" % weight())
	lines.append("  profundidad %d" % depth)
	return "\n".join(lines)
