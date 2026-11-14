extends TestSuite
## Clases base del hito 8: Interactable, Enemy (y sus hijos) y el componente HitFlash.


## Enemigo de prueba: demuestra que un hijo puede cambiar cómo ataca y qué suelta
## sin tocar la base. Ataque a distancia (no necesita estar pegado) e inamovible.
class TestEnemy extends Enemy:
	var attacks := 0
	var dropped := false

	func _init() -> void:
		attack_range = 60.0
		windup_time = 0.05
		base_health = 2

	func _attack(_to_player: Vector2, _dist: float) -> void:
		attacks += 1

	func _drop() -> void:
		dropped = true

	func _knockback_scale() -> float:
		return 0.0


func run() -> void:
	var p := player()

	# --- Interactable: todo lo del pueblo hereda de la misma base ---------------------
	var props := {}
	for node in main._area.get_children():
		if node is Interactable and not node is Harvestable:  # props (la decoración va aparte)
			props[node.get_script().get_global_name()] = node
	check(props.has(&"Chest") and props.has(&"Bed") and props.has(&"Bench") and props.has(&"Board"),
		"cofre, cama, mesa y tablón son Interactable (%s)" % ", ".join(props.keys()))
	var in_group := true
	for node: Interactable in props.values():
		in_group = in_group and node.is_in_group("interactable")
	check(in_group, "todos entran al grupo que busca el jugador")
	var deco := 0
	var choppable := 0
	for node in main._area.get_children():
		if node is Harvestable:
			deco += 1
			if node.is_in_group("interactable"):
				choppable += 1
	check(deco >= 10 and choppable == 0, "el pueblo tiene decoración (%d) y nada para talar" % deco)
	var board: Board = props[&"Board"]
	var legs := board._collision_rect()
	check(legs.size.y < board.size.y and legs.end.y == board.size.y, "tablón: solo las patas bloquean")

	# Usar la mesa con E abre el crafting (señal `used` heredada → Hub → Main)
	props[&"Bench"].interact(p)
	check(main.crafting_ui.is_open(), "interactuar con la mesa abre el crafting")
	main.crafting_ui.close()
	props[&"Chest"].interact(p)
	check(main.inventory_ui.is_open(), "interactuar con el cofre abre el almacén")
	main.inventory_ui.close()

	# Foco: el jugador al lado de la mesa la enfoca
	p.teleport(props[&"Bench"].global_position + Vector2(16, 24))
	await tree.physics_frame
	await tree.physics_frame
	check(p._focus == props[&"Bench"] and props[&"Bench"]._focused, "el jugador enfoca la mesa al acercarse")

	# Recursos: Harvestable también es Interactable; la decoración no se puede usar
	var tree_node := spawn_harvestable(spawn_entry("tree"))
	var bush := spawn_harvestable(spawn_entry("bush"))
	check(tree_node is Interactable and tree_node.is_in_group("interactable"), "el árbol es Interactable")
	check(bush is Interactable and not bush.is_in_group("interactable"), "el arbusto decorativo no se puede usar")
	tree_node.interact(p)
	check(tree_node._flash.is_active(), "golpear un recurso dispara su HitFlash")
	await wait_frames(20)
	check(not tree_node._flash.is_active() and tree_node._sprite.modulate == Color.WHITE,
		"el destello se apaga solo")
	tree_node.queue_free()
	bush.queue_free()

	# --- Enemy: el tipo sale del SpawnEntry -------------------------------------------
	var basic := ForestZone.make_enemy(spawn_entry("enemy_basic"))
	check(basic is EnemyBasic and basic is Enemy, "enemy_basic.tres crea un EnemyBasic (hijo de Enemy)")
	basic.free()
	var no_script := SpawnEntry.new()
	no_script.is_enemy = true
	var fallback := ForestZone.make_enemy(no_script)
	check(fallback is EnemyBasic, "sin script: EnemyBasic por defecto")
	fallback.free()

	# Un hijo cambia ataque, drop y knockback sobrescribiendo métodos
	await go_to_forest()
	await clear_enemies()
	var ent := enemy_entity()
	var custom := TestEnemy.new()
	spawn_enemy(ent, p.global_position + Vector2(40, 0), custom)
	for i in 30:
		await tree.physics_frame
		if custom.attacks > 0:
			break
	check(custom.attacks > 0 and p.health.current == p.health.max_health,
		"hijo con _attack propio: ataca a 40 px y sin morder")
	var pos_before := custom.global_position
	custom.take_hit(1, Vector2(500, 0))
	await wait_frames(3)
	check(custom.global_position.distance_to(pos_before) < 4.0, "hijo con _knockback_scale 0: no lo empujan")
	check(custom.health.current == 1 and custom._flash.is_active(), "recibe daño con destello (base)")
	custom.take_hit(1, Vector2.ZERO)
	check(custom.is_dead() and custom.dropped and ent.alive == false, "al morir llama a _drop() y marca la zona")
