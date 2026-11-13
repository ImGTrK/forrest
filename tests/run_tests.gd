extends Node
## Runner de los tests con el juego real (autoloads + Main.tscn).
## Correr todo:
##   godot --headless --path . res://tests/RunTests.tscn
## Correr una sola suite (o varias, separadas por coma):
##   godot --headless --path . res://tests/RunTests.tscn -- --suite=combat
## (es una escena y no un --script para que los autoloads existan como en el juego real)
##
## Cada suite arranca con una partida nueva y un Main recién creado en el pueblo.
## Los tests del generador van aparte: tests/test_generation.gd (--script).

const SUITES := [
	"res://tests/suites/test_loop.gd",
	"res://tests/suites/test_time_energy.gd",
	"res://tests/suites/test_combat.gd",
	"res://tests/suites/test_inventory.gd",
	"res://tests/suites/test_crafting.gd",
	"res://tests/suites/test_night_missions.gd",
	"res://tests/suites/test_save.gd",
	"res://tests/suites/test_entities.gd",
]


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var tree := get_tree()
	# Archivo de guardado propio: Main autoguarda y no hay que pisar la partida real
	SaveSystem.save_path = "user://test_save.json"
	var only := _requested_suites()
	var total_fail := 0
	var total_checks := 0
	var summary: Array[String] = []
	for path: String in SUITES:
		var suite_name := path.get_file().get_basename().trim_prefix("test_")
		if not only.is_empty() and not only.has(suite_name):
			continue
		print("\n== %s ==" % suite_name)
		tree.paused = false
		SaveSystem.new_game()
		SaveSystem.delete_save()
		var main: Node = load("res://scenes/Main.tscn").instantiate()
		tree.root.add_child(main)
		await tree.process_frame
		var suite: TestSuite = load(path).new()
		suite.main = main
		suite.tree = tree
		add_child(suite)
		await suite.run()
		total_fail += suite.failures
		total_checks += suite.checks
		summary.append("%s: %d/%d" % [suite_name, suite.checks - suite.failures, suite.checks])
		tree.paused = false
		suite.queue_free()
		main.queue_free()
		await tree.process_frame
		await tree.process_frame
	SaveSystem.delete_save()
	print("\n" + "\n".join(summary))
	print("RESULTADO: ", "OK (%d checks)" % total_checks if total_fail == 0 else "%d FALLAS de %d" % [total_fail, total_checks])
	tree.quit(1 if total_fail > 0 else 0)


func _requested_suites() -> PackedStringArray:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--suite="):
			return arg.trim_prefix("--suite=").split(",")
	return PackedStringArray()
