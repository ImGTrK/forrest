class_name Player
extends CharacterBody2D
## Jugador: movimiento en 8 direcciones animado, interacción, ataque en arco y dash.
## Hito 10: la hoja sale de un rig por partes (tools/art/draw_player.gd) con quieto, caminar,
## ataque, dash y muerte. Encima, una capa procedural suave (_update_pose) le da peso: estirón
## al pegar, aplastado al recibir y estela en el dash.
## El combate es un port de PlayerController.cs de BarrenRoots (mismos valores,
## convertidos a píxeles: 1 unidad de Unity = 16 px).
## CharacterBody2D ≈ Rigidbody2D kinematic: seteás `velocity` y llamás move_and_slide().

signal died

# --- Interacción ---------------------------------------------------------------
const INTERACT_RANGE := 14.0
## Tiempo mínimo entre interacciones. Con energía baja se multiplica (Energy).
const INTERACT_COOLDOWN := 0.25

# --- Animación (hoja 384x216: 16x9 frames de 24x24, escala 1) ---------------------
## Filas de la hoja: 0 S · 1 SW · 2 W · 3 NW · 4 N · 5 NE · 6 E · 7 SE · 8 muerte.
## Columnas: 0-3 quieto, 4-7 caminar, 8-11 ataque, 12-15 dash.
## Fila de muerte: 0-3 cae con la cabeza a la izquierda, 4-7 a la derecha.
## Este array traduce el sector angular (0 = Este, en sentido horario) a la fila.
const DIR_ROWS := [6, 7, 0, 1, 2, 3, 4, 5]
const SHEET_COLUMNS := 16
const IDLE_COL := 0
const WALK_COL := 4
const ATTACK_COL := 8
const DASH_COL := 12
const DEATH_ROW := 8
const ANIM_FPS := 4.0  # quieto
const WALK_FPS := 8.0

# --- Combate ---------------------------------------------------------------------
const MAX_HEALTH := 6  # 3 corazones (cada corazón = 2)
## Daño sin arma. Con arma, el daño es su stat "poder" (redondeado).
const FIST_DAMAGE := 1
const ATTACK_DURATION := 0.2  # BarrenRoots: attackDuration
const ATTACK_COOLDOWN := 0.35
const ATTACK_REACH := 22.0  # px desde el centro del jugador
const ATTACK_ARC := 2.0944  # 120° de arco
const ATTACK_KNOCKBACK := 140.0
const DASH_SPEED := 288.0  # BarrenRoots: 18 u/s
const DASH_DURATION := 0.15
const DASH_COOLDOWN := 1.5
const DASH_ENERGY := 0.6
const HURT_IFRAMES := 0.6
const HURT_KNOCKBACK := 150.0
const HURT_KNOCKBACK_TIME := 0.15
## Muerte: cae de costado, queda tendido y recién ahí avisa (died) para el fundido.
const DEATH_TIME := 0.9
## Estela del dash: una "foto" del sprite cada tanto, que se desvanece.
const AFTERIMAGE_EVERY := 0.03
const AFTERIMAGE_LIFE := 0.22
## Frame de 24x24 centrado: los pies (fila 22) quedan en y ≈ 4, sobre la colisión.
const SPRITE_POS := Vector2(0, -6)
const SPRITE_SCALE := 1.0

## Capas de colisión (bits): 1 mundo · 2 jugador · 3 enemigos
const MASK_NORMAL := 1 | 4
const MASK_DASHING := 1  # durante el dash se atraviesan enemigos

@export var speed: float = 95.0

var facing := Vector2.DOWN
## Interactuable enfocado. Sin tipo a propósito: cualquier nodo del grupo "interactable"
## que implemente get_interact_rect(), set_focused(bool) e interact(by) sirve (duck typing,
## como una interfaz de C# pero sin declararla).
var _focus: Variant = null
var _cooldown := 0.0

var _anim_t := 0.0
var _was_moving := false

var _attack_cd := 0.0
var _attack_t := 0.0
var _attack_dir := Vector2.DOWN

var _dash_t := 0.0
var _dash_cd := 0.0
var _dash_dir := Vector2.DOWN

var _knock_t := 0.0
var _knock_vel := Vector2.ZERO
var _flash_t := 0.0
var _dying_t := -1.0  # < 0 = vivo
var _ghost_t := 0.0

@onready var camera: Camera2D = $Camera2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var health: Health = $Health
var _sword: Sprite2D


