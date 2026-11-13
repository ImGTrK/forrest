extends TestSuite
## Grilla, peso, mochila llena, almacén, equipo que no se pierde y la UI del inventario.


func run() -> void:
	var gs: Node = GameState
	var wood := item("wood")
	var stone := item("stone")
	var iron := item("iron")
	var p := player()
	check(gs.bag.is_empty(), "partida nueva: mochila vacía")

	# Grilla: la madera ocupa 1x2; 12 maderas llenan la grilla de 6x4
	var grid := GridInventory.new(Vector2i(6, 4))
	var first_wood := roll("wood")
	grid.add(first_wood)
	check(grid.item_at(Vector2i(0, 0)) == first_wood and grid.item_at(Vector2i(0, 1)) == first_wood,
		"la madera ocupa 1x2 celdas")
	for i in 11:
		grid.add(roll("wood"))
	check(grid.count() == 12 and not grid.has_space(Vector2i.ONE), "12 maderas llenan la grilla 6x4")
	grid.remove(first_wood)
	check(grid.has_space(Vector2i(1, 2)) and grid.add(roll("wood")), "al sacar una entra otra")

	# ADN con stat invertido: más profundidad = MENOS peso
	var w0 := 0.0
	var w6 := 0.0
	for i in 300:
		w0 += DNA.generar_recurso(iron, 0, gs.rng).weight()
		w6 += DNA.generar_recurso(iron, 6, gs.rng).weight()
	check(w6 < w0, "peso invertido: lo profundo pesa menos (%.2f vs %.2f)" % [w6 / 300, w0 / 300])

	# Mochila llena: no se puede recolectar (ni se gasta energía)
	for i in 12:
		gs.bag.add(roll("wood"))
	check(not gs.can_carry(stone), "mochila llena")
	var rock := Harvestable.new()
	rock.setup(spawn_entry("rock"), {"alive": true}, 0)
	main._area.add_child(rock)
	var energy_before: float = Energy.value
	for i in 10:
		rock.interact(p)
	check(is_instance_valid(rock) and not rock.is_queued_for_deletion(), "mochila llena: la roca no se rompe")
	check(Energy.value >= energy_before - 0.01, "mochila llena: no gasta energía")
	rock.queue_free()

	# Guardar todo en el almacén / retirar
	var storage_count: int = gs.storage.count()
	var moved: int = gs.deposit_resources()
	check(moved == 12 and gs.bag.is_empty() and gs.storage.count() == storage_count + 12,
		"guardar todos los recursos")
	var picked: ItemInstance = gs.storage.items().back()
	check(gs.withdraw(picked) and gs.bag.has(picked) and not gs.storage.has(picked), "retirar del almacén")
	gs.deposit(picked)

	# Sobrepeso: más de 18 kg -> velocidad ×0.5
	check(gs.speed_multiplier() == 1.0, "sin sobrepeso: velocidad normal")
	while gs.carried_weight() <= GameState.MAX_WEIGHT:
		gs.bag.add(DNA.generar_recurso(iron, 0, gs.rng))
	check(gs.is_overweight() and gs.speed_multiplier() == GameState.OVERWEIGHT_SPEED_MULT,
		"sobrepeso: velocidad ×0.5 (%.1f kg)" % gs.carried_weight())
	gs.deposit_resources()

	# El equipo nunca se pierde al morir/colapsar
	var axe_data := ItemData.new()
	axe_data.display_name = "Hacha de prueba"
	axe_data.item_type = ItemData.ItemType.TOOL
	var axe := ItemInstance.new(axe_data)
	gs.bag.add(axe)
	for i in 4:
		gs.bag.add(DNA.generar_recurso(stone, 0, gs.rng))
	var lost_all: int = gs.lose_run_fraction(1.0, gs.rng)
	check(lost_all == 4 and gs.bag.has(axe) and gs.bag.count() == 1, "perder 100%: el equipo se queda")
	gs.bag.remove(axe)

	# --- Rotar, mover, intercambiar, ordenar, tirar ---------------------------------
	var ui: InventoryUI = main.inventory_ui
	var bag: GridInventory = gs.bag
	var log_a := DNA.generar_recurso(wood, 0, gs.rng)
	check(log_a.grid_size() == Vector2i(1, 2), "madera parada: 1x2")
	log_a.rotated = true
	check(log_a.grid_size() == Vector2i(2, 1), "madera rotada: 2x1")
	log_a.rotated = false

	ui.open_bag()
	bag.add_at(log_a, Vector2i(0, 0))
	ui.pick_up(bag, log_a)
	check(ui.is_holding() and not bag.has(log_a), "agarrar saca el ítem de la grilla")
	ui.rotate_held()
	check(ui.place_held(bag, Vector2i(3, 2)) and bag.position_of(log_a) == Vector2i(3, 2)
		and log_a.grid_size() == Vector2i(2, 1), "soltar rotado en otra posición")
	var pebble := DNA.generar_recurso(stone, 0, gs.rng)
	bag.add_at(pebble, Vector2i(0, 0))
	ui.pick_up(bag, log_a)
	check(ui.place_held(bag, Vector2i(0, 0)) and bag.item_at(Vector2i(0, 0)) == log_a
		and ui.held_item() == pebble, "soltar encima intercambia")
	check(ui.place_held(bag, bag.find_space(Vector2i.ONE)) and not ui.is_holding(),
		"soltar la piedra intercambiada en un lugar libre")
	ui.pick_up(bag, pebble)
	ui.close()
	check(not ui.is_holding() and bag.has(pebble), "cerrar con algo en la mano lo devuelve")
	ui.open_bag()
	bag.clear()
	var log_b := DNA.generar_recurso(wood, 0, gs.rng)
	bag.add_at(log_b, Vector2i(2, 1))
	check(ui.rotate_in_place(bag, log_b) and log_b.grid_size() == Vector2i(2, 1), "rotar en el lugar")
	# Ordenar: grilla fragmentada donde la madera parada no entra hasta ordenar
	bag.clear()
	for x in 6:
		for y in [0, 2]:  # piedras en filas 0 y 2: ningún hueco vertical de 2
			bag.add_at(DNA.generar_recurso(stone, 0, gs.rng), Vector2i(x, y))
	check(bag.find_space(Vector2i(1, 2)).x < 0 and bag.find_space(Vector2i(2, 1)).x >= 0,
		"fragmentada: no entra una madera parada")
	check(bag.sort() and bag.find_space(Vector2i(1, 2)).x >= 0, "ordenar libera lugar para la madera")
	var junk := bag.items()[0]
	var before_discard := bag.count()
	ui.pick_up(bag, junk)
	ui.discard_held()
	check(bag.count() == before_discard - 1 and not ui.is_holding(), "tirar el ítem agarrado")
	ui.discard(bag, bag.items()[0])
	check(bag.count() == before_discard - 2, "tirar el ítem bajo el mouse")
	ui.close()
	# Mochila <-> almacén lado a lado
	bag.clear()
	ui.open_chest()
	var log_c := DNA.generar_recurso(wood, 0, gs.rng)
	bag.add(log_c)
	var free: Vector2i = gs.storage.find_space(Vector2i(1, 2))
	ui.pick_up(bag, log_c)
	check(ui.place_held(gs.storage, free) and gs.storage.position_of(log_c) == free,
		"arrastrar de la mochila al almacén")
	ui.quick_move(gs.storage, log_c)
	check(bag.has(log_c) and not gs.storage.has(log_c), "Shift+clic: del almacén a la mochila")
	ui.close()
	bag.clear()
	# El almacén crece: siempre deja lugar libre
	var big := GridInventory.new(Vector2i(2, 2), true)
	for i in 6:
		big.add(DNA.generar_recurso(stone, 0, gs.rng))
	check(big.count() == 6 and big.size.y >= 4, "el almacén crece (%d filas)" % big.size.y)
	var last_row_free := true
	for x in big.size.x:
		if big.item_at(Vector2i(x, big.size.y - 1)) != null:
			last_row_free = false
	check(last_row_free and big.find_space(Vector2i(1, 2)).x >= 0,
		"el almacén siempre deja lugar para una madera parada")

	ui.open_bag()
	check(tree.paused and ui.is_open(), "la mochila pausa el juego")
	ui.close()
	check(not tree.paused, "cerrar la mochila despausa")
