extends TestSuite
## Hito 11: escalera piedra → cobre → hierro, rasgos raros (tirada, herencia, guardado)
## y el tablón nuevo (elegir qué entregar, misiones de fabricar y de rasgo).


func _with_trait(id: String, trait_id: String) -> ItemInstance:
	var it := roll(id)
	var t: TraitData = load("res://data/traits/%s.tres" % trait_id)
	it.traits.append(t)
	Traits.apply(it, it.traits)
	return it


func run() -> void:
	var gs: Node = GameState
	var rng := RandomNumberGenerator.new()
	rng.seed = 11

	# --- Escalera de metales ----------------------------------------------------------
	check(item("stone_pickaxe").tool_level == 1 and item("copper_pickaxe").tool_level == 2
		and item("iron_pickaxe").tool_level == 3, "picos: piedra 1 · cobre 2 · hierro 3")
	check(spawn_entry("copper_vein").min_tool_level == 1 and spawn_entry("iron_vein").min_tool_level == 2,
		"veta de cobre con pico de piedra, veta de hierro con pico de cobre")
	check(spawn_entry("copper_vein").min_depth < spawn_entry("iron_vein").min_depth, "el hierro aparece más profundo")
	for r in ["copper_axe", "copper_pickaxe", "copper_sword"]:
		check(Crafting.RECIPES.has(recipe(r)), "receta %s en la mesa" % r)

	# --- Datos de rasgos -----------------------------------------------------------------
	for mat in ["wood", "stone", "copper", "iron"]:
		var list := Traits.for_material(item(mat))
		var bad := list.filter(func(t: TraitData) -> bool: return t.negative).size()
		check(list.size() == 3 and bad == 1, "%s: 3 rasgos, 1 malo" % mat)
	check(Traits.chance(0) < Traits.chance(6) and Traits.chance(99) == Traits.MAX_CHANCE,
		"la chance sube con la profundidad y tiene tope")

	# --- Tirada al recolectar -------------------------------------------------------------
	var with_trait := 0
	for i in 400:
		if DNA.generar_recurso(item("wood"), 0, rng).has_traits():
			with_trait += 1
	var deep := 0
	for i in 400:
		if DNA.generar_recurso(item("wood"), 10, rng).has_traits():
			deep += 1
	check(with_trait > 2 and with_trait < 60, "a profundidad 0 los rasgos son raros (%d/400)" % with_trait)
	check(deep > with_trait, "más profundo, más rasgos (%d/400)" % deep)
	var all_good := true
	for i in 50:
		var g := DNA.generar_recurso(item("iron"), 0, rng, true, true)
		all_good = all_good and g.has_traits() and not g.traits[0].negative
	check(all_good, "eventos especiales: rasgo bueno garantizado")
	check(spawn_entry("ancient_tree").guaranteed_trait and spawn_entry("shiny_vein").guaranteed_trait,
		"árbol antiguo y veta brillante garantizan rasgo")
	var plain := roll("wood")
	var light := ItemInstance.from_dict(plain.to_dict())  # la misma madera, liviana
	light.traits.append(load("res://data/traits/light_wood.tres"))
	Traits.apply(light, light.traits)
	check(not plain.has_traits(), "roll() de los tests sale sin rasgos")
	check(is_equal_approx(light.weight(), snappedf(plain.weight() * 0.7, 0.1)),
		"madera liviana: pesa 30% menos ya en la mochila")

	# --- Herencia al fabricar -----------------------------------------------------------------
	var axe := recipe("stone_axe")
	var stones: Array[ItemInstance] = [roll("stone"), roll("stone")]
	var woods: Array[ItemInstance] = [roll("wood"), roll("wood")]
	var base := Crafting.preview(axe, {0: woods, 1: stones})
	var heart := ItemInstance.from_dict(woods[0].to_dict())  # misma madera, más el rasgo
	heart.traits.append(load("res://data/traits/heartwood.tres"))
	var woods_h: Array[ItemInstance] = [heart, woods[1]]
	var boosted := Crafting.preview(axe, {0: woods_h, 1: stones})
	check(boosted.traits.size() == 1 and boosted.traits[0].id == &"heartwood", "el hacha hereda el rasgo de la madera")
	check(absf(boosted.max_durability() - roundf(base.max_durability() * 1.25)) <= 1.0,
		"corazón de roble: +25%% durabilidad (%d → %d)" % [base.max_durability(), boosted.max_durability()])
	# Tope de 2 y los malos primero
	var veined := _with_trait("stone", "veined_stone")
	var river := _with_trait("stone", "river_stone")
	var worm := _with_trait("wood", "wormwood")
	var sel4 := {0: [heart, worm] as Array[ItemInstance], 1: [veined, river] as Array[ItemInstance]}
	var inh := Crafting.traits_for(axe, sel4)
	check(inh.kept.size() == Traits.MAX_PER_ITEM and inh.dropped.size() == 2, "tope de 2 rasgos: el resto no entra")
	check((inh.kept[0] as TraitData).id == &"wormwood", "los rasgos malos entran primero (no se tapan)")
	var dup := Crafting.traits_for(axe, {0: [heart, _with_trait("wood", "heartwood")] as Array[ItemInstance], 1: stones})
	check(dup.kept.size() == 1, "dos maderas de corazón = un solo rasgo")
	# El peso no se aplica dos veces (ya viene de los materiales)
	var p_light := Crafting.preview(axe, {0: [light, woods[1]] as Array[ItemInstance], 1: stones})
	var p_plain := Crafting.preview(axe, {0: [plain, woods[1]] as Array[ItemInstance], 1: stones})
	var expected := snappedf((light.weight() + woods[1].weight() + stones[0].weight() + stones[1].weight()) * axe.weight_factor, 0.1)
	check(is_equal_approx(p_light.stats["peso"], expected) and p_light.stats["peso"] < p_plain.stats["peso"],
		"madera liviana: hacha más liviana, sin doble descuento")

	# Fabricar de verdad: los rasgos quedan y reparar no los saca
	gs.bag.clear()
	gs.storage.clear()
	gs.storage.add(heart)
	gs.storage.add(woods[1])
	for s in stones:
		gs.storage.add(s)
	var made := Crafting.craft(axe, {0: [heart, woods[1]] as Array[ItemInstance], 1: stones})
	check(made != null and made.has_traits(), "el hacha fabricada tiene el rasgo")
	made.durability = 1.0
	gs.storage.add(roll("stone"))
	Crafting.repair(made)
	check(made.has_traits() and made.durability == made.max_durability(), "reparar conserva los rasgos")

	# --- Guardado ---------------------------------------------------------------------------
	var back := ItemInstance.from_dict(JSON.parse_string(JSON.stringify(made.to_dict())))
	check(back.traits.size() == 1 and back.traits[0] == made.traits[0], "los rasgos se guardan y se cargan")
	var old := made.to_dict()
	old.erase("traits")
	check(ItemInstance.from_dict(old).traits.is_empty(), "guardado viejo (sin rasgos): carga igual")

	# --- Aviso de hallazgo ---------------------------------------------------------------------
	AudioManager._last.clear()
	var rare_before: int = AudioManager.played.get(&"rare", 0)
	gs.pick_up(_with_trait("copper", "red_copper"))
	check(AudioManager.played.get(&"rare", 0) > rare_before, "hallazgo raro: suena el jingle")
	check(main.crafting_ui != null, "la mesa existe")
	main.crafting_ui.open()
	main.crafting_ui.select_recipe(axe)
	check(main.crafting_ui._result_stats.text.contains("★") or not Crafting.traits_for(axe, main.crafting_ui.selection()).kept.size(),
		"la vista previa muestra los rasgos que se heredan")
	main.crafting_ui.close()

	# --- Tablón ------------------------------------------------------------------------------
	var missions: Node = Missions
	missions.reset()
	gs.bag.clear()
	gs.storage.clear()
	var deliver: Mission = null
	for m: Mission in missions.active:
		if m.kind == Mission.Kind.DELIVER:
			deliver = m
	deliver.item = item("stone")
	deliver.count = 2
	deliver.min_quality = 0
	var s_low := roll("stone")
	s_low.quality = 10
	var s_mid := roll("stone")
	s_mid.quality = 50
	var s_top := roll("stone")
	s_top.quality = 95
	for s in [s_top, s_low, s_mid]:
		gs.storage.add(s)
	var def: Array = missions.default_choice(deliver)
	check(def.has(s_low) and def.has(s_mid) and not def.has(s_top), "por defecto se entregan los peores")
	var s_rare := _with_trait("stone", "veined_stone")
	s_rare.quality = 1
	gs.storage.add(s_rare)
	check(not missions.default_choice(deliver).has(s_rare), "por defecto no se entrega una piedra con rasgo bueno")
	gs.storage.remove(s_rare)
	check(not missions.is_valid_choice(deliver, [s_top]) and not missions.is_valid_choice(deliver, [s_top, s_top]),
		"elección inválida: cantidad justa y sin repetir")
	# UI: abrir el selector, cambiar la elección y entregar
	main.board_ui.open()
	main.board_ui.open_picker(deliver)
	check(main.board_ui.is_picking() and main.board_ui.chosen().size() == 2, "Reclamar abre el selector con 2 marcados")
	main.board_ui.toggle_choice(s_mid)  # saca la del medio
	main.board_ui.toggle_choice(s_top)  # elige la mejor
	check(main.board_ui.confirm_picker(), "entregar lo elegido")
	check(gs.storage.has(s_mid) and not gs.storage.has(s_top) and not gs.storage.has(s_low),
		"se entregó la elección del jugador (la buena) y quedó la otra")
	main.board_ui.close()

	# Las nuevas no repiten tipo y pueden ser de fabricar / rasgo
	var kinds: Array = missions.active.map(func(m: Mission) -> int: return m.kind)
	var unique := {}
	for k in kinds:
		unique[k] = true
	check(unique.size() == missions.active.size(), "el tablón no repite tipos de misión")
	var craft_m: Mission = missions.generate(Mission.Kind.CRAFT)
	missions.active[0] = craft_m
	var weak := ItemInstance.new(item("stone_axe"))
	weak.quality = craft_m.target - 10
	missions.on_crafted(weak)
	check(not craft_m.is_complete(), "fabricar con poca calidad no cuenta")
	weak.quality = craft_m.target
	missions.on_crafted(weak)
	check(craft_m.is_complete(), "fabricar con calidad suficiente cumple la misión")
	var trait_m: Mission = missions.generate(Mission.Kind.TRAIT)
	missions.active[1] = trait_m
	gs.storage.add(_with_trait("wood", "wormwood"))
	check(not trait_m.is_complete(), "un rasgo malo no sirve para la misión de rasgo")
	var good := _with_trait("wood", "heartwood")
	gs.storage.add(good)
	check(trait_m.is_complete() and missions.claim(trait_m) and not gs.storage.has(good),
		"misión de rasgo: se entrega el recurso con rasgo bueno")
	var saved := Mission.from_dict(JSON.parse_string(JSON.stringify(craft_m.to_dict())))
	check(saved.kind == Mission.Kind.CRAFT and saved.target == craft_m.target and saved.is_complete(),
		"las misiones nuevas se guardan")
	missions.reset()
