class_name Enemy
extends CharacterBody2D
## Clase base de todos los enemigos (≈ clase abstracta de C#). Port de EnemyAI.cs de BarrenRoots.
##
## La base tiene lo que comparten todos:
##   - máquina de estados: IDLE → CHASE → WINDUP (amago) → ATTACK → RECOVER, más KNOCKBACK,
##     STUNNED y DEAD
##   - vida (componente Health), destello al recibir daño (componente HitFlash), knockback
##   - muerte: marca la entidad en la cache de la zona, avisa a Missions y llama a _drop()
##   - el "amago" visual: se infla y se pone blanco antes de pegar (legible y esquivable)
##
## Cada tipo de enemigo es un hijo que:
##   1. en _init() setea sus stats (speed, damage, base_health…) y su textura
##   2. sobrescribe solo lo que cambia: cómo se mueve (_chase_velocity), cuándo ataca
##      (_wants_attack), cómo ataca (_attack / _attack_velocity), su animación (_animate)
##      y qué suelta (_drop)
## Ver EnemyBasic como ejemplo mínimo.

enum State { IDLE, CHASE, WINDUP, ATTACK, RECOVER, KNOCKBACK, STUNNED, DEAD }

## Capas de colisión (bits): 1 mundo · 2 jugador · 3 enemigos
const LAYER_ENEMY := 4
const MASK_ENEMY := 1 | 4  # mundo + otros enemigos (al jugador lo atraviesa)
const KNOCKBACK_TIME := 0.25
const KNOCKBACK_FRICTION := 600.0
const HURT_FLASH := Color(1, 0.3, 0.3)

# --- Stats (los setea cada hijo en _init) --------------------------------------
var speed := 48.0
var perception := 80.0
var lose_interest := 120.0
var attack_range := 12.0
var windup_time := 0.35
var attack_cooldown := 1.0
var damage := 1
var base_health := 3
## Cada cuántos niveles de profundidad efectiva gana +1 de vida.
var depth_per_health := 3
var wander_speed := 14.0
var radius := 6.0
# --- Visual ----------------------------------------------------------------------
var texture: Texture2D
var hframes := 1
var vframes := 1
var sprite_offset := Vector2(0, -3)

var entity: Dictionary  # referencia en ZoneData (alive = false al morir: no reaparece)
var player: Player
var health: Health
var state: State = State.IDLE

var _t := 0.0
var _knock := Vector2.ZERO
var _wander := Vector2.ZERO
var _anim_t := 0.0
var _max_health := 3
var _sprite: Sprite2D
var _flash: HitFlash


func setup(p_entity: Dictionary, p_player: Player, loot_depth: int) -> void:
	entity = p_entity
	player = p_player
	# Más profundo (o más tarde) = más aguante
	_max_health = base_health + floori(loot_depth / float(depth_per_health))


func _ready() -> void:
	collision_layer = LAYER_ENEMY
	collision_mask = MASK_ENEMY
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CircleShape2D.new()
	shape.radius = radius - 1.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)

	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.hframes = hframes
	_sprite.vframes = vframes
	_sprite.position = sprite_offset
	add_child(_sprite)
	_flash = HitFlash.new(_sprite)
	add_child(_flash)

	health = Health.new()
	health.max_health = maxi(_max_health, base_health)
	add_child(health)
	health.damaged.connect(func(_a: int, _f: Vector2) -> void: _flash.flash(HURT_FLASH, 0.15))
	health.died.connect(_die)
	add_to_group("enemy")
	_anim_t = randf() * 2.0


func _physics_process(delta: float) -> void:
	if state == State.DEAD or player == null:
		return
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	_t -= delta

	match state:
		State.IDLE:
			velocity = _idle_velocity()
			if dist <= perception:
				state = State.CHASE
		State.CHASE:
			velocity = _chase_velocity(to_player, dist)
			if _wants_attack(to_player, dist):
				state = State.WINDUP
				_t = windup_time
				_on_windup_start(to_player)
			elif dist > lose_interest:
				state = State.IDLE
		State.WINDUP:
			velocity = Vector2.ZERO
			if _t <= 0.0:
				state = State.RECOVER
				_t = attack_cooldown
				_attack(to_player, dist)  # puede cambiar el estado (ej. a ATTACK para una embestida)
		State.ATTACK:
			velocity = _attack_velocity(delta)
		State.RECOVER:
			velocity = _recover_velocity(to_player)
			if _t <= 0.0:
				state = State.CHASE
		State.KNOCKBACK:
			velocity = _knock
			_knock = _knock.move_toward(Vector2.ZERO, KNOCKBACK_FRICTION * delta)
			if _t <= 0.0:
				state = State.CHASE
		State.STUNNED:
			velocity = Vector2.ZERO
			if _t <= 0.0:
				state = State.CHASE
	move_and_slide()
	_on_moved()
	_update_visual(delta)


