extends Node
## Feedback de combate ("juice"): freno de golpe, sacudida de cámara, números de daño y partículas.
## Autoload: cualquier script llama Fx.hitstop(), Fx.shake(), Fx.number() o Fx.burst().
## En Unity sería un singleton tipo FeedbackManager con métodos estáticos.
##
## Todo usa tiempo REAL (no el escalado): el freno de golpe baja Engine.time_scale y el resto
## tiene que seguir funcionando igual mientras dura.

const NumberScript := preload("res://scenes/fx/damage_number.gd")

## Sacudida máxima en px (con trauma = 1). El trauma baja solo y la amplitud es trauma².
const MAX_SHAKE := 4.0
const TRAUMA_DECAY := 2.5
## Escala de tiempo durante el freno de golpe (casi congelado, no del todo).
const HITSTOP_SCALE := 0.05

var enabled := true

var _trauma := 0.0
var _stop_until := 0
var _last_ms := 0
var _cam: Camera2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_last_ms = Time.get_ticks_msec()


## Freno de 2-3 frames al pegar: el golpe "pesa". Varios seguidos no se suman, se estiran.
func hitstop(seconds := 0.045) -> void:
	if not enabled or get_tree().paused:
		return
	Engine.time_scale = HITSTOP_SCALE
	_stop_until = maxi(_stop_until, Time.get_ticks_msec() + int(seconds * 1000.0))


func is_stopped() -> bool:
	return Engine.time_scale < 1.0


## Sacudida de cámara. amount 0..1 (se suma al trauma que haya, con tope 1).
func shake(amount: float) -> void:
	if enabled:
		_trauma = minf(_trauma + amount, 1.0)


func trauma() -> float:
	return _trauma


## Número flotante sobre `target` (sube y se desvanece). Vive en el mismo padre que el target
## para que se borre solo al cambiar de zona.
func number(target: Node2D, value: Variant, color := Color("FFF1D6")) -> Node2D:
	var parent := target.get_parent() if is_instance_valid(target) else null
	if parent == null:
		return null
	var n: Node2D = NumberScript.new()
	n.setup(str(value), color)
	n.position = target.position + Vector2(randf_range(-3.0, 3.0), -16.0)
	parent.add_child(n)
	return n


## Explosión de partículas cuadradas de 1-2 px (impacto, astillas, polvo).
## colors: se elige uno al azar por partícula. up: sesgo hacia arriba (0 = todas direcciones).
func burst(target: Node2D, colors: PackedColorArray, count := 8, speed := 60.0,
		offset := Vector2.ZERO, up := 0.0) -> CPUParticles2D:
	var parent := target.get_parent() if is_instance_valid(target) else null
	if parent == null or colors.is_empty():
		return null
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = maxi(count, 1)
	p.lifetime = 0.45
	p.direction = Vector2.UP
	p.spread = lerpf(180.0, 60.0, clampf(up, 0.0, 1.0))
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 180)
	p.damping_min = 20.0
	p.damping_max = 60.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	# Color al azar entre los dados (rampa en escalones) y desvanecido al final
	var pick := Gradient.new()
	pick.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offs := PackedFloat32Array()
	for i in colors.size():
		offs.append(float(i) / colors.size())
	pick.offsets = offs
	pick.colors = colors
	p.color_initial_ramp = pick
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.set_offset(0, 0.6)
	p.color_ramp = fade
	p.position = target.position + offset
	p.z_index = 40
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	var real_delta := (now - _last_ms) / 1000.0
	_last_ms = now

	if Engine.time_scale < 1.0 and now >= _stop_until:
		Engine.time_scale = 1.0

	var cam := get_viewport().get_camera_2d()
	if cam != _cam:
		if is_instance_valid(_cam):
			_cam.offset = Vector2.ZERO
		_cam = cam
	if _trauma > 0.0:
		_trauma = maxf(_trauma - real_delta * TRAUMA_DECAY, 0.0)
		if cam:
			var a := _trauma * _trauma * MAX_SHAKE
			cam.offset = Vector2(randf_range(-a, a), randf_range(-a, a)).round()
	elif cam and cam.offset != Vector2.ZERO:
		cam.offset = Vector2.ZERO


## Para tests y cambios de escena: deja todo en reposo.
func reset() -> void:
	Engine.time_scale = 1.0
	_stop_until = 0
	_trauma = 0.0
