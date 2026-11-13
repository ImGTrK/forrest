extends Node2D
## Orquestador: decide qué "área" está cargada (Hub o una ForestZone) y maneja
## las transiciones, el dormir, el colapso y la muerte. El jugador es persistente (no se destruye
## al cambiar de área); lo único que se reemplaza es el hijo de $World.

const FADE_TIME := 0.5
const SLEEP_HOLD_TIME := 0.8

@onready var world: Node2D = $World
@onready var player: Player = $Player
@onready var hud: GameHUD = $HUD
@onready var inventory_ui: InventoryUI = $InventoryUI
@onready var crafting_ui: CraftingUI = $CraftingUI
## Tiñe todo el canvas del mundo según la hora (el HUD está en otra capa y no se tiñe).
@onready var ambient: CanvasModulate = $Ambient
## Pantalla negra para dormir/colapsar. process_mode = ALWAYS: anima con el juego pausado.
@onready var fade: ColorRect = $Fade/Black

var _area: Node2D = null
var _busy := false
var _sleeping := false


func _ready() -> void:
	# Diferido: el colapso se dispara en medio del _process del reloj y no conviene
	# destruir/crear áreas en ese momento.
	Energy.collapsed.connect(_on_collapsed, CONNECT_DEFERRED)
	player.died.connect(_on_player_died, CONNECT_DEFERRED)
	hud.bind_player(player)
	_load_hub("start")


func _process(_delta: float) -> void:
	ambient.color = Clock.ambient_color()


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
	hub.chest_opened.connect(inventory_ui.open_chest)
	hub.bed_used.connect(sleep)
	hub.bench_used.connect(crafting_ui.open)
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
	if _busy or _sleeping:
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


## Volver voluntariamente: sin penalización (GDD §4). El bosque se borra; lo cargado
## sigue en la mochila hasta que el jugador lo guarde en el cofre.
func _return_to_hub() -> void:
	GameState.end_run()
	ForestSession.reset()
	_load_hub("forest")
	var n := GameState.bag.count()
	GameState.notify("Volviste al pueblo" + (" · guardá lo que traés en el almacén" if n > 0 else ""))


## Energía en 0 (GDD §4): "muerte suave". En el bosque se pierde un % menor de lo cargado
## que al morir, se vuelve al hub y se duerme a la fuerza. En el hub, solo se duerme.
func _on_collapsed() -> void:
	if _sleeping:
		return
	var summary := "Te desmayaste de cansancio."
	if ForestSession.in_forest:
		var lost := GameState.lose_run_fraction(GameState.COLLAPSE_LOSS, GameState.rng)
		GameState.end_run()
		ForestSession.reset()
		_load_hub("bed")
		summary = "Te desmayaste en el bosque · perdiste %d ítems." % lost
	else:
		player.teleport(_hub().get_spawn("bed"))
	sleep(summary)


## Morir en combate (GDD §4): pierde un % MAYOR de lo cargado que el colapso
## (el equipo nunca se pierde), vuelve al hub con la vida llena. No duerme:
## la energía y la hora siguen como estaban.
func _on_player_died() -> void:
	if _sleeping:
		return
	var summary := {}
	await _black_screen(func() -> void:
		var lost := GameState.lose_run_fraction(GameState.DEATH_LOSS, GameState.rng)
		GameState.end_run()
		ForestSession.reset()
		_load_hub("bed")
		player.revive()
		summary.text = "Caíste en combate · perdiste %d ítems." % lost)
	GameState.notify(summary.text)


## Dormir (solo en el hub): fundido a negro, pasan 5-9 h al azar, recarga proporcional.
## Dormir también cura toda la vida.
func sleep(prefix: String = "") -> void:
	if _sleeping:
		return
	var before := Energy.value
	var result := {}
	await _black_screen(func() -> void:
		result.hours = Clock.sleep()
		player.revive()
		hud.refresh_clock())
	var text := "Dormiste %d h · energía +%d" % [result.hours, roundi(Energy.value - before)]
	GameState.notify((prefix + "  " + text) if prefix != "" else text)


## Pausa, funde a negro, ejecuta `action` con la pantalla negra y vuelve.
func _black_screen(action: Callable) -> void:
	_sleeping = true
	get_tree().paused = true
	await _fade_to(1.0)
	action.call()
	await get_tree().create_timer(SLEEP_HOLD_TIME, true).timeout
	await _fade_to(0.0)
	get_tree().paused = false
	_sleeping = false


func is_sleeping() -> bool:
	return _sleeping


func _fade_to(alpha: float) -> void:
	var tween := fade.create_tween()
	tween.tween_property(fade, "color:a", alpha, FADE_TIME)
	await tween.finished


func _hub() -> Hub:
	return _area as Hub