func _ready() -> void:
	health.max_health = max_health()
	health.current = max_health()
	GameState.upgrades_changed.connect(_on_upgrades_changed)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_health_died)
	_sword = Sprite2D.new()
	_sword.texture = preload("res://assets/sprites/player/sword.png")  # 16x16, hoja hacia arriba
	_sword.offset = Vector2(0, -8)
	_sword.visible = false
	add_child(_sword)


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_dash_cd = maxf(_dash_cd - delta, 0.0)

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if is_dying():
		_update_death(delta)
		return

	if is_dashing():
		_dash_t -= delta
		velocity = _dash_dir * DASH_SPEED
		if _dash_t <= 0.0:
			_end_dash()
	elif _knock_t > 0.0:
		_knock_t -= delta
		velocity = _knock_vel
	else:
		# Debuffs: energía baja (×0.7) y sobrepeso (×0.5) se acumulan
		velocity = input_dir * speed * Energy.speed_multiplier() * GameState.speed_multiplier()
		if input_dir != Vector2.ZERO and not is_attacking():
			facing = input_dir
	move_and_slide()

	_update_attack(delta)
	_update_animation(delta, input_dir != Vector2.ZERO)
	_update_feedback(delta)
	_update_pose(delta)
	_update_focus()


func _unhandled_input(event: InputEvent) -> void:
	if is_dying():
		return
	if event.is_action_pressed("attack"):
		var aim := get_global_mouse_position() - global_position
		attack(aim if aim.length() > 1.0 else facing)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("dash"):
		dash(Input.get_vector("move_left", "move_right", "move_up", "move_down"))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_light"):
		GameState.toggle_lantern()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and is_instance_valid(_focus) and _cooldown <= 0.0:
		_cooldown = INTERACT_COOLDOWN * Energy.cooldown_multiplier()
		_focus.interact(self)
		get_viewport().set_input_as_handled()


# --- Ataque ------------------------------------------------------------------

func is_attacking() -> bool:
	return _attack_t > 0.0


## Swing en arco hacia `aim`. El daño se aplica al inicio (como en BarrenRoots);
## el resto de la duración es la animación de la espada.
func attack(aim: Vector2) -> void:
	if _attack_cd > 0.0 or is_dashing() or health.is_dead():
		return
	AudioManager.play(&"swing", -3.0)
	_attack_dir = aim.normalized()
	facing = _attack_dir
	_attack_t = ATTACK_DURATION
	_attack_cd = ATTACK_COOLDOWN * Energy.cooldown_multiplier()
	Energy.spend_action()
	var weapon := GameState.best_weapon()
	var damage := maxi(1, roundi(weapon.power())) if weapon else FIST_DAMAGE
	_sword.visible = weapon != null  # a puño limpio solo se ve la estela
	var hit_any := false
	for enemy: Enemy in get_tree().get_nodes_in_group("enemy"):
		var to := enemy.global_position - global_position
		var in_reach := to.length() <= ATTACK_REACH + enemy.radius
		var in_arc := to.length() < 8.0 or absf(_attack_dir.angle_to(to)) <= ATTACK_ARC / 2.0
		if in_reach and in_arc:
			enemy.take_hit(damage, to.normalized() * ATTACK_KNOCKBACK)
			hit_any = true
	if hit_any:
		GameState.wear(weapon)


func _update_attack(delta: float) -> void:
	if _attack_t <= 0.0:
		return
	_attack_t -= delta
	# La espada barre el arco de un lado al otro
	var progress := 1.0 - maxf(_attack_t, 0.0) / ATTACK_DURATION
	var angle := _attack_dir.angle() - ATTACK_ARC / 2.0 + ATTACK_ARC * progress
	_sword.rotation = angle + PI / 2.0
	_sword.position = Vector2.from_angle(angle) * 7.0 + Vector2(0, -5)
	queue_redraw()
	if _attack_t <= 0.0:
		_sword.visible = false
		queue_redraw()


func _draw() -> void:
	if not is_attacking():
		return
	# Estela del swing (placeholder de efecto)
	var progress := 1.0 - _attack_t / ATTACK_DURATION
	var start := _attack_dir.angle() - ATTACK_ARC / 2.0
	draw_arc(Vector2(0, -5), ATTACK_REACH - 4.0, start, start + ATTACK_ARC * progress, 12,
		Color(1, 1, 1, 0.5), 2.0)


# --- Dash ----------------------------------------------------------------------

func is_dashing() -> bool:
	return _dash_t > 0.0


## Dash con i-frames: no recibe daño y atraviesa enemigos mientras dura.
func dash(dir: Vector2) -> void:
	if is_dashing() or _dash_cd > 0.0 or health.is_dead():
		return
	_dash_dir = (dir if dir != Vector2.ZERO else facing).normalized()
	_dash_t = DASH_DURATION
	Energy.spend(DASH_ENERGY)
	health.invulnerable = true
	collision_mask = MASK_DASHING
	_ghost_t = 0.0
	AudioManager.play(&"dash", -4.0)
	Fx.burst(self, PackedColorArray([Color("D8AD82"), Color("F6E3BE")]), 5, 35.0, Vector2(0, 4), 0.7)