# --- API pública ---------------------------------------------------------------

## Golpe del jugador.
func take_hit(amount: int, knockback: Vector2) -> void:
	if state == State.DEAD:
		return
	if health.take_damage(amount) and state != State.DEAD:
		state = State.KNOCKBACK
		_t = KNOCKBACK_TIME
		_knock = knockback * _knockback_scale()


func is_dead() -> bool:
	return state == State.DEAD


## Para hijos con ataques que duran (embestidas): vuelve a RECOVER.
func end_attack(cooldown := -1.0) -> void:
	state = State.RECOVER
	_t = attack_cooldown if cooldown < 0.0 else cooldown


## Para hijos: queda aturdido `time` segundos.
func stun(time: float) -> void:
	state = State.STUNNED
	_t = time


# --- Métodos virtuales (sobrescribir en los hijos) --------------------------------

## Vagar sin rumbo mientras no ve al jugador.
func _idle_velocity() -> Vector2:
	if _t <= 0.0:
		_t = randf_range(1.0, 2.5)
		_wander = Vector2.from_angle(randf() * TAU) * wander_speed if randf() < 0.6 else Vector2.ZERO
	return _wander


## Movimiento al perseguir. Por defecto: derecho al jugador.
func _chase_velocity(to_player: Vector2, _dist: float) -> Vector2:
	return to_player.normalized() * speed


## ¿Empieza el amago? Por defecto: cuando está a distancia de ataque.
func _wants_attack(_to_player: Vector2, dist: float) -> bool:
	return dist <= attack_range


## Al empezar el amago (ej. fijar hacia dónde va a embestir o disparar).
func _on_windup_start(_to_player: Vector2) -> void:
	pass


## El golpe en sí, al terminar el amago. Por defecto: mordida cuerpo a cuerpo.
func _attack(_to_player: Vector2, dist: float) -> void:
	if dist <= attack_range + 6.0:
		player.take_hit(damage, global_position)


## Movimiento durante State.ATTACK (solo para ataques que duran). Terminar con end_attack().
func _attack_velocity(_delta: float) -> Vector2:
	end_attack()
	return Vector2.ZERO


## Después de atacar. Por defecto: se aleja un poco.
func _recover_velocity(to_player: Vector2) -> Vector2:
	return -to_player.normalized() * speed * 0.3


## Después de move_and_slide (ej. detectar choques contra paredes).
func _on_moved() -> void:
	pass


## 1 = knockback normal, 0 = inamovible (enemigos pesados).
func _knockback_scale() -> float:
	return 1.0


## Frame del sprite según el estado. Por defecto: frame 0.
func _animate(_delta: float) -> void:
	pass


## Qué suelta al morir. Por defecto: nada.
func _drop() -> void:
	pass


# --- Interno -----------------------------------------------------------------------

func _die() -> void:
	state = State.DEAD
	entity.alive = false
	Missions.on_enemy_killed()
	_drop()
	remove_from_group("enemy")
	collision_layer = 0
	collision_mask = 0
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color(1, 0.3, 0.3, 0.0), 0.3)
	tween.tween_callback(queue_free)


func _update_visual(delta: float) -> void:
	_anim_t += delta
	_animate(delta)
	if absf(velocity.x) > 1.0:
		_sprite.flip_h = velocity.x < 0.0
	if _flash.is_active():
		return  # el destello de daño manda
	if state == State.WINDUP:
		# Amago: se infla y se pone blanco antes de pegar
		var k := 1.0 - maxf(_t, 0.0) / windup_time
		_sprite.modulate = Color.WHITE.lerp(Color(1.8, 1.8, 1.8), k)
		_sprite.scale = Vector2.ONE * (1.0 + 0.25 * k)
	else:
		_sprite.modulate = Color.WHITE
		_sprite.scale = Vector2.ONE
