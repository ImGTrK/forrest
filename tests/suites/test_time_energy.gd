extends TestSuite
## Reloj, energía, curva por hora, dormir y colapso.


func run() -> void:
	var gs: Node = GameState
	var fs: Node = ForestSession
	await go_to_forest()

	var t0: float = Clock.total_minutes
	await wait_frames(20)
	check(Clock.total_minutes > t0, "el reloj avanza")
	main.inventory_ui.open_chest()
	var t1: float = Clock.total_minutes
	for i in 10:
		await tree.process_frame
	check(is_equal_approx(Clock.total_minutes, t1), "el reloj se pausa en menús")
	main.inventory_ui.close()

	# Golpear gasta energía (además del drenaje por tiempo)
	var e0: float = Energy.value
	for node in main._area.get_children():
		if node is Harvestable and node.entry.item != null and node.entry.min_tool_level == 0:
			node.interact(player())
			break
	check(Energy.value <= e0 - Energy.ACTION_COST + 0.01, "golpear gasta energía")

	# Curva por hora
	var saved_time: float = Clock.total_minutes
	Clock.total_minutes = 1440 + 8 * 60  # 08:00
	check(is_equal_approx(Clock.difficulty_multiplier(), 1.0) and Clock.rarity_bonus() == 0,
		"mañana: dificultad base")
	Clock.total_minutes = 1440 + 3 * 60  # 03:00
	check(Clock.difficulty_multiplier() > 1.7 and Clock.rarity_bonus() == 3,
		"madrugada: pico (x%.2f, +%d)" % [Clock.difficulty_multiplier(), Clock.rarity_bonus()])
	check(Clock.ambient_color().v < 0.7, "madrugada: el mundo se oscurece")
	Clock.total_minutes = saved_time

	# Rampa de energía
	Energy.set_value(45.0)
	check(Energy.state == Energy.State.TIRED, "50%: cansado (solo aviso)")
	check(Energy.speed_multiplier() == 1.0, "cansado no tiene debuff")
	Energy.set_value(15.0)
	check(Energy.state == Energy.State.EXHAUSTED and Energy.speed_multiplier() < 1.0,
		"20%: agotado con debuff de velocidad")

	# Dormir: 5-9 h al azar, recarga proporcional
	Energy.set_value(30.0)
	var before_sleep: float = Clock.total_minutes
	main.sleep()
	await wait_sleep()
	var slept_h: float = (Clock.total_minutes - before_sleep) / 60.0
	check(slept_h >= 5.0 and slept_h <= 9.1, "dormir pasa 5-9 h (%.1f)" % slept_h)
	check(Energy.value >= 30.0 + 5 * Energy.RECHARGE_PER_SLEEP_HOUR - 1.0, "dormir recarga energía")
	check(not tree.paused, "despierta despausado")

	# Colapso en el bosque: pierde 25% de lo cargado, vuelve al pueblo y duerme
	check(main._area is ForestZone, "(seguimos en el bosque)")
	gs.deposit_resources()
	for i in 8:
		gs.bag.add(roll("wood"))
	Energy.set_value(0.0)
	await tree.process_frame
	await wait_sleep()
	check(main._area is Hub, "el colapso lleva al pueblo")
	check(gs.bag.count() == 6, "colapso: le quedan 6 de 8 en la mochila (perdió 25%)")
	check(fs.zones.is_empty(), "colapso: el bosque se borró")
	check(Energy.value > 0.0 and Energy.state != Energy.State.COLLAPSED, "colapso: despierta con energía")
