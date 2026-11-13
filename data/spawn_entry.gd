class_name SpawnEntry
extends Resource
## Una fila de la tabla ponderada de generación (GDD §2).
## Las entidades con cost > 0 se compran con el presupuesto de la zona;
## las de cost = 0 son decoración y se reparten aparte.

@export var id: StringName
## Cuánto presupuesto consume aparecer.
@export var cost: int = 1
## Peso base en la tabla ponderada.
@export var weight: float = 1.0
## Peso extra por cada nivel de profundidad (hace que lo raro sea más común lejos del hub).
@export var weight_per_depth: float = 0.0
## No aparece antes de esta profundidad (distancia Manhattan al inicio del bosque).
@export var min_depth: int = 0
## true = se instancia como Enemy en vez de Harvestable (también cuesta presupuesto).
@export var is_enemy: bool = false
## Qué ítem da al recolectarse. null = decoración no recolectable.
@export var item: ItemData
## Golpes necesarios para recolectarlo (las herramientas llegarán en otro hito).
@export var hits: int = 1
@export var color: Color = Color.WHITE
## Tamaño en tiles. El sprite tiene que medir exactamente size * 16 px.
@export var size: Vector2i = Vector2i.ONE
## Sprite en el mundo (assets/sprites/world/). Si es null se dibuja un rectángulo de color.
@export var texture: Texture2D
