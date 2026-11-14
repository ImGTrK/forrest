extends TestSuite
## Hito 10: Lanzador, Embestidor, proyectiles, hoja estándar, feedback y audio.


func run() -> void:
	var p := player()
	await go_to_forest()
	await clear_enemies()
	Fx.reset()

	# --- Datos: los tres enemigos salen de su .tres con su script -----------------------
	for id in ["enemy_basic", "enemy_spitter", "enemy_charger"]:
		var e := spawn_entry(id)
		var inst := ForestZone.make_enemy(e)
		check(inst is Enemy and inst.vframes == 4 and inst.hframes == 4,
			"%s: hijo de Enemy con hoja estándar 4×4" % id)
		check(e.texture.get_size() == Vector2(64, 64), "%s: la hoja mide 64×64" % id)
		inst.free()
	check(spawn_entry("enemy_spitter").min_depth > spawn_entry("enemy_basic").min_depth
		and spawn_entry("enemy_charger").min_depth > spawn_entry("enemy_spitter").min_depth,
		"aparecen en orden: erizo, Lanzador, Embestidor")

	# --- Lanzador: apunta, dispara una espora y huye de cerca ------------------------------
	p.revive()
	var ent := {"entry": spawn_entry("enemy_spitter"), "tile": Vector2i.ZERO, "alive": true}
	var spitter: EnemySpitter = spawn_enemy(ent, p.global_position + Vector2(70, 0), EnemySpitter.new())
	var proj: Projectile = null
	var aimed := false
	for i in 120:
		await tree.physics_frame
		if spitter.state == Enemy.State.WINDUP:
			aimed = spitter.aim.x < -0.9  # el jugador está a la izquierda
		var list := tree.get_nodes_in_group("projectile")
		if not list.is_empty():
			proj = list[0]
			break
	check(aimed, "Lanzador: el amago apunta al jugador")
	check(proj != null, "Lanzador: dispara una espora")
	if proj:
		check(proj.velocity.x < 0.0 and absf(proj.velocity.y) < 5.0, "la espora vuela hacia el jugador")
		for i in 90:
			await tree.physics_frame
			if not is_instance_valid(proj) or p.health.current < p.health.max_health:
				break
		check(p.health.current == p.health.max_health - EnemySpitter.DAMAGE, "la espora pega medio corazón")
	# De cerca huye
	p.revive()
	spitter.global_position = p.global_position + Vector2(20, 0)
	spitter.state = Enemy.State.CHASE
	var v := spitter._chase_velocity(p.global_position - spitter.global_position, 20.0)
	check(v.x > 0.0, "Lanzador: si te acercás, huye")
	spitter.queue_free()
	for n in tree.get_nodes_in_group("projectile"):
		n.queue_free()

	# Proyectil: el dash lo atraviesa, contra el mundo se rompe
	p.revive()
	await wait_frames(40)  # i-frames del golpe anterior
	p._dash_cd = 0.0
	p.dash(Vector2.UP)
	var dodge := Projectile.spawn(main._area, p.position + Vector2(-12, 0), Vector2(300, 0), 1)
	await wait_frames(4)
	check(p.health.current == p.health.max_health and is_instance_valid(dodge) and not dodge.is_done(),
		"dash: la espora pasa de largo sin pegar")
	await wait_frames(20)
	var wall := Projectile.spawn(main._area, Vector2(8, 8), Vector2(-200, 0), 1)  # contra el cerco
	await wait_frames(10)
	check(not is_instance_valid(wall) or wall.is_done(), "la espora se rompe contra el cerco")
	if is_instance_valid(dodge):
		dodge.queue_free()

	# --- Embestidor: amago largo, embiste recto, se aturde al chocar -----------------------
	p.revive()
	await wait_frames(40)
	var cent := {"entry": spawn_entry("enemy_charger"), "tile": Vector2i.ZERO, "alive": true}
	var charger: EnemyCharger = spawn_enemy(cent, p.global_position + Vector2(60, 0), EnemyCharger.new())
	var saw_windup := false
	var saw_charge := false
	for i in 150:
		await tree.physics_frame
		saw_windup = saw_windup or charger.state == Enemy.State.WINDUP
		if charger.is_charging():
			saw_charge = true
			break
	check(saw_windup and saw_charge, "Embestidor: raspa (amago) y después embiste")
	check(charger.charge_dir.x < -0.9, "embiste en línea recta hacia donde estaba el jugador")
	# En plena embestida un golpe no lo frena
	charger.take_hit(1, Vector2(300, 0))
	check(charger.is_charging(), "en plena embestida los golpes no lo frenan")
	for i in 60:
		await tree.physics_frame
		if p.health.current < p.health.max_health or not charger.is_charging():
			break
	check(p.health.current == p.health.max_health - EnemyCharger.DAMAGE, "la embestida pega un corazón entero")
	# Choque contra el mundo: aturdido
	charger.crash()
	check(charger.state == Enemy.State.STUNNED, "al chocar queda aturdido")
	var hp := charger.health.current
	charger.take_hit(1, Vector2(100, 0))
	check(charger.health.current == hp - 1, "aturdido se le puede pegar")
	charger.queue_free()

	# --- Hoja estándar: el frame sigue al estado ------------------------------------------
	var basic := spawn_enemy(enemy_entity(), p.global_position + Vector2(0, 90))
	await tree.physics_frame
	basic.state = Enemy.State.WINDUP
	basic._t = 0.3
	basic._update_visual(0.01)
	check(basic._sprite.frame / 4 == Enemy.ROW_ATTACK, "amago: fila de ataque")
	basic.state = Enemy.State.IDLE
	basic.velocity = Vector2.ZERO
	basic._update_visual(0.01)
	check(basic._sprite.frame / 4 == Enemy.ROW_IDLE, "quieto: fila 0")

	# --- Feedback: número, partículas, freno, barra y muerte animada ------------------------
	Fx.reset()
	var before: int = main._area.get_child_count()
	AudioManager._last.clear()  # que no lo frene el anti-repetición del golpe anterior
	var played_hit: int = AudioManager.played.get(&"hit", 0)
	basic.take_hit(1, Vector2.ZERO)
	check(main._area.get_child_count() > before, "golpe: aparecen número y partículas en la zona")
	check(Fx.is_stopped() and Fx.trauma() > 0.0, "golpe: freno y sacudida de cámara")
	check(AudioManager.played.get(&"hit", 0) > played_hit, "golpe: suena")
	var t0 := Time.get_ticks_msec()
	while Fx.is_stopped() and Time.get_ticks_msec() - t0 < 500:
		await tree.process_frame
	check(not Fx.is_stopped(), "el freno dura un instante y se suelta solo")
	check(basic.health.current < basic.health.max_health, "herido: muestra la barra de vida")
	basic.take_hit(99, Vector2.ZERO)
	check(basic.is_dead() and is_instance_valid(basic), "al morir no desaparece de golpe (anima)")
	await wait_frames(int(Enemy.DEATH_TIME * 60.0) + 10)
	check(not is_instance_valid(basic), "después de la animación de muerte se borra")

	# --- Jugador: pose del muñeco y estela del dash -------------------------------------------
	p.revive()
	await wait_frames(2)
	p._attack_cd = 0.0
	p.attack(Vector2.RIGHT)
	await wait_frames(5)
	check(p.sprite.scale.x > Player.SPRITE_SCALE, "ataque: el sprite se estira hacia el golpe")
	await wait_frames(20)
	check(is_equal_approx(p.sprite.scale.x, Player.SPRITE_SCALE), "después del ataque vuelve a la pose normal")
	p._dash_cd = 0.0
	p.dash(Vector2.LEFT)
	await wait_frames(4)
	check(not tree.get_nodes_in_group("afterimage").is_empty(), "dash: deja estela")

	# --- Recolección: astillas y sonido ---------------------------------------------------
	var tree_node := spawn_harvestable(spawn_entry("tree"))
	AudioManager._last.clear()
	var chops: int = AudioManager.played.get(&"chop", 0)
	tree_node.interact(p)
	check(AudioManager.played.get(&"chop", 0) > chops, "talar: suena el hachazo")
	check(spawn_harvestable(spawn_entry("rock")).chip_colors()[0] != tree_node.chip_colors()[0],
		"piedra y madera sueltan astillas distintas")

	# --- Audio: buses y sonidos sintetizados ------------------------------------------------
	for bus in AudioManager.BUSES:
		check(AudioServer.get_bus_index(bus) >= 0, "bus de audio %s" % bus)
	var ok := true
	for id: StringName in SfxSynth.RECIPES:
		var streams := AudioManager.streams_for(id)
		ok = ok and streams.size() >= 2 and streams[0] is AudioStreamWAV and streams[0].data.size() > 100
	check(ok, "cada efecto tiene variantes generadas")
	AudioManager.set_bus_volume(&"SFX", 0.5)
	check(absf(AudioManager.get_bus_volume(&"SFX") - 0.5) < 0.01, "volumen por bus")
	AudioManager.set_bus_volume(&"SFX", 1.0)
	Fx.reset()
