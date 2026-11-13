class_name EnemyBasic
extends Enemy
## Enemigo básico: persigue, hace el amago y muerde de cerca. Usa todo el comportamiento
## por defecto de Enemy; solo define sus números y su animación.

# --- Valores (BarrenRoots ×16 px) -------------------------------------------------
const SPEED := 48.0  # 3 u/s
const PERCEPTION := 80.0  # 5 u
const ATTACK_RANGE := 12.0  # ~0.6-0.75 u
const WINDUP_TIME := 0.35
const DAMAGE := 1  # medio corazón
const BASE_HEALTH := 3
## 32x16: 2 frames de 16x16 (de EnemyTemp.ase). Frame 1 es el normal, frame 0 el "parpadeo".
const TEXTURE := preload("res://assets/sprites/enemies/enemy_basic.png")


func _init() -> void:
	speed = SPEED
	perception = PERCEPTION
	attack_range = ATTACK_RANGE
	windup_time = WINDUP_TIME
	damage = DAMAGE
	base_health = BASE_HEALTH
	texture = TEXTURE
	hframes = 2


## Ciclo de 2.1 s: 0.1 s parpadeo (frame 0) + 2 s normal (frame 1), como el .ase
func _animate(_delta: float) -> void:
	_sprite.frame = 0 if fmod(_anim_t, 2.1) < 0.1 else 1
