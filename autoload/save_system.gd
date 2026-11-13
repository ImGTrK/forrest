extends Node
## Guardado en disco (GDD §8: JSON, como el diseño de BarrenRoots).
## Archivo: user://save.json  (en Windows: %APPDATA%/Godot/app_userdata/Forrest/save.json)
##
## Qué se guarda: todo lo persistente — mochila y almacén (cada ítem con posición,
## rotación, ADN y durabilidad), mejoras, runs, misiones, hora, energía y vida.
## Qué NO: el bosque. Siempre se carga en el pueblo; si cerrás en el bosque, volvés
## al último guardado (el run en curso se pierde).
## Cuándo: al llegar al pueblo, después de dormir y al cerrar la ventana en el pueblo (Main).

const VERSION := 1

var save_path := "user://save.json"
## Vida del jugador leída del guardado; Main la aplica al crear al jugador (-1 = llena).
var pending_health := -1


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


## Partida nueva: todo a cero (no borra el archivo hasta el primer guardado).
func new_game() -> void:
	GameState.reset()
	Clock.reset()
	Energy.reset()
	ForestSession.reset()
	Missions.reset()
	pending_health = -1


func save_game(player_health: int = -1) -> bool:
	var data := {
		"version": VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"game": {
			"bag": GameState.bag.to_dict(),
			"storage": GameState.storage.to_dict(),
			"runs_completed": GameState.runs_completed,
			"bonus_weight": GameState.bonus_weight,
			"bonus_energy": GameState.bonus_energy,
			"bonus_health": GameState.bonus_health,
		},
		"clock": {"total_minutes": Clock.total_minutes},
		"energy": {"value": Energy.value},
		"player": {"health": player_health},
		"missions": {
			"completed": Missions.completed,
			"active": Missions.active.map(func(m: Mission) -> Dictionary: return m.to_dict()),
		},
	}
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		push_error("No se pudo guardar en %s: %s" % [save_path, error_string(FileAccess.get_open_error())])
		return false
	f.store_string(JSON.stringify(data, "\t", true, true))  # full_precision: el ADN vuelve exacto
	return true


## Carga el guardado. Devuelve false si no hay archivo o está roto (no toca el estado).
func load_game() -> bool:
	if not has_save():
		return false
	var text := FileAccess.get_file_as_string(save_path)
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Guardado ilegible: %s" % save_path)
		return false
	new_game()
	var game: Dictionary = data.get("game", {})
	# Mejoras primero: definen los máximos de energía/peso
	GameState.bonus_weight = float(game.get("bonus_weight", 0.0))
	GameState.bonus_energy = float(game.get("bonus_energy", 0.0))
	GameState.bonus_health = int(game.get("bonus_health", 0))
	GameState.runs_completed = int(game.get("runs_completed", 0))
	GameState.bag.load_dict(game.get("bag", {}), GameState.BAG_SIZE)
	GameState.storage.load_dict(game.get("storage", {}), GameState.STORAGE_SIZE)
	GameState.upgrades_changed.emit()
	Clock.total_minutes = float(data.get("clock", {}).get("total_minutes", Clock.total_minutes))
	Energy.set_value(float(data.get("energy", {}).get("value", Energy.max_value())))
	pending_health = int(data.get("player", {}).get("health", -1))
	var ms: Dictionary = data.get("missions", {})
	Missions.load_state(int(ms.get("completed", 0)), ms.get("active", []))
	return true
