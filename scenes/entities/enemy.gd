class_name Enemy
extends CharacterBody2D
## Enemigo básico. Port de EnemyAI.cs de BarrenRoots: misma máquina de estados
## (Idle -> Chase -> Attack -> Knockback) y mismos valores convertidos a píxeles.
## Cambio respecto al original: el ataque tiene un "amago" (WINDUP) antes de pegar,
## para que se pueda leer y esquivar con el dash.

enum State { IDLE, CHASE, WINDUP, RECOVER, KNOCKBACK, DEAD }

## 32x16: 2 frames de 16x16 (de EnemyTemp.ase). Frame 1 es el normal, frame 0 el "parpadeo".
const TEXTURE := preload("res://assets/sprites/enemies/enemy_basic.png")
const RADIUS := 6.0

# --- Valores (BarrenRoots ×16 px) ---------------------------------------------
const SPEED := 48.0  # 3 u/s
const PERCEPTION := 80.0  # 5 u
const LOSE_INTEREST := 120.0
const ATTACK_RANGE := 12.0  # ~0.6-0.75 u
const WINDUP_TIME := 0.35
const ATTACK_COOLDOWN := 1.0
const DAMAGE := 1  # medio corazón
const KNOCKBACK_TIME := 0.25
const BASE_HEALTH := 3
const WANDER_SPEED := 14.0
# -------------------------------------------------------------------------------

var entity: Dictionary  # referencia en ZoneData (alive = false al morir: no reaparece)
var player: Player
var health: Health

var state: State = State.IDLE
var _t := 0.0
var _knock := Vector2.ZERO
var _wander := Vector2.ZERO
var _flash_t := 0.0
var _anim_t := 0.0
var _sprite: Sprite2D
var _max_health := BASE_HEALTH


func setup(p_entity: Dictionary, p_player: Player, loot_depth: int) -> void:
	entity = p_entity
	player = p_player
	# Más profundo (o más tarde) = más aguante
	_max_health = BASE_HEALTH + floori(loot_depth / 3.0)


func _ready() -> void:
	collision_layer = 4  # capa 3: enemigos
	collision_mask = 1 | 4  # mundo + otros enemigos (al jugador lo atraviesa)
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CircleShape2D.new()
	shape.radius = RADIUS - 1.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)

	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.hframes = 2
	_sprite.frame = 1
	_sprite.position = Vector2(0, -3)
	add_child(_sprite)

	health = Health.new()
	health.max_health = _max_health
	add_child(health)
	health.damaged.connect(func(_a: int, _f: Vector2) -> void: _flash_t = 0.15)
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
			if _t <= 0.0:
				_t = randf_range(1.0, 2.5)
				_wander = Vector2.from_angle(randf() * TAU) * WANDER_SPEED if randf() < 0.6 else Vector2.ZERO
			velocity = _wander
			if dist <= PERCEPTION:
				state = State.CHASE
		State.CHASE:
			velocity = to_player.normalized() * SPEED
			if dist <= ATTACK_RANGE:
				state = State.WINDUP
				_t = WINDUP_TIME
			elif dist > LOSE_INTEREST:
				state = State.IDLE
		State.WINDUP:
			velocity = Vector2.ZERO
			if _t <= 0.0:
				if dist <= ATTACK_RANGE + 6.0:
					player.take_hit(DAMAGE, global_position)
				state = State.RECOVER
				_t = ATTACK_COOLDOWN
		State.RECOVER:
			velocity = -to_player.normalized() * SPEED * 0.3  # se aleja un poco
			if _t <= 0.0:
				state = State.CHASE
		State.KNOCKBACK:
			velocity = _knock
			_knock = _knock.move_toward(Vector2.ZERO, 600.0 * delta)
			if _t <= 0.0:
				state = State.CHASE
	move_and_slide()
	_update_visual(delta)


## Golpe del jugador.
func take_hit(amount: int, knockback: Vector2) -> void:
	if state == State.DEAD:
		return
	if health.take_damage(amount) and state != State.DEAD:
		state = State.KNOCKBACK
		_t = KNOCKBACK_TIME
		_knock = knockback


func _die() -> void:
	state = State.DEAD
	entity.alive = false
	remove_from_group("enemy")
	collision_layer = 0
	collision_mask = 0
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color(1, 0.3, 0.3, 0.0), 0.3)
	tween.tween_callback(queue_free)


func _update_visual(delta: float) -> void:
	_anim_t += delta
	# Ciclo de 2.1 s: 0.1 s parpadeo (frame 0) + 2 s normal (frame 1), como el .ase
	_sprite.frame = 0 if fmod(_anim_t, 2.1) < 0.1 else 1
	if absf(velocity.x) > 1.0:
		_sprite.flip_h = velocity.x < 0.0
	_flash_t = maxf(_flash_t - delta, 0.0)
	if _flash_t > 0.0:
		_sprite.modulate = Color(1, 0.3, 0.3)
	elif state == State.WINDUP:
		# Amago: se infla y se pone blanco antes de pegar
		var k := 1.0 - maxf(_t, 0.0) / WINDUP_TIME
		_sprite.modulate = Color.WHITE.lerp(Color(1.8, 1.8, 1.8), k)
		_sprite.scale = Vector2.ONE * (1.0 + 0.25 * k)
	else:
		_sprite.modulate = Color.WHITE
		_sprite.scale = Vector2.ONE
