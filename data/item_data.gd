class_name ItemData
extends Resource
## Definición de un TIPO de ítem (Madera, Piedra, Hacha...). Port de ItemData.cs de BarrenRoots:
## es un asset (.tres en data/items/), no cambia en runtime. Equivale al ScriptableObject.
## Cada ejemplar concreto que el jugador recoge es un ItemInstance con sus stats rolados.

enum ItemType { RESOURCE, TOOL, WEAPON, CONSUMABLE }

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
## Ícono para inventario/almacén. Tiene que medir grid_size * 16 px.
@export var icon: Texture2D
@export var color: Color = Color.WHITE
@export var item_type: ItemType = ItemType.RESOURCE

@export_group("Inventario")
## Celdas que ocupa en la grilla de la mochila (BarrenRoots: tamanoEnGrilla).
@export var grid_size: Vector2i = Vector2i.ONE
## Stat del ADN que define el peso. Si el ítem no lo tiene, se usa base_weight.
@export var weight_stat: String = "peso"
@export var base_weight: float = 1.0

@export_group("ADN")
## nombre_del_stat -> Vector2(min, max). Se tiran al recolectar (BarrenRoots: StatRange[]).
@export var stats: Dictionary = {}
## Stats donde MENOS es mejor (ej. "peso"). El ADN favorece valores bajos con la profundidad.
@export var inverted_stats: PackedStringArray = []

@export_group("Herramienta (hito 5)")
@export var tool_type: StringName = &""
@export var tool_level: int = 0


func is_inverted(stat: String) -> bool:
	return inverted_stats.has(stat)


## El equipo (herramientas/armas) nunca se pierde al morir o colapsar (GDD §4).
func is_equipment() -> bool:
	return item_type == ItemType.TOOL or item_type == ItemType.WEAPON
