class_name EnemyBasic
extends Enemy
## Erizo-fruta: persigue, hace el amago y muerde de cerca. Usa todo el comportamiento
## por defecto de Enemy; solo define sus números y su hoja.

# --- Valores (BarrenRoots ×16 px) -------------------------------------------------
const SPEED := 48.0  # 3 u/s
const PERCEPTION := 80.0  # 5 u
const ATTACK_RANGE := 12.0  # ~0.6-0.75 u
const WINDUP_TIME := 0.35
const DAMAGE := 1  # medio corazón
const BASE_HEALTH := 3
## Hoja estándar 64×64: 4×4 frames de 16×16 (ver Enemy.ROW_*).
const TEXTURE := preload("res://assets/sprites/enemies/enemy_basic.png")


func _init() -> void:
	speed = SPEED
	perception = PERCEPTION
	attack_range = ATTACK_RANGE
	windup_time = WINDUP_TIME
	damage = DAMAGE
	base_health = BASE_HEALTH
	texture = TEXTURE
	hframes = 4
	vframes = 4
