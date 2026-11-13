extends TestSuite
## Noche, linterna, aceite y tablón de misiones.


func run() -> void:
	var gs: Node = GameState
	var bag: GridInventory = gs.bag
	var at := func(h: float) -> float:
		Clock.total_minutes = 1440.0 * 3 + h * 60.0
		return Clock.night_factor()
	check(at.call(12.0) == 0.0 and is_equal_approx(at.call(19.5), 0.5) and at.call(23.0) == 1.0
		and is_equal_approx(at.call(4.0), 0.5) and at.call(6.0) == 0.0,
		"noche: se cierra 18-21, cerrada 21-03, se abre 03-05")

	# Visión: en el bosque de noche se achica; en el pueblo no hay oscuridad
	await go_to_forest()
	at.call(23.0)
	await tree.process_frame
	await tree.process_frame  # process_frame se emite antes de los _process de ese frame
	check(main._night_rect.visible and main.vision_radius() == main.VISION_NO_LIGHT,
		"de noche en el bosque: visión mínima sin linterna")
	await clear_enemies()

	# Linterna + aceite
	check(not gs.toggle_lantern(), "sin linterna no se prende")
	var lantern_recipe := recipe("lantern")
	var oil_recipe := recipe("oil")
	for i in 3:
		gs.storage.add(roll("stone"))
	for i in 5:
		gs.storage.add(roll("wood"))
	var lamp := Crafting.craft(lantern_recipe, Crafting.auto_select(lantern_recipe, gs.owned_items()))
	check(lamp != null and lamp.stats.get("radio", 0.0) >= 80.0, "linterna fabricada (radio %d)" % lamp.stats.get("radio", 0))
	check(not gs.toggle_lantern(), "sin aceite no se prende")
	var oil := Crafting.craft(oil_recipe, Crafting.auto_select(oil_recipe, gs.owned_items()))
	check(oil != null and oil.max_durability() >= 90.0 and oil.durability == oil.max_durability(),
		"aceite fabricado (%d min)" % oil.max_durability())
	check(not Crafting.needs_repair(oil), "el aceite no aparece para reparar")
	check(gs.toggle_lantern() and main.vision_radius() == lamp.stats.radio, "linterna prendida: más visión")
	var oil_before := oil.durability
	gs.burn_oil(30.0)
	check(is_equal_approx(oil.durability, oil_before - 30.0), "la linterna gasta aceite con el reloj")
	gs.burn_oil(9999.0)
	check(not bag.has(oil) and not gs.lantern_on, "sin aceite: el frasco desaparece y se apaga")
	var lost_oil := Crafting.craft(oil_recipe, Crafting.auto_select(oil_recipe, gs.owned_items()))
	gs.toggle_lantern()
	await go_to_hub()
	await tree.process_frame
	await tree.process_frame
	check(main._area is Hub and not gs.lantern_on and not main._night_rect.visible,
		"en el pueblo: linterna apagada y sin oscuridad")
	check(bag.has(lamp) and bag.has(lost_oil), "linterna y aceite siguen en la mochila")
	at.call(10.0)

	# Misiones
	var missions: Node = Missions
	missions.reset()
	check(missions.active.size() == 3, "el tablón tiene 3 misiones")
	var hunt: Mission = null
	var deliver: Mission = null
	var reach: Mission = null
	for m: Mission in missions.active:
		match m.kind:
			Mission.Kind.HUNT: hunt = m
			Mission.Kind.DELIVER: deliver = m
			Mission.Kind.REACH_DEPTH: reach = m
	check(hunt and deliver and reach, "una de cada tipo")
	hunt.reward = &"weight"
	check(not missions.claim(hunt), "no se puede reclamar sin cumplir")
	for i in hunt.target:
		missions.on_enemy_killed()
	var weight_before: float = gs.max_weight()
	check(hunt.is_complete() and missions.claim(hunt) and gs.max_weight() == weight_before + GameState.UPGRADE_WEIGHT,
		"cazar: cumplida, +2 kg de capacidad")
	check(missions.active.size() == 3 and not missions.active.has(hunt) and missions.completed == 1,
		"aparece una misión nueva")
	reach.reward = &"energy"
	missions._on_zone_entered(Vector2i(reach.target, 0))
	var energy_max_before: float = Energy.max_value()
	check(missions.claim(reach) and Energy.max_value() == energy_max_before + GameState.UPGRADE_ENERGY,
		"profundidad: cumplida, +10 de energía máxima")
	deliver.reward = &"health"
	deliver.item = item("stone")
	deliver.count = 2
	deliver.min_quality = 0
	gs.storage.clear()
	gs.storage.add(roll("stone"))
	check(not deliver.is_complete(), "entregar: falta material")
	gs.storage.add(roll("stone"))
	var p := player()
	var hp_max_before: int = p.health.max_health
	check(missions.claim(deliver) and gs.storage.is_empty(), "entregar: consume las piedras")
	check(p.health.max_health == hp_max_before + 2 and main.hud._hearts.get_child_count() == p.health.max_health / 2,
		"+1 corazón: vida máxima y HUD actualizados")
	main.board_ui.open()
	check(tree.paused and main.board_ui.is_open(), "el tablón pausa el juego")
	main.board_ui.close()
