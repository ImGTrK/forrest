extends TestSuite
## Loop básico: pueblo → bosque → recolectar → zona visitada → pueblo → almacén → bosque nuevo.


func run() -> void:
	var gs: Node = GameState
	var fs: Node = ForestSession
	check(main._area is Hub, "arranca en el pueblo")

	await go_to_forest()
	check(main._area is ForestZone, "entró al bosque")
	check(fs.zones.size() == 1, "una zona generada")
	var first_seed: int = fs.run_seed

	# Recolectar todo lo recolectable de la zona (golpeando hasta romper)
	var harvested := 0
	for node in main._area.get_children():
		if node is Harvestable and node.entry.item != null and node.entry.min_tool_level == 0:
			for i in 20:  # a mano: golpear hasta que se rompa
				if node.is_queued_for_deletion():
					break
				node.interact(player())
			harvested += maxi(node.entry.drop_count, 1)  # eventos (árbol ancestral) sueltan más de uno
	check(harvested > 0, "había algo para recolectar")
	check(gs.bag.count() == harvested, "mochila = %d" % harvested)

	# Ir a una zona vecina y volver: la (0,0) no debe regenerarse ni revivir recursos
	var z0: ZoneData = fs.zones[Vector2i.ZERO]
	var dir := Vector2i.ZERO
	for d: Vector2i in z0.doors:
		if z0.doors[d] and d != Vector2i.LEFT:
			dir = d
	check(dir != Vector2i.ZERO, "la zona inicial tiene salida al bosque")
	main._handle_leave(dir)
	await tree.physics_frame
	check(fs.current == dir, "se movió a %s" % dir)
	main._handle_leave(-dir)
	await tree.physics_frame
	check(fs.zones[Vector2i.ZERO] == z0, "la zona (0,0) salió de la cache, no se regeneró")
	var alive_harvestables := 0
	for node in main._area.get_children():
		if node is Harvestable and node.entry.item != null:
			alive_harvestables += 1
	check(alive_harvestables == 0, "lo recolectado no reaparece (%d vivos)" % alive_harvestables)

	await go_to_hub()
	check(main._area is Hub, "volvió al pueblo")
	check(fs.zones.is_empty(), "el bosque se borró")
	check(gs.bag.count() == harvested and gs.storage.is_empty(),
		"volver no guarda solo: lo recolectado sigue en la mochila")
	check(gs.deposit_resources() == harvested and gs.storage.count() == harvested and gs.bag.is_empty(),
		"guardar en el cofre: almacén tiene %d" % harvested)

	main.inventory_ui.open_chest()
	check(tree.paused, "el almacén pausa el juego")
	main.inventory_ui.close()
	check(not tree.paused, "cerrar despausa")

	await go_to_forest()
	check(fs.zones.size() == 1 and fs.run_seed != first_seed, "bosque nuevo con otra semilla")
