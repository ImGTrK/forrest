class_name EnemySpitter
extends Enemy
## Lanzador (hongo bufón): se queda a distancia, apunta con un amago visible (una mira de
## puntos) y escupe una espora que vuela recto. Si te acercás, huye; si te alejás, te sigue.
## Frágil: 2 golpes. Se le gana cerrando distancia o esquivando la espora con el dash.

const SPEED := 40.0
const PERCEPTION := 112.0
const LOSE_INTEREST := 150.0
## Distancia cómoda: más lejos se acerca, más cerca huye.
const PREFERRED := 64.0
const TOO_CLOSE := 36.0
const FIRE_RANGE := 100.0
const WINDUP_TIME := 0.6
const COOLDOWN := 1.7
const DAMAGE := 1
const BASE_HEALTH := 2
const SPORE_SPEED := 96.0
const TEXTURE := preload("res://assets/sprites/enemies/enemy_spitter.png")

## Dirección fijada al empezar el amago: la espora sale hacia ahí (se esquiva moviéndose).
var aim := Vector2.RIGHT
var _strafe := 1.0


func _init() -> void:
	speed = SPEED
	perception = PERCEPTION
	lose_interest = LOSE_INTEREST
	attack_range = FIRE_RANGE
	windup_time = WINDUP_TIME
	attack_cooldown = COOLDOWN
	damage = DAMAGE
	base_health = BASE_HEALTH
	texture = TEXTURE
	hframes = 4
	vframes = 4
	_strafe = 1.0 if randf() < 0.5 else -1.0
	hit_colors = PackedColorArray([Color("FFF1D6"), Color("D4E2A1"), Color("D34B55")])


func _chase_velocity(to_player: Vector2, dist: float) -> Vector2:
	var dir := to_player.normalized()
	if dist < TOO_CLOSE:
		return -dir * speed * 1.25  # huye
	if dist > PREFERRED + 14.0:
		return dir * speed
	# A buena distancia: rodea al jugador de costado
	return dir.orthogonal() * speed * 0.45 * _strafe


func _wants_attack(_to_player: Vector2, dist: float) -> bool:
	return dist <= FIRE_RANGE and dist >= TOO_CLOSE * 0.8


func _on_windup_start(to_player: Vector2) -> void:
	aim = to_player.normalized()
	_strafe = -_strafe  # la próxima vez rodea para el otro lado


func _attack(_to_player: Vector2, _dist: float) -> void:
	var parent := get_parent()
	if parent == null:
		return
	Projectile.spawn(parent, position + aim * 6.0, aim * SPORE_SPEED, damage)
	AudioManager.play(&"spit")


## Tras disparar: si el jugador está cerca se aleja, si no se queda quieto.
func _recover_velocity(to_player: Vector2) -> Vector2:
	if to_player.length() < PREFERRED:
		return -to_player.normalized() * speed
	return Vector2.ZERO


## Mira: puntos que se llenan hacia donde va a escupir.
func _draw_telegraph() -> void:
	var k := 1.0 - maxf(_t, 0.0) / windup_time
	var dots := 6
	for i in dots:
		if float(i) / dots > k:
			break
		var p := (aim * (10.0 + i * 6.0)).round()
		draw_rect(Rect2(p, Vector2(1, 1)), Color(0.83, 0.29, 0.33, 0.5 + 0.5 * k))
