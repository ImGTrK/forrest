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
## Script del enemigo (hijo de Enemy, ej. enemy_basic.gd). Vacío = EnemyBasic.
@export var enemy_script: Script
## Qué ítem da al recolectarse. null = decoración no recolectable.
@export var item: ItemData
## Dureza: "vida" del recurso. Cada golpe resta el poder de la herramienta
## (o Harvestable.HAND_POWER a mano). Golpes = ceil(dureza / poder).
@export var hardness: float = 1.0
## Herramienta que sirve para este recurso (&"axe", &"pickaxe"). Vacío = ninguna.
@export var tool_type: StringName = &""
## 0 = se puede a mano (lento). >0 = exige una herramienta de ese nivel.
@export var min_tool_level: int = 0
@export var color: Color = Color.WHITE
## Tamaño en tiles. El sprite tiene que medir exactamente size * 16 px.
@export var size: Vector2i = Vector2i.ONE
## Sprite en el mundo (assets/sprites/world/). Si es null se dibuja un rectángulo de color.
@export var texture: Texture2D
## false = se puede pisar (flores, pasto alto, nenúfares). Solo decoración.
@export var solid: bool = true
## > 0: la textura es una tira de frames que se anima a estos fps (fogata, veta brillante).
## = 0: si la tira tiene varios frames son variantes y se elige uno por posición.
@export var anim_fps: float = 0.0
## Profundidad extra para el ADN de lo que suelta (eventos raros: mejor calidad).
@export var loot_bonus: int = 0
## Hito 11: lo que suelta trae un rasgo bueno seguro (árbol antiguo, veta brillante).
@export var guaranteed_trait: bool = false
## Cuántos ejemplares suelta al romperse.
@export var drop_count: int = 1
## Script especial para entidades que no son recursos comunes (ej. cofre perdido).
## Vacío = Harvestable.
@export var entity_script: Script
## Dónde se puede colocar: &"" en pasto · &"water" sobre el agua (nenúfares).
@export var placement: StringName = &""
