class_name EnemyCharger
extends Enemy
## Embestidor (jabalí-escarabajo): lento y pesado. Raspa el piso (amago largo, tiembla y
## levanta polvo) y embiste en línea recta. Si choca contra un árbol, una roca o una pared
## queda aturdido: es la ventana para pegarle. En plena embestida los golpes no lo frenan.

const SPEED := 30.0
const PERCEPTION := 96.0
const LOSE_INTEREST := 140.0
const CHARGE_RANGE := 84.0
const WINDUP_TIME := 0.75
const CHARGE_SPEED := 210.0
const CHARGE_TIME := 0.7
const STUN_TIME := 1.6
const COOLDOWN := 1.1
const DAMAGE := 2  # un corazón entero
const BASE_HEALTH := 5
const TEXTURE := preload("res://assets/sprites/enemies/enemy_charger.png")

var charge_dir := Vector2.RIGHT
var _charge_t := 0.0
var _hit_player := false
var _dust_t := 0.0


func _init() -> void:
	speed = SPEED
	perception = PERCEPTION
	lose_interest = LOSE_INTEREST
	attack_range = CHARGE_RANGE
	windup_time = WINDUP_TIME
	attack_cooldown = COOLDOWN
	damage = DAMAGE
	base_health = BASE_HEALTH
	radius = 7.0
	top = 12.0
	texture = TEXTURE
	hframes = 4
	vframes = 4
	hit_colors = PackedColorArray([Color("FFF1D6"), Color("744B46"), Color("D34B55")])


func is_charging() -> bool:
	return state == State.ATTACK


func _on_windup_start(to_player: Vector2) -> void:
	charge_dir = to_player.normalized()
	AudioManager.play(&"scrape", -4.0)


func _attack(_to_player: Vector2, _dist: float) -> void:
	state = State.ATTACK
	_charge_t = CHARGE_TIME
	_hit_player = false


func _attack_velocity(delta: float) -> Vector2:
	_charge_t -= delta
	if _charge_t <= 0.0:
		end_attack()
		return Vector2.ZERO
	if not _hit_player and player and global_position.distance_to(player.global_position) <= radius + 6.0:
		_hit_player = player.take_hit(damage, global_position)
	return charge_dir * CHARGE_SPEED


## Choque durante la embestida: contra el mundo queda aturdido, contra otro enemigo frena.
func _on_moved() -> void:
	if state != State.ATTACK:
		return
	for i in get_slide_collision_count():
		var other := get_slide_collision(i).get_collider()
		if other is Enemy:
			end_attack()
			return
		crash()
		return


func crash() -> void:
	stun(STUN_TIME)
	Fx.shake(0.45)
	Fx.burst(self, PackedColorArray([Color("D8AD82"), Color("B88064"), Color("F6E3BE")]), 10, 70.0)
	AudioManager.play(&"bonk")


func _knockback_scale() -> float:
	return 0.35  # pesado


func _interruptible() -> bool:
	return state != State.ATTACK


func _animate(delta: float) -> void:
	super._animate(delta)
	# Raspar: tiembla y levanta polvo detrás
	if state == State.WINDUP:
		_sprite.position.x = sprite_offset.x + (1.0 if int(_anim_t * 30.0) % 2 == 0 else -1.0)
		_dust_t -= delta
		if _dust_t <= 0.0:
			_dust_t = 0.12
			Fx.burst(self, PackedColorArray([Color("D8AD82"), Color("F6E3BE")]), 3, 30.0,
				-charge_dir * 6.0 + Vector2(0, 3), 0.8)
	else:
		_sprite.position.x = sprite_offset.x


## Flecha de puntos cortos hacia donde va a embestir.
func _draw_telegraph() -> void:
	var k := 1.0 - maxf(_t, 0.0) / windup_time
	for i in 4:
		var p := (charge_dir * (12.0 + i * 5.0)).round()
		draw_rect(Rect2(p - Vector2(1, 0), Vector2(2, 1)), Color(0.83, 0.29, 0.33, k * (1.0 - i * 0.18)))
