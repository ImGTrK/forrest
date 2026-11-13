extends TestSuite
## Guardado en disco, carga, versionado/migraciones y menús.


func run() -> void:
	var gs: Node = GameState
	var bag: GridInventory = gs.bag
	var missions: Node = Missions
	var wood := item("wood")
	var p := player()

	await go_to_forest()
	await clear_enemies()
	await go_to_hub()
	check(main.is_in_hub() and SaveSystem.has_save(), "llegar al pueblo autoguarda")

	# Armar un estado reconocible
	bag.clear()
	gs.storage.clear()
	var s_log := roll("wood", 4)
	s_log.rotated = true
	bag.add_at(s_log, Vector2i(2, 3))
	var hard_stones: Array[ItemInstance] = []
	for i in 2:
		var h := roll("stone")
		h.stats["dureza"] = 12.0
		hard_stones.append(h)
	var s_axe := Crafting.preview(recipe("stone_axe"), {0: [roll("wood"), roll("wood")], 1: hard_stones})
	s_axe.durability = 7.0
	bag.add_at(s_axe, Vector2i(0, 0))
	for i in 25:  # suficiente para que el almacén crezca
		gs.storage.add(roll("stone", i % 5))
	var s_storage_rows: int = gs.storage.size.y
	gs.apply_upgrade(&"weight")
	var s_bonus_w: float = gs.bonus_weight
	var s_bonus_h: int = gs.bonus_health
	Clock.total_minutes = 1440 * 4 + 15 * 60 + 30
	Energy.set_value(42.0)
	p.health.current = 3
	missions.on_enemy_killed()
	var s_hunt_progress := _hunt_progress()
	var s_completed: int = missions.completed
	var s_titles: Array = missions.active.map(func(m: Mission) -> String: return m.title())
	check(main.autosave(), "guardar en el pueblo")
	var saved := _read_save()
	check(int(saved.get("version", 0)) == SaveSystem.VERSION and saved.get("game_version", "") == SaveSystem.game_version(),
		"el guardado lleva versión de formato (%d) y del juego (%s)" % [SaveSystem.VERSION, SaveSystem.game_version()])

	# Romper todo y cargar
	SaveSystem.new_game()
	check(bag.is_empty() and gs.storage.is_empty() and gs.bonus_weight == 0.0
		and missions.completed == 0, "partida nueva: todo a cero")
	check(SaveSystem.load_game(), "cargar el guardado")
	var l_log: ItemInstance = bag.item_at(Vector2i(2, 3))
	check(l_log != null and l_log.rotated and l_log.data == wood and same_stats(l_log.stats, s_log.stats)
		and l_log.quality == s_log.quality and bag.position_of(l_log) == Vector2i(2, 3),
		"madera: misma posición, rotación, ADN y calidad")
	var l_axe: ItemInstance = bag.item_at(Vector2i(0, 0))
	check(l_axe != null and l_axe.data == s_axe.data and l_axe.durability == 7.0
		and is_equal_approx(l_axe.power(), s_axe.power()), "hacha: tipo, poder y durabilidad")
	check(gs.storage.count() == 25 and gs.storage.size.y == s_storage_rows, "almacén: 25 ítems y su tamaño")
	check(gs.bonus_weight == s_bonus_w and gs.bonus_health == s_bonus_h, "mejoras permanentes")
	check(Clock.total_minutes == 1440 * 4 + 15 * 60 + 30 and is_equal_approx(Energy.value, 42.0),
		"hora y energía")
	check(SaveSystem.pending_health == 3, "vida guardada (la aplica Main al crearse)")
	check(missions.completed == s_completed and _hunt_progress() == s_hunt_progress
		and missions.active.map(func(m: Mission) -> String: return m.title()) == s_titles,
		"misiones: las mismas, con su progreso")
	SaveSystem.pending_health = -1

	# --- Versionado ---------------------------------------------------------------
	# Un guardado de la 0.1 (formato 1, sin game_version) se migra y carga igual
	var v1 := saved.duplicate(true)
	v1["version"] = 1
	v1.erase("game_version")
	_write_save(v1)
	SaveSystem.new_game()
	check(SaveSystem.load_game() and bag.item_at(Vector2i(2, 3)) != null and gs.storage.count() == 25,
		"guardado de la 0.1 (formato 1): se migra y carga")
	var migrated := SaveSystem.migrate(v1.duplicate(true))
	check(int(migrated.get("version", 0)) == SaveSystem.VERSION and migrated.get("game_version") == "0.1",
		"la migración 1→2 completa la versión del juego")
	SaveSystem.pending_health = -1
	# Un guardado de una versión futura no se carga ni toca el estado
	var future := saved.duplicate(true)
	future["version"] = SaveSystem.VERSION + 1
	_write_save(future)
	var count_before: int = bag.count()
	check(not SaveSystem.load_game() and bag.count() == count_before and SaveSystem.last_error != "",
		"guardado de una versión más nueva: no carga y explica por qué")
	main.autosave()

	# En el bosque no se guarda
	var save_time := FileAccess.get_modified_time(ProjectSettings.globalize_path(SaveSystem.save_path))
	await go_to_forest()
	check(not main.autosave(), "en el bosque no se guarda")
	check(FileAccess.get_modified_time(ProjectSettings.globalize_path(SaveSystem.save_path)) == save_time,
		"el archivo no cambió")
	await clear_enemies()

	# Guardado roto: no rompe el juego
	var f := FileAccess.open(SaveSystem.save_path, FileAccess.WRITE)
	f.store_string("{esto no es json")
	f.close()
	var bag_count_before: int = bag.count()
	check(not SaveSystem.load_game() and bag.count() == bag_count_before,
		"guardado ilegible: no carga y no toca el estado")

	# Menús
	main.pause_menu.open(false)
	check(tree.paused and main.pause_menu.is_open(), "el menú de pausa pausa")
	main.pause_menu.close()
	check(not tree.paused, "cerrar la pausa")
	SaveSystem.delete_save()
	var menu: Control = load("res://scenes/MainMenu.tscn").instantiate()
	tree.root.add_child(menu)
	check(menu._continue.disabled, "menú: sin guardado, Continuar deshabilitado")
	menu.queue_free()


func _hunt_progress() -> int:
	for m: Mission in Missions.active:
		if m.kind == Mission.Kind.HUNT:
			return m.progress
	return -1


func _read_save() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.save_path))


func _write_save(data: Dictionary) -> void:
	var f := FileAccess.open(SaveSystem.save_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t", true, true))
	f.close()
