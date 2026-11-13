class_name HitFlash
extends Node
## Componente: destello de color (y sacudida opcional) sobre un CanvasItem al recibir un golpe.
## Se agrega como hijo, como un MonoBehaviour de Unity: `add_child(HitFlash.new(sprite))`.
## Lo usan los recursos (destello blanco + sacudida) y los enemigos (destello rojo).
## Componer en vez de heredar: cualquier cosa golpeable lo puede usar, sea o no Interactable.

## Lo que se ilumina. Puede ser null (ej. recurso sin sprite): entonces solo se lee amount().
var target: CanvasItem
var _color := Color.WHITE
var _duration := 0.1
var _shake := 0.0
var _t := 0.0
var _base_x := 0.0


func _init(p_target: CanvasItem = null) -> void:
	target = p_target


## color: tinte en el pico del destello (valores >1 = más brillante que el sprite).
## shake: amplitud en px de la sacudida horizontal (0 = sin sacudida).
func flash(color: Color, duration: float, shake := 0.0) -> void:
	if _t <= 0.0 and target is Node2D:
		_base_x = (target as Node2D).position.x
	_color = color
	_duration = maxf(duration, 0.001)
	_shake = shake
	_t = _duration


func is_active() -> bool:
	return _t > 0.0


## 1 recién golpeado → 0 terminado.
func amount() -> float:
	return clampf(_t / _duration, 0.0, 1.0)


func _process(delta: float) -> void:
	if _t <= 0.0:
		return
	_t = maxf(_t - delta, 0.0)
	var k := amount()
	if target:
		target.modulate = Color.WHITE.lerp(_color, k)
		if _shake > 0.0 and target is Node2D:
			(target as Node2D).position.x = _base_x + sin(k * 30.0) * _shake * k
	var parent := get_parent()
	if parent is CanvasItem:
		(parent as CanvasItem).queue_redraw()