func _end_dash() -> void:
	_dash_t = 0.0
	_dash_cd = DASH_COOLDOWN
	health.invulnerable = false
	collision_mask = MASK_NORMAL
	sprite.modulate.a = 1.0


# --- Daño ----------------------------------------------------------------------

## Llamado por los enemigos.
func take_hit(amount: int, from: Vector2) -> bool:
	return health.take_damage(amount, from, HURT_IFRAMES)


func _on_damaged(amount: int, from: Vector2) -> void:
	_flash_t = 0.15
	Fx.number(self, amount, Color("F2BAC5"))
	Fx.burst(self, PackedColorArray([Color("D34B55"), Color("F6E3BE")]), 6, 50.0, Vector2(0, -4))
	Fx.hitstop(0.06)
	Fx.shake(0.5)
	AudioManager.play(&"player_hurt")
	if from != Vector2.INF:
		_knock_vel = (global_position - from).normalized() * HURT_KNOCKBACK
		_knock_t = HURT_KNOCKBACK_TIME


func max_health() -> int:
	return MAX_HEALTH + GameState.bonus_health


func _on_upgrades_changed() -> void:
	var gained := max_health() - health.max_health
	health.max_health = max_health()
	if gained > 0:
		health.heal(gained)
	else:
		health.changed.emit(health.current, health.max_health)


func revive() -> void:
	health.restore_full()
	_knock_t = 0.0
	_dying_t = -1.0
	_reset_pose()


# --- Muerte --------------------------------------------------------------------

func is_dying() -> bool:
	return _dying_t >= 0.0


func _on_health_died() -> void:
	if is_dying():
		return
	_dying_t = 0.0
	velocity = Vector2.ZERO
	_attack_t = 0.0
	_sword.visible = false
	if is_dashing():
		_end_dash()
	sprite.frame = row_for(facing) * SHEET_COLUMNS + IDLE_COL
	AudioManager.play(&"player_die")
	Fx.shake(0.6)
	queue_redraw()


## Fila de muerte: el golpe, se le aflojan las rodillas, cae de espaldas (hacia el lado
## contrario a donde mira) y queda tendido.
const DEATH_FRAME_TIMES := [0.0, 0.14, 0.3, 0.5]


func _update_death(delta: float) -> void:
	var was := _dying_t
	_dying_t += delta
	velocity = Vector2.ZERO
	var side := -1.0 if facing.x > 0.0 else 1.0
	var col := 0
	for i in DEATH_FRAME_TIMES.size():
		if _dying_t >= DEATH_FRAME_TIMES[i]:
			col = i
	sprite.frame = DEATH_ROW * SHEET_COLUMNS + col + (0 if side < 0.0 else 4)
	sprite.rotation = 0.0
	sprite.position = SPRITE_POS
	sprite.scale = Vector2.ONE * SPRITE_SCALE
	sprite.skew = 0.0
	var gray := clampf((_dying_t - 0.3) / 0.4, 0.0, 1.0)
	sprite.modulate = Color(1, 0.55, 0.55).lerp(Color(0.8, 0.75, 0.85), gray)
	if was < 0.3 and _dying_t >= 0.3:
		Fx.burst(self, PackedColorArray([Color("D8AD82"), Color("F6E3BE")]), 6, 40.0,
			Vector2(side * 6.0, 4.0), 0.6)
	if was < DEATH_TIME and _dying_t >= DEATH_TIME:
		died.emit()


## Capa procedural encima de los frames del rig (los frames ya traen la pose; esto suma peso):
##   ataque: un empujón de 1 px y un estirón leve hacia el golpe
##   dash: deja estela
##   golpe recibido: se aplasta un instante
## Unity: sería animar localScale del SpriteRenderer desde código (tween a mano).
func _update_pose(delta: float) -> void:
	var offset := Vector2.ZERO
	var stretch := Vector2.ONE  # x = a lo largo de la acción, y = de costado
	var axis := Vector2.RIGHT
	var lean := 0.0
	if is_attacking():
		var k := 1.0 - _attack_t / ATTACK_DURATION
		var punch := sin(k * PI)  # 0 → 1 → 0
		axis = _attack_dir
		offset = _attack_dir * punch
		stretch = Vector2(1.0 + 0.06 * punch, 1.0 - 0.03 * punch)
	elif is_dashing():
		_ghost_t -= delta
		if _ghost_t <= 0.0:
			_ghost_t = AFTERIMAGE_EVERY
			_spawn_afterimage()
	elif _flash_t > 0.0:
		var k := _flash_t / 0.15
		stretch = Vector2(1.0 - 0.1 * k, 1.0 + 0.08 * k)  # aplastado por el golpe
		axis = Vector2.UP
	# En pixel art alcanza con estirar sobre el eje dominante (horizontal o vertical)
	var sc := stretch if absf(axis.x) >= absf(axis.y) else Vector2(stretch.y, stretch.x)
	sprite.scale = sc * SPRITE_SCALE
	sprite.skew = -lean
	sprite.rotation = 0.0
	sprite.position = (SPRITE_POS + offset).round()


