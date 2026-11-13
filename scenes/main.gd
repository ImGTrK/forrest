extends Node2D
## Orquestador: decide qué "área" está cargada (Hub o una ForestZone) y maneja
## las transiciones. El jugador es persistente (no se destruye al cambiar de área);
## lo único que se reemplaza es el hijo de $World.

@onready var world: Node2D = $World
@onready var player: Player = $Player
@onready var hud: GameHUD = $HUD
@onready var storage_ui: StorageUI = $StorageUI

var _area: Node2D = null
var _busy := false


func _ready() -> void:
	_load_hub("start")


func _swap_area(new_area: Node2D) -> void:
	if _area:
		world.remove_child(_area)
		_area.queue_free()
	_area = new_area
	_area.connect("leave", _on_area_leave)
	world.add_child(_area)  # dispara _ready() del área, que construye el mapa


func _load_hub(spawn: String) -> void:
	var hub := Hub.new()
	hub.player = player
	hub.chest_opened.connect(storage_ui.open_storage)
	_swap_area(hub)
	player.set_camera_limits(hub.get_bounds())
	player.teleport(hub.get_spawn(spawn))
	hud.set_hub()


func _load_zone(coord: Vector2i, entry_dir: Vector2i) -> void:
	var data := ForestSession.enter(coord, entry_dir)
	var zone := ForestZone.new()
	zone.setup(data, player)
	_swap_area(zone)
	player.set_camera_limits(zone.get_bounds())
	player.teleport(zone.get_entry_position(entry_dir))


## Llamado por el área cuando el jugador cruza un borde. Se difiere al final del frame
## porque no conviene destruir nodos en medio del paso de física.
func _on_area_leave(dir: Vector2i) -> void:
	if _busy:
		return
	_busy = true
	_handle_leave.call_deferred(dir)


func _handle_leave(dir: Vector2i) -> void:
	if _area is Hub:
		ForestSession.start_run()
		_load_zone(Vector2i.ZERO, Vector2i.LEFT)
	else:
		var target := ForestSession.current + dir
		if target == ForestSession.HUB_COORD:
			_return_to_hub()
		else:
			_load_zone(target, -dir)
	_busy = false


## Volver voluntariamente: sin penalización (GDD §4). Se deposita todo y el bosque se borra.
func _return_to_hub() -> void:
	var deposited := GameState.deposit_run()
	ForestSession.reset()
	_load_hub("forest")
	GameState.notify("Volviste al pueblo · %d recursos al almacén" % deposited)
