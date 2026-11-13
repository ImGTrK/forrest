extends TestSuite
## Herramientas, durabilidad, crafting, reparación y la UI de la mesa.


func run() -> void:
	var gs: Node = GameState
	var bag: GridInventory = gs.bag
	var p := player()
	var vein_entry := spawn_entry("iron_vein")
	var axe_recipe := recipe("stone_axe")
	var pick_recipe := recipe("stone_pickaxe")
	var sword_recipe := recipe("iron_sword")

	# A mano: el árbol se puede, lento. La veta de hierro no.
	var tree_node := spawn_harvestable(spawn_entry("tree"))
	check(tree_node.hits_left() == 4, "a mano: árbol en 4 golpes (%d)" % tree_node.hits_left())
	var vein := spawn_harvestable(vein_entry)
	var e_vein: float = Energy.value
	vein.interact(p)
	check(vein._hp == vein_entry.hardness and Energy.value >= e_vein - 0.01,
		"sin pico: la veta de hierro no se puede (ni gasta energía)")

	# Materiales en mochila y almacén; auto-selección = los de mejor calidad
	for i in 3:
		bag.add(roll("wood"))
	for i in 4:
		gs.storage.add(roll("wood"))
	for i in 6:
		gs.storage.add(roll("stone", i))
	var owned: Array[ItemInstance] = gs.owned_items()
	var sel := Crafting.auto_select(axe_recipe, owned)
	var best_wood: int = Crafting.candidates(axe_recipe, 0, owned)[0].quality
	check(Crafting.is_complete(axe_recipe, sel) and sel[0][0].quality == best_wood,
		"auto-selección: los mejores materiales")
	check(Crafting.preview(axe_recipe, {0: sel[0], 1: []}) == null, "selección incompleta: sin resultado")
	var prev := Crafting.preview(axe_recipe, sel)
	check(prev.power() >= 2.1 and prev.power() <= 3.9 and prev.max_durability() >= 24.0
		and prev.durability == prev.max_durability(), "preview: stats dentro de los rangos de la receta")
	var owned_before: int = gs.owned_items().size()
	var axe_item := Crafting.craft(axe_recipe, sel)
	check(axe_item != null and gs.owned_items().size() == owned_before - 4 + 1 and bag.has(axe_item),
		"craftear consume 4 materiales y el hacha va a la mochila")
	check(is_equal_approx(axe_item.power(), prev.power()), "el resultado coincide con la vista previa")

	# Mejores materiales = mejor herramienta
	var hard_stones: Array[ItemInstance] = []
	var soft_stones: Array[ItemInstance] = []
	for i in 2:
		var h := roll("stone")
		h.stats["dureza"] = 12.0
		hard_stones.append(h)
		var s2 := roll("stone")
		s2.stats["dureza"] = 2.0
		soft_stones.append(s2)
	var two_wood: Array = sel[0]
	check(Crafting.preview(axe_recipe, {0: two_wood, 1: hard_stones}).power()
		> Crafting.preview(axe_recipe, {0: two_wood, 1: soft_stones}).power(),
		"piedra más dura = hacha con más poder")

	# Con hacha: menos golpes y gasta durabilidad
	check(gs.best_tool(&"axe") == axe_item, "el hacha de la mochila se usa sola")
	var hits_axe := tree_node.hits_left()
	check(hits_axe < 4, "con hacha: menos golpes (%d)" % hits_axe)
	var dur0 := axe_item.durability
	tree_node.interact(p)
	check(axe_item.durability == dur0 - 1, "cada golpe gasta 1 de durabilidad")

	# Pico: habilita la veta de hierro
	var pick_item := Crafting.craft(pick_recipe, Crafting.auto_select(pick_recipe, gs.owned_items()))
	check(pick_item != null and pick_item.data.tool_level == 1, "pico de piedra fabricado (nivel 1)")
	vein.interact(p)
	check(vein._hp < vein_entry.hardness, "con pico: la veta de hierro se puede picar")

	# Romper y reparar
	axe_item.durability = 1
	tree_node.interact(p)
	check(axe_item.is_broken and gs.best_tool(&"axe") == null, "hacha rota: deja de usarse")
	check(tree_node.hits_left() == ceili(tree_node._hp / Harvestable.HAND_POWER), "rota = como a mano")
	gs.storage.add(roll("stone"))
	var stones_before := Crafting.candidates(axe_recipe, 1, gs.owned_items()).size()
	check(Crafting.repair(axe_item) and not axe_item.is_broken
		and axe_item.durability == axe_item.max_durability(), "reparar deja el hacha como nueva")
	check(Crafting.candidates(axe_recipe, 1, gs.owned_items()).size() == stones_before - 1,
		"reparar consume 1 piedra")
	tree_node.queue_free()
	vein.queue_free()

	# Arma: el daño sale del poder de la espada, y se gasta al pegar
	var sword := ItemInstance.new(sword_recipe.result)
	sword.stats = {"poder": 3.0, "durabilidad": 50.0, "peso": 2.0}
	sword.repair_full()
	bag.add(sword)
	var ent3 := enemy_entity()
	spawn_enemy(ent3, p.global_position + Vector2(14, 0))
	p._attack_cd = 0.0
	p.attack(Vector2.RIGHT)
	check(ent3.alive == false, "espada de poder 3: el enemigo básico cae de un golpe")
	check(sword.durability == 49.0, "pegar gasta durabilidad de la espada")

	# UI de la mesa
	var cui: CraftingUI = main.crafting_ui
	cui.open()
	check(tree.paused and cui.is_open(), "la mesa pausa el juego")
	cui.select_recipe(axe_recipe)
	var chosen_stone: ItemInstance = cui.selection()[1][0]
	cui.toggle_material(1, chosen_stone)
	check(not cui.selection()[1].has(chosen_stone) and cui._craft_button.disabled,
		"quitar un material deshabilita Fabricar")
	cui.close()
	check(not tree.paused, "cerrar la mesa despausa")