func _reset_pose() -> void:
	sprite.scale = Vector2.ONE * SPRITE_SCALE
	sprite.skew = 0.0
	sprite.rotation = 0.0
	sprite.position = SPRITE_POS
	sprite.modulate = Color.WHITE


static var _ghost_mat: ShaderMaterial


static func _ghost_material() -> ShaderMaterial:
	if _ghost_mat == null:
		_ghost_mat = ShaderMaterial.new()
		_ghost_mat.shader = preload("res://assets/shaders/silhouette.gdshader")
	return _ghost_mat


## Copia del sprite actual que se queda en el lugar y se desvanece (estela del dash).
func _spawn_afterimage() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var g := Sprite2D.new()
	g.texture = sprite.texture
	g.hframes = sprite.hframes
	g.vframes = sprite.vframes
	g.frame = sprite.frame
	g.scale = sprite.scale
	g.skew = sprite.skew
	# Silueta sólida color agua: se lee sobre pasto y sobre camino
	g.material = _ghost_material()
	g.modulate = Color(1, 1, 1, 0.7)
	g.z_index = z_index
	g.add_to_group("afterimage")
	parent.add_child(g)
	parent.move_child(g, get_index())  # justo detrás del jugador (y arriba del suelo)
	g.global_position = sprite.global_position
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, AFTERIMAGE_LIFE)
	tw.tween_callback(g.queue_free)


## Destello rojo al recibir daño y parpadeo durante los i-frames.
func _update_feedback(delta: float) -> void:
	_flash_t = maxf(_flash_t - delta, 0.0)
	var color := Color.WHITE
	if _flash_t > 0.0:
		color = Color(1, 0.3, 0.3)  # mismo tinte que BarrenRoots
	if is_dashing():
		color = Color(0.85, 1.0, 0.97)  # leve tinte agua mientras es intangible
	if not is_dashing() and health.is_invulnerable() and _flash_t <= 0.0:
		color.a = 0.4 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
	sprite.modulate = color


# --- Animación -----------------------------------------------------------------

func _update_animation(delta: float, moving: bool) -> void:
	if moving != _was_moving:
		_was_moving = moving
		_anim_t = 0.0
	_anim_t += delta
	var row := row_for(facing)
	var col := IDLE_COL + int(_anim_t * ANIM_FPS) % 4
	if is_attacking():  # 4 frames repartidos en la duración del ataque
		var k := 1.0 - _attack_t / ATTACK_DURATION
		col = ATTACK_COL + mini(int(k * 4.0), 3)
	elif is_dashing():
		var k := 1.0 - _dash_t / DASH_DURATION
		row = row_for(_dash_dir)
		col = DASH_COL + mini(int(k * 4.0), 3)
	elif moving:
		col = WALK_COL + int(_anim_t * WALK_FPS) % 4
	sprite.frame = row * SHEET_COLUMNS + col


## Fila de la hoja para una dirección (8 sectores de 45°).
static func row_for(dir: Vector2) -> int:
	var sector := posmod(roundi(dir.angle() / (PI / 4.0)), 8)
	return DIR_ROWS[sector]


# --- Interacción ---------------------------------------------------------------

## Busca el interactuable (grupo "interactable") más cercano dentro del rango.
## Los grupos de Godot ≈ tags de Unity, pero un nodo puede tener varios.
func _update_focus() -> void:
	var best: Variant = null
	var best_dist := INTERACT_RANGE
	for node: Variant in get_tree().get_nodes_in_group("interactable"):
		var rect: Rect2 = node.get_interact_rect()
		var closest := global_position.clamp(rect.position, rect.end)
		var d := closest.distance_to(global_position)
		if d < best_dist:
			best_dist = d
			best = node
	if best != _focus:
		if is_instance_valid(_focus):
			_focus.set_focused(false)
		_focus = best
		if best != null:
			_focus.set_focused(true)


func set_camera_limits(bounds: Rect2) -> void:
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)


func teleport(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	_focus = null
	_knock_t = 0.0
	_dying_t = -1.0
	_reset_pose()
	if is_dashing():
		_end_dash()
	camera.reset_smoothing()
