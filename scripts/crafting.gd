class_name Crafting
extends RefCounted
## Lógica de crafting y reparación (port de "Sistema de Crafting" de BarrenRoots).
## - preview() y craft() usan la MISMA fórmula; preview no consume nada.
## - craft() es destructivo e irreversible.
## - La selección es { índice_de_ingrediente: Array[ItemInstance] } con los ejemplares elegidos.
## Lógica pura: la UI (CraftingUI) solo arma la selección y muestra el resultado.

const RECIPES := [
	preload("res://data/recipes/stone_axe.tres"),
	preload("res://data/recipes/stone_pickaxe.tres"),
	preload("res://data/recipes/wood_sword.tres"),
	preload("res://data/recipes/iron_axe.tres"),
	preload("res://data/recipes/iron_pickaxe.tres"),
	preload("res://data/recipes/iron_sword.tres"),
]


## Ejemplares que sirven para el ingrediente `i` (mochila + almacén), mejor calidad primero.
static func candidates(recipe: RecipeData, i: int, owned: Array[ItemInstance]) -> Array[ItemInstance]:
	var data := recipe.ingredient_item(i)
	var out: Array[ItemInstance] = []
	for it in owned:
		if it.data == data:
			out.append(it)
	out.sort_custom(func(a: ItemInstance, b: ItemInstance) -> bool: return a.quality > b.quality)
	return out


## Selección por defecto: los mejores ejemplares de cada ingrediente.
static func auto_select(recipe: RecipeData, owned: Array[ItemInstance]) -> Dictionary:
	var sel := {}
	for i in recipe.ingredients.size():
		var c := candidates(recipe, i, owned)
		sel[i] = c.slice(0, recipe.ingredient_count(i))
	return sel


static func is_complete(recipe: RecipeData, selection: Dictionary) -> bool:
	for i in recipe.ingredients.size():
		if not selection.has(i) or selection[i].size() != recipe.ingredient_count(i):
			return false
	return true


## Resultado que daría la selección, sin consumir nada. null si la selección está incompleta.
static func preview(recipe: RecipeData, selection: Dictionary) -> ItemInstance:
	if not is_complete(recipe, selection):
		return null
	var item := ItemInstance.new(recipe.result)
	var quality_sum := 0.0
	for f: Dictionary in recipe.formulas:
		var t := _avg_normalized(recipe.ingredient_item(f.from), selection[f.from], f.source)
		var value: float = f.base * lerpf(f.min, f.max, t)
		item.stats[f.stat] = roundf(value) if f.stat == "durabilidad" else snappedf(value, 0.1)
		quality_sum += t
	var weight := 0.0
	for i in recipe.ingredients.size():
		for m: ItemInstance in selection[i]:
			weight += m.weight()
	item.stats["peso"] = snappedf(weight * recipe.weight_factor, 0.1)
	item.quality = roundi(100.0 * quality_sum / maxi(recipe.formulas.size(), 1))
	item.repair_full()
	return item


## Craftea: consume los materiales elegidos y entrega el resultado (mochila o almacén).
static func craft(recipe: RecipeData, selection: Dictionary) -> ItemInstance:
	var item := preview(recipe, selection)
	if item == null:
		return null
	for i in recipe.ingredients.size():
		for m: ItemInstance in selection[i]:
			GameState.remove_owned(m)
	var where := GameState.receive(item)
	GameState.notify("Fabricaste %s (calidad %d%%) · está en %s" % [item.display_name(), item.quality, where])
	return item


# --- Reparación ----------------------------------------------------------------

static func recipe_for(data: ItemData) -> RecipeData:
	for r: RecipeData in RECIPES:
		if r.result == data:
			return r
	return null


static func needs_repair(item: ItemInstance) -> bool:
	return item.has_durability() and item.durability < item.max_durability()


## Ejemplar que se gastaría para reparar (el de peor calidad). null si no hay.
static func repair_material_for(item: ItemInstance, owned: Array[ItemInstance]) -> ItemInstance:
	var recipe := recipe_for(item.data)
	if recipe == null or recipe.repair_material == null:
		return null
	var worst: ItemInstance = null
	for it in owned:
		if it.data == recipe.repair_material and (worst == null or it.quality < worst.quality):
			worst = it
	return worst


static func repair(item: ItemInstance) -> bool:
	if not needs_repair(item):
		return false
	var material := repair_material_for(item, GameState.owned_items())
	if material == null:
		GameState.notify("Falta material para reparar")
		return false
	GameState.remove_owned(material)
	item.repair_full()
	GameState.equipment_changed.emit()
	GameState.notify("Reparaste %s (usaste 1 %s)" % [item.display_name(), material.display_name()])
	return true


static func _avg_normalized(data: ItemData, mats: Array, stat: String) -> float:
	if mats.is_empty() or not data.stats.has(stat):
		return 0.5
	var r: Vector2 = data.stats[stat]
	var total := 0.0
	for m: ItemInstance in mats:
		var t := inverse_lerp(r.x, r.y, m.stats.get(stat, r.x))
		total += (1.0 - t) if data.is_inverted(stat) else t
	return clampf(total / mats.size(), 0.0, 1.0)
