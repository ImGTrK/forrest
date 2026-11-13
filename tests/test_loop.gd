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

	# Dejar correr algunos frames reales
	for i in 30:
		await tree.physics_frame

	print("RESULTADO: ", "OK" if _failures == 0 else "%d FALLAS" % _failures)
	tree.quit(1 if _failures > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL ") + msg)
	if not cond:
		_failures += 1
