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
		if node is Harvestable and node.entry.resource_type != null:
			for i in node.entry.hits:
				node.interact(main.player)
			harvested += 1
	_check(harvested > 0, "había algo para recolectar")
	_check(gs.run_inventory.size() == harvested, "inventario de run = %d" % harvested)

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
		if node is Harvestable and node.entry.resource_type != null:
			alive_harvestables += 1
	_check(alive_harvestables == 0, "lo recolectado no reaparece (%d vivos)" % alive_harvestables)

	# Volver al hub por el oeste de (0,0)
	main._handle_leave(Vector2i.LEFT)
	await tree.physics_frame
	_check(main._area is Hub, "volvió al hub")
	_check(fs.zones.is_empty(), "el bosque se borró")
	_check(gs.run_inventory.is_empty(), "inventario de run vacío")
	_check(gs.storage.size() == harvested, "almacén tiene %d" % harvested)

	# Abrir el almacén pausa el juego
	main.storage_ui.open_storage()
	_check(tree.paused, "el almacén pausa el juego")
	main.storage_ui.close()
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
	main.storage_ui.open_storage()
	var t1: float = Clock.total_minutes
	for i in 10:
		await tree.process_frame
	_check(is_equal_approx(Clock.total_minutes, t1), "el reloj se pausa en menús")
	main.storage_ui.close()

	# Golpear gasta energía (además del drenaje por tiempo)
	var e0: float = Energy.value
	for node in main._area.get_children():
		if node is Harvestable and node.entry.resource_type != null:
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
	var wood: ResourceType = load("res://data/resources/wood.tres")
	for i in 8:
		gs.run_inventory.append(DNA.generar_recurso(wood, 0, gs.rng))
	var storage_before: int = gs.storage.size()
	Energy.set_value(0.0)
	await tree.process_frame
	await _wait_sleep(main)
	_check(main._area is Hub, "el colapso lleva al hub")
	_check(gs.storage.size() == storage_before + 6, "colapso: guardó 6 de 8 (perdió 25%)")
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
	for i in 8:
		gs.run_inventory.append(DNA.generar_recurso(wood, 0, gs.rng))
	var storage_before_death: int = gs.storage.size()
	var time_before_death: float = Clock.total_minutes
	player.health.take_damage(99)
	await tree.process_frame
	await _wait_sleep(main)
	_check(main._area is Hub, "la muerte lleva al hub")
	_check(gs.storage.size() == storage_before_death + 4, "muerte: guardó 4 de 8 (perdió 50%)")
	_check(player.health.current == Player.MAX_HEALTH, "muerte: vuelve con la vida llena")
	_check(Clock.total_minutes - time_before_death < 60.0, "muerte: no duerme (no pasan horas)")

	# Animación: 8 direcciones -> filas de la hoja de BarrenRoots
	_check(Player.row_for(Vector2.DOWN) == 0 and Player.row_for(Vector2.UP) == 4
		and Player.row_for(Vector2.RIGHT) == 6 and Player.row_for(Vector2.LEFT) == 2
		and Player.row_for(Vector2(1, 1)) == 7 and Player.row_for(Vector2(-1, -1)) == 3,
		"direcciones -> filas de la hoja")

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
