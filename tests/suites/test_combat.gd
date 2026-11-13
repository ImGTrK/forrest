extends TestSuite
## Ataque en arco, enemigo básico, i-frames, dash y muerte.


func run() -> void:
	var gs: Node = GameState
	await go_to_forest()
	check(main._area is ForestZone, "en el bosque")
	var p := player()
	await clear_enemies()

	# Arco: un enemigo a la derecha se golpea atacando a la derecha, no a la izquierda
	var ent := enemy_entity()
	var enemy := spawn_enemy(ent, p.global_position + Vector2(14, 0))
	await tree.physics_frame
	p._attack_cd = 0.0
	p.attack(Vector2.LEFT)
	check(enemy.health.current == EnemyBasic.BASE_HEALTH, "atacar hacia el otro lado no pega")
	for i in EnemyBasic.BASE_HEALTH:
		p._attack_cd = 0.0
		enemy.global_position = p.global_position + Vector2(14, 0)
		p.attack(Vector2.RIGHT)
	check(ent.alive == false, "%d golpes matan al enemigo básico" % EnemyBasic.BASE_HEALTH)
	var hp_bonus := EnemyBasic.new()
	hp_bonus.setup({}, p, 6)
	check(hp_bonus._max_health > EnemyBasic.BASE_HEALTH, "más profundidad = enemigos con más vida")
	hp_bonus.free()

	# El enemigo pega (con amago) y deja i-frames
	p.revive()
	var biter := spawn_enemy(enemy_entity(), p.global_position + Vector2(8, 0))
	for i in 60:
		await tree.physics_frame
		if p.health.current < Player.MAX_HEALTH:
			break
	check(p.health.current == Player.MAX_HEALTH - EnemyBasic.DAMAGE, "el enemigo hace medio corazón de daño")
	check(not p.take_hit(1, biter.global_position), "i-frames: no recibe dos golpes seguidos")
	biter.queue_free()

	# Dash: invulnerable mientras dura
	p.revive()
	await tree.physics_frame
	p._dash_cd = 0.0
	p.dash(Vector2.RIGHT)
	check(p.is_dashing(), "dash activo")
	check(not p.take_hit(1, p.global_position + Vector2(5, 0)), "dash con i-frames")
	await wait_frames(20)
	check(not p.is_dashing() and not p.health.invulnerable, "el dash termina")

	# Muerte: pierde 50% de lo cargado, vuelve al pueblo con vida llena, sin dormir
	gs.deposit_resources()
	for i in 8:
		gs.bag.add(roll("wood"))
	var time_before_death: float = Clock.total_minutes
	p.health.take_damage(99)
	await tree.process_frame
	await wait_sleep()
	check(main._area is Hub, "la muerte lleva al pueblo")
	check(gs.bag.count() == 4, "muerte: le quedan 4 de 8 en la mochila (perdió 50%)")
	check(p.health.current == Player.MAX_HEALTH, "muerte: vuelve con la vida llena")
	check(Clock.total_minutes - time_before_death < 60.0, "muerte: no duerme (no pasan horas)")

	# Animación: 8 direcciones -> filas de la hoja
	check(Player.row_for(Vector2.DOWN) == 0 and Player.row_for(Vector2.UP) == 4
		and Player.row_for(Vector2.RIGHT) == 6 and Player.row_for(Vector2.LEFT) == 2
		and Player.row_for(Vector2(1, 1)) == 7 and Player.row_for(Vector2(-1, -1)) == 3,
		"direcciones -> filas de la hoja")
