extends TestSuite
## Hito 9 — bosque vivo: suelo por materiales, decoración, eventos raros.


func run() -> void:
	var gs: Node = GameState
	var p := player()
	await go_to_forest()
	await clear_enemies()
	var zone: ZoneData = ForestSession.zones[Vector2i.ZERO]
	check(ZoneTemplates.TEMPLATES.has(zone.template), "la zona tiene plantilla (%s)" % zone.template)

	# --- Suelo pintado por materiales -------------------------------------------------
	var layer: TileMapLayer = null
	for n in main._area.get_children():
		if n is TileMapLayer:
			layer = n
	var mid := ZoneGenerator.ZONE_TILES / 2
	var path_atlas := layer.get_cell_atlas_coords(Vector2i(mid, mid))
	check(path_atlas in [Vector2i(3, 0), Vector2i(12, 0), Vector2i(6, 1)], "el centro de la zona es camino (%s)" % path_atlas)
	var wall_data := layer.get_cell_tile_data(Vector2i(0, 0))
	check(wall_data != null and wall_data.get_collision_polygons_count(0) > 0, "el cerco del borde tiene colisión")
	var grass_kinds := {}
	for y in range(3, 37):
		for x in range(3, 37):
			if zone.ground_at(Vector2i(x, y)) == TerrainTiles.Mat.GRASS:
				grass_kinds[layer.get_cell_atlas_coords(Vector2i(x, y))] = true
	check(grass_kinds.size() >= 3, "el pasto mezcla variantes (%d distintas)" % grass_kinds.size())
	# Piezas de borde: un camino que entra al pasto usa una pieza de transición
	var piece := TerrainTiles.piece_for(func(dx: int, dy: int) -> bool: return dy >= 0)
	check(piece == &"t", "autotile: sin vecino arriba = borde de arriba")
	piece = TerrainTiles.piece_for(func(dx: int, dy: int) -> bool: return not (dx == -1 and dy == -1))
	check(piece == &"itl", "autotile: solo falta la diagonal = esquina interna")

	# --- Decoración blanda: se pisa y no se usa ------------------------------------------
	var flowers := spawn_harvestable(spawn_entry("deco_flowers"))
	check(not flowers._collision_rect().has_area() and not flowers.is_in_group("interactable"),
		"las flores no tienen colisión ni se pueden usar")
	var log_deco := spawn_harvestable(spawn_entry("deco_log"))
	check(log_deco._collision_rect().has_area(), "el tronco caído sí bloquea")
	var fire := spawn_harvestable(spawn_entry("campfire"))
	var f0: int = fire._sprite.frame
	await wait_frames(12)
	check(fire._sprite.frame != f0, "la fogata se anima")
	for n in [flowers, log_deco, fire]:
		n.queue_free()

	# --- Árbol antiguo: suelta 3 maderas de buena calidad ------------------------------------
	gs.bag.clear()
	var ancient := spawn_harvestable(spawn_entry("ancient_tree"))
	for i in 30:
		if ancient.is_queued_for_deletion():
			break
		ancient.interact(p)
	check(gs.bag.count() == 3, "el árbol antiguo suelta 3 maderas (%d)" % gs.bag.count())
	var q := 0
	for it: ItemInstance in gs.bag.items():
		q += it.quality
	check(q / 3 >= 55, "con buen ADN (calidad promedio %d%%)" % (q / 3))
	gs.bag.clear()

	# --- Veta brillante: pide pico de nivel 1 ---------------------------------------------------
	var shiny := spawn_harvestable(spawn_entry("shiny_vein"))
	shiny.interact(p)
	check(shiny._hp == spawn_entry("shiny_vein").hardness, "veta brillante: sin pico no se puede")
	shiny.queue_free()

	# --- Cofre perdido: da 3 recursos y queda abierto ------------------------------------------
	var ent := {"alive": true, "tile": Vector2i(5, 5)}
	var chest := LostChest.new()
	chest.setup(spawn_entry("lost_chest"), ent, 0)
	main._area.add_child(chest)
	chest.global_position = p.global_position + Vector2(24, 0)
	check(chest.is_in_group("interactable") and chest._sprite.frame == 0, "el cofre perdido arranca cerrado")
	chest.interact(p)
	check(gs.bag.count() == LostChest.LOOT_COUNT and chest.is_open() and chest._sprite.frame == 1,
		"abrirlo da %d recursos y queda abierto" % LostChest.LOOT_COUNT)
	chest.interact(p)
	check(gs.bag.count() == LostChest.LOOT_COUNT, "abierto ya no da nada")
	# Mochila llena: lo que no entra queda adentro
	gs.bag.clear()
	for i in 12:
		gs.bag.add(roll("wood"))
	var ent2 := {"alive": true, "tile": Vector2i(6, 6)}
	var chest2 := LostChest.new()
	chest2.setup(spawn_entry("lost_chest"), ent2, 0)
	main._area.add_child(chest2)
	chest2.interact(p)
	check(not chest2.is_open() and int(ent2.loot) == LostChest.LOOT_COUNT, "mochila llena: el botín queda en el cofre")
	gs.bag.clear()
