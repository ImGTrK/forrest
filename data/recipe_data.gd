class_name RecipeData
extends Resource
## Receta de crafting (port de RecipeData de BarrenRoots). Un .tres por receta en data/recipes/.
##
## Los stats del resultado salen de los stats de los MATERIALES QUE EL JUGADOR ELIGE
## (BarrenRoots: "promedio ponderado de stats relevantes"):
##   t     = promedio normalizado (0-1) de `source` en los ejemplares elegidos del ingrediente `from`
##   valor = base × lerp(min, max, t)
## Así una piedra muy dura da un pico con más poder, y una madera flexible uno que dura más.

@export var id: StringName
@export var result: ItemData
## Cada ingrediente: { "item": ItemData, "count": int }
@export var ingredients: Array = []
## Cada fórmula: { "stat": String, "base": float, "min": float, "max": float,
##                 "from": int (índice en ingredients), "source": String (stat del material) }
@export var formulas: Array = []
## Peso del resultado = suma del peso de los materiales × este factor.
@export var weight_factor: float = 0.5
## Material que consume reparar (1 ejemplar, el de peor calidad).
@export var repair_material: ItemData


func ingredient_item(i: int) -> ItemData:
	return ingredients[i]["item"]


func ingredient_count(i: int) -> int:
	return ingredients[i]["count"]
