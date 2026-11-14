class_name Projectile
extends Area2D
## Proyectil genérico: vuela recto, se rompe contra el mundo y daña al jugador.
## Lo usa el Lanzador (esporas) y lo puede reusar un jefe o una trampa: todo se configura
## con variables, sin heredar. Area2D ≈ un Collider2D con isTrigger en Unity.
##
## Se esquiva con el dash: durante el dash el jugador lo atraviesa sin romperlo.

signal hit(body: Node)

## Capas: 1 mundo · 2 jugador
const MASK := 1 | 2

var velocity := Vector2.ZERO
var damage := 1
var lifetime := 2.5
var radius := 3.0
## Altura visual sobre el piso: la colisión va a ras del suelo (como los pies del jugador)
## y el sprite se dibuja más arriba. Convención top-down: "dónde está" = la sombra.
var height := 5.0
var texture: Texture2D = preload("res://assets/sprites/enemies/spore.png")
var hframes := 2
var anim_fps := 10.0
## Colores de las partículas al romperse.
var pop_colors := PackedColorArray([Color("D4E2A1"), Color("B9D88B"), Color("F6E3BE")])

var _sprite: Sprite2D
var _t := 0.0
var _done := false


## Atajo: crea, configura y agrega el proyectil a `parent`.
static func spawn(parent: Node, pos: Vector2, vel: Vector2, dmg := 1) -> Projectile:
	var p := Projectile.new()
	p.velocity = vel
	p.damage = dmg
	p.position = pos
	parent.add_child(p)
	return p


func _ready() -> void:
	collision_layer = 0
	collision_mask = MASK
	var shape := CircleShape2D.new()
	shape.radius = radius
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.hframes = hframes
	_sprite.position = Vector2(0, -height)
	add_child(_sprite)
	z_index = 5
	body_entered.connect(_on_body_entered)
	add_to_group("projectile")


func _physics_process(delta: float) -> void:
	if _done:
		return
	position += velocity * delta
	_t += delta
	_sprite.frame = int(_t * anim_fps) % hframes
	if _t >= lifetime:
		pop()


## Sombrita en el piso: ayuda a leer por dónde va a pasar.
func _draw() -> void:
	draw_rect(Rect2(-2, 0, 4, 1), Color(0.23, 0.18, 0.27, 0.35))


func _on_body_entered(body: Node) -> void:
	if _done:
		return
	if body is Player:
		var p := body as Player
		if p.is_dashing() or p.health.is_dead():
			return  # esquivado: sigue de largo
		p.take_hit(damage, global_position - velocity.normalized() * 8.0)
		hit.emit(body)
		pop()
	elif body is Enemy:
		return  # pasa entre enemigos (no hay fuego amigo)
	else:
		hit.emit(body)
		pop()


## Se rompe: partículas, sonido y desaparece.
func pop() -> void:
	if _done:
		return
	_done = true
	Fx.burst(self, pop_colors, 6, 40.0)
	AudioManager.play(&"pop", -6.0)
	queue_free()


func is_done() -> bool:
	return _done
