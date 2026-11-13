class_name TestSuite
extends Node
## Base de cada suite de tests. El runner (tests/run_tests.gd) le da un Main recién creado
## (partida nueva, arrancando en el pueblo) y llama a run(). Cada suite es independiente:
## no depende de lo que haya hecho otra.
##
## Para agregar una suite: crear tests/suites/test_<sistema>.gd con `extends TestSuite`,
## implementar run() y sumarla a SUITES en run_tests.gd.

var main: Node
var tree: SceneTree
var failures := 0
var checks := 0


## Sobrescribir. Puede usar await.
func run() -> void:
	pass


func check(cond: bool, msg: String) -> void:
	checks += 1
	print(("  ok   " if cond else "  FAIL ") + msg)
	if not cond:
		failures += 1


# --- Helpers -------------------------------------------------------------------

func player() -> Player:
	return main.player


func item(id: String) -> ItemData:
	return load("res://data/items/%s.tres" % id)


func spawn_entry(id: String) -> SpawnEntry:
	return load("res://data/spawns/%s.tres" % id)


func recipe(id: String) -> RecipeData:
	return load("res://data/recipes/%s.tres" % id)


func roll(id: String, depth := 0) -> ItemInstance:
	return DNA.generar_recurso(item(id), depth, GameState.rng)


## Del pueblo al bosque (zona 0,0).
func go_to_forest() -> void:
	main._handle_leave(Vector2i.RIGHT)
	await tree.physics_frame


## De la zona (0,0) al pueblo.
func go_to_hub() -> void:
	main._handle_leave(Vector2i.LEFT)
	await tree.physics_frame


## Saca los enemigos naturales de la zona para que no interfieran.
func clear_enemies() -> void:
	for n in tree.get_nodes_in_group("enemy"):
		n.queue_free()
	await tree.process_frame


func spawn_enemy(ent: Dictionary, pos: Vector2, enemy: Enemy = null) -> Enemy:
	if enemy == null:
		enemy = EnemyBasic.new()
	enemy.setup(ent, player(), 0)
	main._area.add_child(enemy)
	enemy.global_position = pos
	return enemy


func enemy_entity() -> Dictionary:
	return {"entry": spawn_entry("enemy_basic"), "tile": Vector2i.ZERO, "alive": true}


func spawn_harvestable(entry: SpawnEntry) -> Harvestable:
	var h := Harvestable.new()
	h.setup(entry, {"alive": true}, 0)
	main._area.add_child(h)
	h.global_position = player().global_position + Vector2(40, 40)
	return h


func same_stats(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for k in a:
		if not b.has(k) or not is_equal_approx(float(a[k]), float(b[k])):
			return false
	return true


func wait_sleep() -> void:
	for i in 600:  # ~10 s de margen
		if not main.is_sleeping():
			return
		await tree.process_frame
	check(false, "dormir no terminó a tiempo")


func wait_frames(n: int) -> void:
	for i in n:
		await tree.physics_frame
