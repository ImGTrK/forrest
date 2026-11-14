extends Node
## Sistema de audio (autoload `AudioManager`).
##   - Buses: Music, SFX y UI (se crean al arrancar si no existen; todos mandan a Master).
##   - Pool de reproductores: varios sonidos a la vez sin crear nodos por golpe.
##   - Variantes al azar + un poco de tono al azar: golpes seguidos no suenan igual.
##
## Uso:  AudioManager.play(&"hit")      AudioManager.play(&"click", 0.0, &"UI")
##
## Sonidos reales: poné `assets/audio/sfx/<id>.wav` (u .ogg), o variantes `<id>_1.wav`,
## `<id>_2.wav`… y se usan en vez del sintetizado (SfxSynth). Sin archivo ni receta: silencio.
## En Unity sería un AudioManager singleton con un pool de AudioSources y AudioMixer groups.

const BUSES: Array[StringName] = [&"Music", &"SFX", &"UI"]
const POOL_SIZE := 12
const SFX_DIR := "res://assets/audio/sfx/"
const EXTENSIONS := ["wav", "ogg"]
## El mismo sonido no se repite antes de esto (ms): evita que 3 golpes en un frame saturen.
const MIN_REPEAT_MS := 35

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _cache := {}  # id -> Array[AudioStream]
var _last := {}  # id -> ms
## Contador de reproducciones (para tests y depuración).
var played := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in BUSES:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus)
			AudioServer.set_bus_send(idx, &"Master")
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_players.append(p)


## Reproduce un efecto. volume_db: ajuste fino · pitch_var: ± variación de tono al azar.
func play(id: StringName, volume_db := 0.0, bus := &"SFX", pitch_var := 0.08) -> void:
	var streams := streams_for(id)
	if streams.is_empty():
		return
	var now := Time.get_ticks_msec()
	if now - int(_last.get(id, -1000)) < MIN_REPEAT_MS:
		return
	_last[id] = now
	played[id] = int(played.get(id, 0)) + 1
	var p := _free_player()
	p.stream = streams.pick_random()
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.bus = bus
	p.play()


## Volumen de un bus, lineal 0..1 (para el menú de opciones del hito 12).
func set_bus_volume(bus: StringName, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
		AudioServer.set_bus_mute(idx, linear <= 0.0)


func get_bus_volume(bus: StringName) -> float:
	var idx := AudioServer.get_bus_index(bus)
	return db_to_linear(AudioServer.get_bus_volume_db(idx)) if idx >= 0 else 0.0


## Archivos del id (con variantes) o, si no hay, el sintetizado.
func streams_for(id: StringName) -> Array:
	if _cache.has(id):
		return _cache[id]
	var found: Array[AudioStream] = []
	for ext: String in EXTENSIONS:
		var base := "%s%s.%s" % [SFX_DIR, id, ext]
		if ResourceLoader.exists(base):
			found.append(load(base))
		for i in range(1, 9):
			var path := "%s%s_%d.%s" % [SFX_DIR, id, i, ext]
			if ResourceLoader.exists(path):
				found.append(load(path))
	if found.is_empty():
		found = SfxSynth.make(id)
	_cache[id] = found
	return found


## El primero libre; si están todos sonando, pisa el más viejo (ronda).
func _free_player() -> AudioStreamPlayer:
	for i in _players.size():
		var p := _players[(_next + i) % _players.size()]
		if not p.playing:
			_next = (_next + i + 1) % _players.size()
			return p
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	return p
