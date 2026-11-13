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
		if node is Harvestable and node.entry.item != null:
			for i in node.entry.hits:
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
		if node is Harvestable and node.entry.item != null:
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
	for i in rock_entry.hits:
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
	_check(last_row_free, "el almacén deja una fila libre abajo")

	# UI: Tab abre la mochila y pausa
	main.inventory_ui.open_bag()
	_check(tree.paused and main.inventory_ui.is_open(), "la mochila pausa el juego")
	main.inventory_ui.close()
	_check(not tree.paused, "cerrar la mochila despausa")

	# Dejar correr algunos frames reales
	for i in 30:
		await tree.physics_frame

	print("RESULTADO: ", "OK" if _failures == 0 else "%d FALLAS" % _failures)
	tree.quit(1 if _failures > 0 else 0)


func _spawn_enemy(main: Node, ent: Dictionary, pos: Vector2) -> Enemy:
	var enemy := Enemy.new()
	enemy.setup(ent, main.player, 0)
	main._area.add_child(enemy)
	enemy.global_position = pos
	return enemy


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
