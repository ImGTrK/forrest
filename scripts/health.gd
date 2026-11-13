class_name Health
extends Node
## Vida reutilizable (jugador y enemigos). Port de HealthSystem.cs de BarrenRoots:
## mismas ideas (eventos de cambio y muerte), pero con señales de Godot y con
## invulnerabilidad incorporada (i-frames tras recibir daño o durante el dash).
## Se agrega como nodo hijo, igual que un componente en Unity.

signal changed(current: int, max_value: int)
signal damaged(amount: int, from: Vector2)
signal died

@export var max_health: int = 6

var current: int = 0
## Invulnerabilidad forzada (ej. mientras dura el dash).
var invulnerable: bool = false
var _iframes_left: float = 0.0


func _ready() -> void:
	current = max_health


func _process(delta: float) -> void:
	_iframes_left = maxf(_iframes_left - delta, 0.0)


func is_invulnerable() -> bool:
	return invulnerable or _iframes_left > 0.0


func is_dead() -> bool:
	return current <= 0


## Aplica daño. Devuelve false si no entró (muerto o invulnerable).
## `iframes`: segundos de invulnerabilidad que deja el golpe.
func take_damage(amount: int, from: Vector2 = Vector2.INF, iframes: float = 0.0) -> bool:
	if is_dead() or is_invulnerable():
		return false
	current = maxi(current - amount, 0)
	_iframes_left = iframes
	changed.emit(current, max_health)
	damaged.emit(amount, from)
	if current == 0:
		died.emit()
	return true


func heal(amount: int) -> void:
	current = mini(current + amount, max_health)
	changed.emit(current, max_health)


func restore_full() -> void:
	current = max_health
	_iframes_left = 0.0
	changed.emit(current, max_health)
