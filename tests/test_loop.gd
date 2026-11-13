extends Node
## Smoke test del loop completo con el juego real (autoloads + Main.tscn):
##   hub -> bosque -> recolectar -> volver a zona visitada -> hub -> almacén -> bosque nuevo
## Correr con:
##   godot --headless --path . res://tests/TestLoop.tscn
## (es una escena y no un --script para que los autoloads existan como en el juego real)

var _failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var tree := get_tree()
	var root := tree.root
	var gs: Node = GameState
	var fs: Node = ForestSession
	# Archivo de guardado propio: Main autoguarda y no hay que pisar la partida real
	SaveSystem.save_path = "user://test_save.json"
	SaveSystem.delete_save()
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await tree.process_frame

	_check(main._area is Hub, "arranca en el hub")

	# Salir del hub por el este
	main._handle_leave(Vector2i.RIGHT)
	await tree.physics_frame
	_check(main._area is ForestZone, "entró al bosque")
	_check(fs.zones.size() == 1, "una zona generada")
	var first_seed: int = fs.run_seed

	# Recolectar todo lo recolectable de la zona (golpeando hasta romper)
	var harvested := 0
	for node in main._area.get_children():
		if node is Harvestable and node.entry.item != null and node.entry.min_tool_level == 0:
			for i in 20:  # a mano: golpear hasta que se rompa
				if node.is_queued_for_deletion():
					break
				node.interact(main.player)
			harvested += 1
	_check(harvested > 0, "había algo para recolectar")
	_check(gs.bag.count() == harvested, "inventario de run = %d" % harvested)

	# Ir a una zona vecina y volver: la (0,0) no debe regenerarse ni revivir recursos
	var z0: ZoneData = fs.zones[Vector2i.ZERO]
	var dir := Vector2i.ZERO
	for d: Vector2i in z0.doors:
		if z0.doors[d] and d != Vector2i.LEFT:
			dir = d
	_check(dir != Vector2i.ZERO, "la zona inicial tiene salida al bosque")
	main._handle_leave(dir)
	await tree.physics_frame
	_check(fs.current == dir, "se movió a %s" % dir)
	main._handle_leave(-dir)
	await tree.physics_frame
	_check(fs.zones[Vector2i.ZERO] == z0, "la zona (0,0) salió de la cache, no se regeneró")
	var alive_harvestables := 0
	for node in main._area.get_children():
		if node is Harvestable and node.entry.item != null:
			alive_harvestables += 1
	_check(alive_harvestables == 0, "lo recolectado no reaparece (%d vivos)" % alive_harvestables)

	# Volver al hub por el oeste de (0,0)
	main._handle_leave(Vector2i.LEFT)
	await tree.physics_frame
	_check(main._area is Hub, "volvió al hub")
	_check(fs.zones.is_empty(), "el bosque se borró")
	_check(gs.bag.count() == harvested and gs.storage.is_empty(),
		"volver no guarda solo: lo recolectado sigue en la mochila")
	_check(gs.deposit_resources() == harvested and gs.storage.count() == harvested and gs.bag.is_empty(),
		"guardar en el cofre: almacén tiene %d" % harvested)

	# Abrir el almacén pausa el juego
	main.inventory_ui.open_chest()
	_check(tree.paused, "el almacén pausa el juego")
	main.inventory_ui.close()
	_check(not tree.paused, "cerrar despausa")

	# Entrar otra vez: bosque nuevo
	main._handle_leave(Vector2i.RIGHT)
	await tree.physics_frame
	_check(fs.zones.size() == 1 and fs.run_seed != first_seed, "bosque nuevo con otra semilla")

	# --- Hito 2: reloj y energía -------------------------------------------
	var t0: float = Clock.total_minutes
	for i in 20:
		await tree.physics_frame
	_check(Clock.total_minutes > t0, "el reloj avanza")
	main.inventory_ui.open_chest()
	var t1: float = Clock.total_minutes
	for i in 10:
		await tree.process_frame
	_check(is_equal_approx(Clock.total_minutes, t1), "el reloj se pausa en menús")
	main.inventory_ui.close()

	# Golpear gasta energía (además del drenaje por tiempo)
	var e0: float = Energy.value
	for node in main._area.get_children():
		if node is Harvestable and node.entry.item != null and node.entry.min_tool_level == 0:
			node.interact(main.player)
			break
	_check(Energy.value <= e0 - Energy.ACTION_COST + 0.01, "golpear gasta energía")

	# Curva por hora
	var saved_time: float = Clock.total_minutes
	Clock.total_minutes = 1440 + 8 * 60  # 08:00
	_check(is_equal_approx(Clock.difficulty_multiplier(), 1.0) and Clock.rarity_bonus() == 0,
		"mañana: dificultad base")
	Clock.total_minutes = 1440 + 3 * 60  # 03:00
	_check(Clock.difficulty_multiplier() > 1.7 and Clock.rarity_bonus() == 3,
		"madrugada: pico (x%.2f, +%d)" % [Clock.difficulty_multiplier(), Clock.rarity_bonus()])
	_check(Clock.ambient_color().v < 0.7, "madrugada: el mundo se oscurece")
	Clock.total_minutes = saved_time

	# Rampa de energía
	Energy.set_value(45.0)
	_check(Energy.state == Energy.State.TIRED, "50%: cansado (solo aviso)")
	_check(Energy.speed_multiplier() == 1.0, "cansado no tiene debuff")
	Energy.set_value(15.0)
	_check(Energy.state == Energy.State.EXHAUSTED and Energy.speed_multiplier() < 1.0,
		"20%: agotado con debuff de velocidad")

	# Dormir: 5-9 h al azar, recarga proporcional
	Energy.set_value(30.0)
	var before_sleep: float = Clock.total_minutes
	main.sleep()
	await _wait_sleep(main)
	var slept_h: float = (Clock.total_minutes - before_sleep) / 60.0
	_check(slept_h >= 5.0 and slept_h <= 9.1, "dormir pasa 5-9 h (%.1f)" % slept_h)
	_check(Energy.value >= 30.0 + 5 * Energy.RECHARGE_PER_SLEEP_HOUR - 1.0, "dormir recarga energía")
	_check(not tree.paused, "despierta despausado")

	# Colapso en el bosque: pierde 25% de lo cargado, vuelve al hub y duerme
	_check(main._area is ForestZone, "(seguimos en el bosque)")
	var wood: ItemData = load("res://data/items/wood.tres")
	gs.deposit_resources()
	for i in 8:
		gs.bag.add(DNA.generar_recurso(wood, 0, gs.rng))
	Energy.set_value(0.0)
	await tree.process_frame
	await _wait_sleep(main)
	_check(main._area is Hub, "el colapso lleva al hub")
	_check(gs.bag.count() == 6, "colapso: le quedan 6 de 8 en la mochila (perdió 25%)")
	_check(fs.zones.is_empty(), "colapso: el bosque se borró")
	_check(Energy.value > 0.0 and Energy.state != Energy.State.COLLAPSED, "colapso: despierta con energía")

	# --- Hito 3: combate ----------------------------------------------------
	main._handle_leave(Vector2i.RIGHT)
	await tree.physics_frame
	_check(main._area is ForestZone, "combate: de vuelta en el bosque")
	var player: Player = main.player
	var enemy_entry: SpawnEntry = load("res://data/spawns/enemy_basic.tres")
	# Sacar enemigos naturales de la zona para que no interfieran
	for n in tree.get_nodes_in_group("enemy"):
		n.queue_free()
	await tree.process_frame

	# Arco: un enemigo a la derecha se golpea atacando a la derecha, no a la izquierda
	var ent := {"entry": enemy_entry, "tile": Vector2i.ZERO, "alive": true}
	var enemy := _spawn_enemy(main, ent, player.global_position + Vector2(14, 0))
	await tree.physics_frame
	player._attack_cd = 0.0
	player.attack(Vector2.LEFT)
	_check(enemy.health.current == Enemy.BASE_HEALTH, "atacar hacia el otro lado no pega")
	for i in Enemy.BASE_HEALTH:
		player._attack_cd = 0.0
		enemy.global_position = player.global_position + Vector2(14, 0)
		player.attack(Vector2.RIGHT)
	_check(ent.alive == false, "%d golpes matan al enemigo básico" % Enemy.BASE_HEALTH)
	var hp_bonus := Enemy.new()
	hp_bonus.setup({}, player, 6)
	_check(hp_bonus._max_health > Enemy.BASE_HEALTH, "más profundidad = enemigos con más vida")
	hp_bonus.free()

	# El enemigo pega (con amago) y deja i-frames
	player.revive()
	var ent2 := {"entry": enemy_entry, "tile": Vector2i.ZERO, "alive": true}
	var biter := _spawn_enemy(main, ent2, player.global_position + Vector2(8, 0))
	for i in 60:
		await tree.physics_frame
		if player.health.current < Player.MAX_HEALTH:
			break
	_check(player.health.current == Player.MAX_HEALTH - Enemy.DAMAGE, "el enemigo hace medio corazón de daño")
	_check(not player.take_hit(1, biter.global_position), "i-frames: no recibe dos golpes seguidos")
	biter.queue_free()

	# Dash: invulnerable mientras dura
	player.revive()
	await tree.physics_frame
	player._dash_cd = 0.0
	player.dash(Vector2.RIGHT)
	_check(player.is_dashing(), "dash activo")
	_check(not player.take_hit(1, player.global_position + Vector2(5, 0)), "dash con i-frames")
	for i in 20:
		await tree.physics_frame
	_check(not player.is_dashing() and not player.health.invulnerable, "el dash termina")

	# Muerte: pierde 50% de lo cargado, vuelve al hub con vida llena, sin dormir
	gs.deposit_resources()
	for i in 8:
		gs.bag.add(DNA.generar_recurso(wood, 0, gs.rng))
	var time_before_death: float = Clock.total_minutes
	player.health.take_damage(99)
	await tree.process_frame
	await _wait_sleep(main)
	_check(main._area is Hub, "la muerte lleva al hub")
	_check(gs.bag.count() == 4, "muerte: le quedan 4 de 8 en la mochila (perdió 50%)")
	_check(player.health.current == Player.MAX_HEALTH, "muerte: vuelve con la vida llena")
	_check(Clock.total_minutes - time_before_death < 60.0, "muerte: no duerme (no pasan horas)")

	# Animación: 8 direcciones -> filas de la hoja de BarrenRoots
	_check(Player.row_for(Vector2.DOWN) == 0 and Player.row_for(Vector2.UP) == 4
		and Player.row_for(Vector2.RIGHT) == 6 and Player.row_for(Vector2.LEFT) == 2
		and Player.row_for(Vector2(1, 1)) == 7 and Player.row_for(Vector2(-1, -1)) == 3,
		"direcciones -> filas de la hoja")

	# --- Hito 4: ítems e inventario -------------------------------------------
	var stone: ItemData = load("res://data/items/stone.tres")
	var iron: ItemData = load("res://data/items/iron.tres")
	gs.deposit_resources()
	_check(gs.bag.is_empty(), "inventario: mochila vacía tras guardar")

	# Grilla: la madera ocupa 1x2; 12 maderas llenan la grilla de 6x4
	var grid := GridInventory.new(Vector2i(6, 4))
	var first_wood := DNA.generar_recurso(wood, 0, gs.rng)
	grid.add(first_wood)
	_check(grid.item_at(Vector2i(0, 0)) == first_wood and grid.item_at(Vector2i(0, 1)) == first_wood,
		"la madera ocupa 1x2 celdas")
	for i in 11:
		grid.add(DNA.generar_recurso(wood, 0, gs.rng))
	_check(grid.count() == 12 and not grid.has_space(Vector2i.ONE), "12 maderas llenan la grilla 6x4")
	grid.remove(first_wood)
	_check(grid.has_space(Vector2i(1, 2)) and grid.add(DNA.generar_recurso(wood, 0, gs.rng)),
		"al sacar una entra otra")

	# ADN con stat invertido: más profundidad = MENOS peso
	var w0 := 0.0
	var w6 := 0.0
	for i in 300:
		w0 += DNA.generar_recurso(iron, 0, gs.rng).weight()
		w6 += DNA.generar_recurso(iron, 6, gs.rng).weight()
	_check(w6 < w0, "peso invertido: lo profundo pesa menos (%.2f vs %.2f)" % [w6 / 300, w0 / 300])

	# Mochila llena: no se puede recolectar (ni se gasta energía)
	for i in 12:
		gs.bag.add(DNA.generar_recurso(wood, 0, gs.rng))
	_check(not gs.can_carry(stone), "mochila llena")
	var rock_entry: SpawnEntry = load("res://data/spawns/rock.tres")
	var rock := Harvestable.new()
	rock.setup(rock_entry, {"alive": true}, 0)
	main._area.add_child(rock)
	var energy_before: float = Energy.value
	for i in 10:
		rock.interact(player)
	_check(is_instance_valid(rock) and not rock.is_queued_for_deletion(), "mochila llena: la roca no se rompe")
	_check(Energy.value >= energy_before - 0.01, "mochila llena: no gasta energía")
	rock.queue_free()

	# Guardar todo en el almacén / retirar
	var storage_count: int = gs.storage.count()
	var moved: int = gs.deposit_resources()
	_check(moved == 12 and gs.bag.is_empty() and gs.storage.count() == storage_count + 12,
		"guardar todos los recursos")
	var picked: ItemInstance = gs.storage.items().back()
	_check(gs.withdraw(picked) and gs.bag.has(picked) and not gs.storage.has(picked), "retirar del almacén")
	gs.deposit(picked)

	# Sobrepeso: más de 18 kg -> velocidad ×0.5
	_check(gs.speed_multiplier() == 1.0, "sin sobrepeso: velocidad normal")
	while gs.carried_weight() <= GameState.MAX_WEIGHT:
		gs.bag.add(DNA.generar_recurso(iron, 0, gs.rng))
	_check(gs.is_overweight() and gs.speed_multiplier() == GameState.OVERWEIGHT_SPEED_MULT,
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
	_check(lost_all == 4 and gs.bag.has(axe) and gs.bag.count() == 1, "perder 100%: el equipo se queda")
	gs.bag.remove(axe)

	# --- Inventario avanzado: rotar, mover, intercambiar, ordenar, tirar --------
	var ui: InventoryUI = main.inventory_ui
	var bag: GridInventory = gs.bag
	var log_a := DNA.generar_recurso(wood, 0, gs.rng)
	_check(log_a.grid_size() == Vector2i(1, 2), "madera parada: 1x2")
	log_a.rotated = true
	_check(log_a.grid_size() == Vector2i(2, 1), "madera rotada: 2x1")
	log_a.rotated = false

	ui.open_bag()
	# Agarrar y soltar en otro lugar
	bag.add_at(log_a, Vector2i(0, 0))
	ui.pick_up(bag, log_a)
	_check(ui.is_holding() and not bag.has(log_a), "agarrar saca el ítem de la grilla")
	ui.rotate_held()
	_check(ui.place_held(bag, Vector2i(3, 2)) and bag.position_of(log_a) == Vector2i(3, 2)
		and log_a.grid_size() == Vector2i(2, 1), "soltar rotado en otra posición")
	# Intercambio: soltar encima de UN ítem
	var pebble := DNA.generar_recurso(stone, 0, gs.rng)
	bag.add_at(pebble, Vector2i(0, 0))
	ui.pick_up(bag, log_a)
	_check(ui.place_held(bag, Vector2i(0, 0)) and bag.item_at(Vector2i(0, 0)) == log_a
		and ui.held_item() == pebble, "soltar encima intercambia")
	_check(ui.place_held(bag, bag.find_space(Vector2i.ONE)) and not ui.is_holding(),
		"soltar la piedra intercambiada en un lugar libre")
	# Cerrar con algo en la mano lo devuelve
	ui.pick_up(bag, pebble)
	ui.close()
	_check(not ui.is_holding() and bag.has(pebble), "cerrar con algo en la mano lo devuelve")
	# Rotar en el lugar
	ui.open_bag()
	bag.clear()
	var log_b := DNA.generar_recurso(wood, 0, gs.rng)
	bag.add_at(log_b, Vector2i(2, 1))
	_check(ui.rotate_in_place(bag, log_b) and log_b.grid_size() == Vector2i(2, 1), "rotar en el lugar")
	# Ordenar: grilla fragmentada donde la madera parada no entra hasta ordenar
	bag.clear()
	for x in 6:
		for y in [0, 2]:  # piedras en filas 0 y 2: ningún hueco vertical de 2
			bag.add_at(DNA.generar_recurso(stone, 0, gs.rng), Vector2i(x, y))
	_check(bag.find_space(Vector2i(1, 2)).x < 0 and bag.find_space(Vector2i(2, 1)).x >= 0,
		"fragmentada: no entra una madera parada")
	_check(bag.sort() and bag.find_space(Vector2i(1, 2)).x >= 0, "ordenar libera lugar para la madera")
	# Tirar
	var junk := bag.items()[0]
	var before_discard := bag.count()
	ui.pick_up(bag, junk)
	ui.discard_held()
	_check(bag.count() == before_discard - 1 and not ui.is_holding(), "tirar el ítem agarrado")
	ui.discard(bag, bag.items()[0])
	_check(bag.count() == before_discard - 2, "tirar el ítem bajo el mouse")
	ui.close()
	# Mochila <-> almacén lado a lado: mover a una posición elegida del almacén
	bag.clear()
	ui.open_chest()
	var log_c := DNA.generar_recurso(wood, 0, gs.rng)
	bag.add(log_c)
	var free: Vector2i = gs.storage.find_space(Vector2i(1, 2))
	ui.pick_up(bag, log_c)
	_check(ui.place_held(gs.storage, free) and gs.storage.position_of(log_c) == free,
		"arrastrar de la mochila al almacén")
	ui.quick_move(gs.storage, log_c)
	_check(bag.has(log_c) and not gs.storage.has(log_c), "Shift+clic: del almacén a la mochila")
	ui.close()
	bag.clear()
	# El almacén crece: siempre deja una fila libre
	var big := GridInventory.new(Vector2i(2, 2), true)
	for i in 6:
		big.add(DNA.generar_recurso(stone, 0, gs.rng))
	_check(big.count() == 6 and big.size.y >= 4, "el almacén crece (%d filas)" % big.size.y)
	var last_row_free := true
	for x in big.size.x:
		if big.item_at(Vector2i(x, big.size.y - 1)) != null:
			last_row_free = false
	_check(last_row_free and big.find_space(Vector2i(1, 2)).x >= 0,
		"el almacén siempre deja lugar para una madera parada")

	# UI: Tab abre la mochila y pausa
	main.inventory_ui.open_bag()
	_check(tree.paused and main.inventory_ui.is_open(), "la mochila pausa el juego")
	main.inventory_ui.close()
	_check(not tree.paused, "cerrar la mochila despausa")

	# --- Hito 5: herramientas, durabilidad y crafting ---------------------------
	bag.clear()
	gs.storage.clear()
	var tree_entry: SpawnEntry = load("res://data/spawns/tree.tres")
	var vein_entry: SpawnEntry = load("res://data/spawns/iron_vein.tres")
	var axe_recipe: RecipeData = load("res://data/recipes/stone_axe.tres")
	var pick_recipe: RecipeData = load("res://data/recipes/stone_pickaxe.tres")
	var sword_recipe: RecipeData = load("res://data/recipes/iron_sword.tres")

	# A mano: el árbol se puede, lento. La veta de hierro no.
	var tree_node := _spawn_harvestable(main, tree_entry)
	_check(tree_node.hits_left() == 4, "a mano: árbol en 4 golpes (%d)" % tree_node.hits_left())
	var vein := _spawn_harvestable(main, vein_entry)
	var e_vein: float = Energy.value
	vein.interact(player)
	_check(vein._hp == vein_entry.hardness and Energy.value >= e_vein - 0.01,
		"sin pico: la veta de hierro no se puede (ni gasta energía)")

	# Crafting: materiales en mochila y almacén; auto-selección = los de mejor calidad
	for i in 3:
		bag.add(DNA.generar_recurso(wood, 0, gs.rng))
	for i in 4:
		gs.storage.add(DNA.generar_recurso(wood, 0, gs.rng))
	for i in 6:
		gs.storage.add(DNA.generar_recurso(stone, i, gs.rng))
	var owned: Array[ItemInstance] = gs.owned_items()
	var sel := Crafting.auto_select(axe_recipe, owned)
	var best_wood: int = Crafting.candidates(axe_recipe, 0, owned)[0].quality
	_check(Crafting.is_complete(axe_recipe, sel) and sel[0][0].quality == best_wood,
		"auto-selección: los mejores materiales")
	_check(Crafting.preview(axe_recipe, {0: sel[0], 1: []}) == null, "selección incompleta: sin resultado")
	var prev := Crafting.preview(axe_recipe, sel)
	_check(prev.power() >= 2.1 and prev.power() <= 3.9 and prev.max_durability() >= 24.0
		and prev.durability == prev.max_durability(), "preview: stats dentro de los rangos de la receta")
	var owned_before: int = gs.owned_items().size()
	var axe_item := Crafting.craft(axe_recipe, sel)
	_check(axe_item != null and gs.owned_items().size() == owned_before - 4 + 1 and bag.has(axe_item),
		"craftear consume 4 materiales y el hacha va a la mochila")
	_check(is_equal_approx(axe_item.power(), prev.power()), "el resultado coincide con la vista previa")

	# Mejores materiales = mejor herramienta
	var hard_stones: Array[ItemInstance] = []
	var soft_stones: Array[ItemInstance] = []
	for i in 2:
		var h := DNA.generar_recurso(stone, 0, gs.rng)
		h.stats["dureza"] = 12.0
		hard_stones.append(h)
		var s2 := DNA.generar_recurso(stone, 0, gs.rng)
		s2.stats["dureza"] = 2.0
		soft_stones.append(s2)
	var two_wood: Array = sel[0]
	_check(Crafting.preview(axe_recipe, {0: two_wood, 1: hard_stones}).power()
		> Crafting.preview(axe_recipe, {0: two_wood, 1: soft_stones}).power(),
		"piedra más dura = hacha con más poder")

	# Con hacha: menos golpes y gasta durabilidad
	_check(gs.best_tool(&"axe") == axe_item, "el hacha de la mochila se usa sola")
	var hits_axe := tree_node.hits_left()
	_check(hits_axe < 4, "con hacha: menos golpes (%d)" % hits_axe)
	var dur0 := axe_item.durability
	tree_node.interact(player)
	_check(axe_item.durability == dur0 - 1, "cada golpe gasta 1 de durabilidad")

	# Pico: habilita la veta de hierro
	var pick_item := Crafting.craft(pick_recipe, Crafting.auto_select(pick_recipe, gs.owned_items()))
	_check(pick_item != null and pick_item.data.tool_level == 1, "pico de piedra fabricado (nivel 1)")
	vein.interact(player)
	_check(vein._hp < vein_entry.hardness, "con pico: la veta de hierro se puede picar")

	# Romper y reparar
	axe_item.durability = 1
	tree_node.interact(player)
	_check(axe_item.is_broken and gs.best_tool(&"axe") == null, "hacha rota: deja de usarse")
	_check(tree_node.hits_left() == ceili(tree_node._hp / Harvestable.HAND_POWER), "rota = como a mano")
	gs.storage.add(DNA.generar_recurso(stone, 0, gs.rng))
	var stones_before := Crafting.candidates(axe_recipe, 1, gs.owned_items()).size()
	_check(Crafting.repair(axe_item) and not axe_item.is_broken
		and axe_item.durability == axe_item.max_durability(), "reparar deja el hacha como nueva")
	_check(Crafting.candidates(axe_recipe, 1, gs.owned_items()).size() == stones_before - 1,
		"reparar consume 1 piedra")
	tree_node.queue_free()
	vein.queue_free()

	# Arma: el daño sale del poder de la espada, y se gasta al pegar
	var sword := ItemInstance.new(sword_recipe.result)
	sword.stats = {"poder": 3.0, "durabilidad": 50.0, "peso": 2.0}
	sword.repair_full()
	bag.add(sword)
	var ent3 := {"entry": enemy_entry, "tile": Vector2i.ZERO, "alive": true}
	var target := _spawn_enemy(main, ent3, player.global_position + Vector2(14, 0))
	player._attack_cd = 0.0
	player.attack(Vector2.RIGHT)
	_check(ent3.alive == false, "espada de poder 3: el enemigo básico cae de un golpe")
	_check(sword.durability == 49.0, "pegar gasta durabilidad de la espada")

	# UI de la mesa
	var cui: CraftingUI = main.crafting_ui
	cui.open()
	_check(tree.paused and cui.is_open(), "la mesa pausa el juego")
	cui.select_recipe(axe_recipe)
	var chosen_stone: ItemInstance = cui.selection()[1][0]
	cui.toggle_material(1, chosen_stone)
	_check(not cui.selection()[1].has(chosen_stone) and cui._craft_button.disabled,
		"quitar un material deshabilita Fabricar")
	cui.close()
	_check(not tree.paused, "cerrar la mesa despausa")
	bag.clear()
	gs.storage.clear()

	# --- Hito 6: noche, linterna y misiones ---------------------------------------
	var saved_clock: float = Clock.total_minutes
	var at := func(h: float) -> float:
		Clock.total_minutes = 1440.0 * 3 + h * 60.0
		return Clock.night_factor()
	_check(at.call(12.0) == 0.0 and is_equal_approx(at.call(19.5), 0.5) and at.call(23.0) == 1.0
		and is_equal_approx(at.call(4.0), 0.5) and at.call(6.0) == 0.0,
		"noche: se cierra 18-21, cerrada 21-03, se abre 03-05")

	# Visión: en el bosque de noche se achica; en el pueblo no hay oscuridad
	main._handle_leave(Vector2i.RIGHT)
	await tree.physics_frame
	at.call(23.0)
	await tree.process_frame
	await tree.process_frame  # process_frame se emite antes de los _process de ese frame
	_check(main._night_rect.visible and main.vision_radius() == main.VISION_NO_LIGHT,
		"de noche en el bosque: visión mínima sin linterna")
	for n in tree.get_nodes_in_group("enemy"):
		n.queue_free()

	# Linterna + aceite
	bag.clear()
	gs.storage.clear()
	_check(not gs.toggle_lantern(), "sin linterna no se prende")
	var lantern_recipe: RecipeData = load("res://data/recipes/lantern.tres")
	var oil_recipe: RecipeData = load("res://data/recipes/oil.tres")
	for i in 3:
		gs.storage.add(DNA.generar_recurso(stone, 0, gs.rng))
	for i in 5:
		gs.storage.add(DNA.generar_recurso(wood, 0, gs.rng))
	var lamp := Crafting.craft(lantern_recipe, Crafting.auto_select(lantern_recipe, gs.owned_items()))
	_check(lamp != null and lamp.stats.get("radio", 0.0) >= 80.0, "linterna fabricada (radio %d)" % lamp.stats.get("radio", 0))
	_check(not gs.toggle_lantern(), "sin aceite no se prende")
	var oil := Crafting.craft(oil_recipe, Crafting.auto_select(oil_recipe, gs.owned_items()))
	_check(oil != null and oil.max_durability() >= 90.0 and oil.durability == oil.max_durability(),
		"aceite fabricado (%d min)" % oil.max_durability())
	_check(not Crafting.needs_repair(oil), "el aceite no aparece para reparar")
	_check(gs.toggle_lantern() and main.vision_radius() == lamp.stats.radio, "linterna prendida: más visión")
	var oil_before := oil.durability
	gs.burn_oil(30.0)
	_check(is_equal_approx(oil.durability, oil_before - 30.0), "la linterna gasta aceite con el reloj")
	gs.burn_oil(9999.0)
	_check(not bag.has(oil) and not gs.lantern_on, "sin aceite: el frasco desaparece y se apaga")
	var lost_oil := Crafting.craft(oil_recipe, Crafting.auto_select(oil_recipe, gs.owned_items()))
	gs.toggle_lantern()
	main._handle_leave(Vector2i.LEFT)  # zona (0,0) -> pueblo
	await tree.physics_frame
	await tree.process_frame
	await tree.process_frame
	_check(main._area is Hub and not gs.lantern_on and not main._night_rect.visible,
		"en el pueblo: linterna apagada y sin oscuridad")
	_check(bag.has(lamp) and bag.has(lost_oil), "linterna y aceite siguen en la mochila")
	Clock.total_minutes = saved_clock

	# Misiones
	var missions: Node = Missions
	missions.reset()
	_check(missions.active.size() == 3, "el tablón tiene 3 misiones")
	var hunt: Mission = null
	var deliver: Mission = null
	var reach: Mission = null
	for m: Mission in missions.active:
		match m.kind:
			Mission.Kind.HUNT: hunt = m
			Mission.Kind.DELIVER: deliver = m
			Mission.Kind.REACH_DEPTH: reach = m
	_check(hunt and deliver and reach, "una de cada tipo")
	# Cazar: cuenta enemigos derrotados
	hunt.reward = &"weight"
	_check(not missions.claim(hunt), "no se puede reclamar sin cumplir")
	for i in hunt.target:
		missions.on_enemy_killed()
	var weight_before: float = gs.max_weight()
	_check(hunt.is_complete() and missions.claim(hunt) and gs.max_weight() == weight_before + GameState.UPGRADE_WEIGHT,
		"cazar: cumplida, +2 kg de capacidad")
	_check(missions.active.size() == 3 and not missions.active.has(hunt) and missions.completed == 1,
		"aparece una misión nueva")
	# Profundidad: se cumple al pisar una zona lejana
	reach.reward = &"energy"
	missions._on_zone_entered(Vector2i(reach.target, 0))
	var energy_max_before: float = Energy.max_value()
	_check(missions.claim(reach) and Energy.max_value() == energy_max_before + GameState.UPGRADE_ENERGY,
		"profundidad: cumplida, +10 de energía máxima")
	# Entregar: consume los ejemplares que cumplen la calidad
	deliver.reward = &"health"
	deliver.item = stone
	deliver.count = 2
	deliver.min_quality = 0
	gs.storage.clear()
	gs.storage.add(DNA.generar_recurso(stone, 0, gs.rng))
	_check(not deliver.is_complete(), "entregar: falta material")
	gs.storage.add(DNA.generar_recurso(stone, 0, gs.rng))
	var hp_max_before: int = player.health.max_health
	_check(missions.claim(deliver) and gs.storage.is_empty(), "entregar: consume las piedras")
	_check(player.health.max_health == hp_max_before + 2 and main.hud._hearts.get_child_count() == player.health.max_health / 2,
		"+1 corazón: vida máxima y HUD actualizados")
	# UI del tablón
	main.board_ui.open()
	_check(tree.paused and main.board_ui.is_open(), "el tablón pausa el juego")
	main.board_ui.close()
	bag.clear()

	# --- Hito 7: guardado, menús ---------------------------------------------------
	_check(main.is_in_hub() and SaveSystem.has_save(), "llegar al pueblo autoguarda")
	# Armar un estado reconocible
	bag.clear()
	gs.storage.clear()
	var s_log := DNA.generar_recurso(wood, 4, gs.rng)
	s_log.rotated = true
	bag.add_at(s_log, Vector2i(2, 3))
	var s_axe := Crafting.preview(axe_recipe, {0: [DNA.generar_recurso(wood, 0, gs.rng),
		DNA.generar_recurso(wood, 0, gs.rng)], 1: hard_stones})
	s_axe.durability = 7.0
	bag.add_at(s_axe, Vector2i(0, 0))
	for i in 25:  # suficiente para que el almacén crezca
		gs.storage.add(DNA.generar_recurso(stone, i % 5, gs.rng))
	var s_storage_rows: int = gs.storage.size.y
	var s_bonus_w: float = gs.bonus_weight
	var s_bonus_h: int = gs.bonus_health
	Clock.total_minutes = 1440 * 4 + 15 * 60 + 30
	Energy.set_value(42.0)
	player.health.current = 3
	missions.on_enemy_killed()
	var s_hunt_progress := 0
	for m: Mission in missions.active:
		if m.kind == Mission.Kind.HUNT:
			s_hunt_progress = m.progress
	var s_completed: int = missions.completed
	var s_titles: Array = missions.active.map(func(m: Mission) -> String: return m.title())
	_check(main.autosave(), "guardar en el pueblo")

	# Romper todo y cargar
	SaveSystem.new_game()
	_check(bag.is_empty() and gs.storage.is_empty() and gs.bonus_weight == 0.0
		and missions.completed == 0, "partida nueva: todo a cero")
	_check(SaveSystem.load_game(), "cargar el guardado")
	var l_log: ItemInstance = bag.item_at(Vector2i(2, 3))
	_check(l_log != null and l_log.rotated and l_log.data == wood and _same_stats(l_log.stats, s_log.stats)
		and l_log.quality == s_log.quality and bag.position_of(l_log) == Vector2i(2, 3),
		"madera: misma posición, rotación, ADN y calidad")
	var l_axe: ItemInstance = bag.item_at(Vector2i(0, 0))
	_check(l_axe != null and l_axe.data == s_axe.data and l_axe.durability == 7.0
		and is_equal_approx(l_axe.power(), s_axe.power()), "hacha: tipo, poder y durabilidad")
	_check(gs.storage.count() == 25 and gs.storage.size.y == s_storage_rows, "almacén: 25 ítems y su tamaño")
	_check(gs.bonus_weight == s_bonus_w and gs.bonus_health == s_bonus_h, "mejoras permanentes")
	_check(Clock.total_minutes == 1440 * 4 + 15 * 60 + 30 and is_equal_approx(Energy.value, 42.0),
		"hora y energía")
	_check(SaveSystem.pending_health == 3, "vida guardada (la aplica Main al crearse)")
	var l_hunt_progress := -1
	for m: Mission in missions.active:
		if m.kind == Mission.Kind.HUNT:
			l_hunt_progress = m.progress
	_check(missions.completed == s_completed and l_hunt_progress == s_hunt_progress
		and missions.active.map(func(m: Mission) -> String: return m.title()) == s_titles,
		"misiones: las mismas, con su progreso")
	SaveSystem.pending_health = -1

	# En el bosque no se guarda
	var save_time := FileAccess.get_modified_time(ProjectSettings.globalize_path(SaveSystem.save_path))
	main._handle_leave(Vector2i.RIGHT)
	await tree.physics_frame
	_check(not main.autosave(), "en el bosque no se guarda")
	_check(FileAccess.get_modified_time(ProjectSettings.globalize_path(SaveSystem.save_path)) == save_time,
		"el archivo no cambió")
	for n in tree.get_nodes_in_group("enemy"):
		n.queue_free()

	# Guardado roto: no rompe el juego
	var f := FileAccess.open(SaveSystem.save_path, FileAccess.WRITE)
	f.store_string("{esto no es json")
	f.close()
	var bag_count_before: int = bag.count()
	_check(not SaveSystem.load_game() and bag.count() == bag_count_before,
		"guardado ilegible: no carga y no toca el estado")

	# Menús
	main.pause_menu.open(false)
	_check(tree.paused and main.pause_menu.is_open(), "el menú de pausa pausa")
	main.pause_menu.close()
	_check(not tree.paused, "cerrar la pausa")
	SaveSystem.delete_save()
	var menu: Control = load("res://scenes/MainMenu.tscn").instantiate()
	root.add_child(menu)
	_check(menu._continue.disabled, "menú: sin guardado, Continuar deshabilitado")
	menu.queue_free()

	# Dejar correr algunos frames reales
	for i in 30:
		await tree.physics_frame

	SaveSystem.delete_save()
	print("RESULTADO: ", "OK" if _failures == 0 else "%d FALLAS" % _failures)
	tree.quit(1 if _failures > 0 else 0)


func _spawn_enemy(main: Node, ent: Dictionary, pos: Vector2) -> Enemy:
	var enemy := Enemy.new()
	enemy.setup(ent, main.player, 0)
	main._area.add_child(enemy)
	enemy.global_position = pos
	return enemy


func _spawn_harvestable(main: Node, entry: SpawnEntry) -> Harvestable:
	var h := Harvestable.new()
	h.setup(entry, {"alive": true}, 0)
	main._area.add_child(h)
	h.global_position = main.player.global_position + Vector2(40, 40)
	return h


func _same_stats(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for k in a:
		if not b.has(k) or not is_equal_approx(float(a[k]), float(b[k])):
			return false
	return true


func _wait_sleep(main: Node) -> void:
	var tree := get_tree()
	for i in 600:  # ~10 s de margen
		if not main.is_sleeping():
			return
		await tree.process_frame
	_check(false, "dormir no terminó a tiempo")


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL ") + msg)
	if not cond:
		_failures += 1
