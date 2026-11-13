class_name Interactable
extends StaticBody2D
## Clase base de todo lo que el jugador usa con E: cofre, cama, mesa, tablón y recursos.
## (≈ una clase abstracta de C# con métodos virtuales: los hijos sobrescriben solo lo que cambia.)
##
## Lo que resuelve la base:
##   - colisión, sprite y grupo "interactable" (lo que busca Player._update_focus)
##   - contorno blanco cuando el jugador la tiene enfocada
##   - cartel opcional con su nombre arriba
##   - señal `used` al interactuar
##
## Cómo se hace un hijo:
##   1. extends Interactable
##   2. en _init(): setear `size`, `texture` y opcionalmente `label_text` / `label_offset`
##   3. sobrescribir lo que haga falta: _on_interact(), _collision_rect(), _draw_overlay(),
##      is_interactive(). Si un hijo define _ready() tiene que llamar a super._ready().

## Se emite al interactuar (comportamiento por defecto de _on_interact).
signal used

## Tamaño en píxeles (múltiplo de 16). Origen en la esquina superior izquierda.
var size := Vector2(16, 16)
var texture: Texture2D
## Cartel fijo encima del objeto ("" = sin cartel).
var label_text := ""
var label_offset := Vector2.ZERO

var _focused := false
var _sprite: Sprite2D


func _ready() -> void:
	var rect := _collision_rect()
	if rect.has_area():
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		var col := CollisionShape2D.new()
		col.shape = shape
		col.position = rect.get_center()
		add_child(col)
	if texture:
		_sprite = Sprite2D.new()
		_sprite.texture = texture
		_sprite.centered = false
		add_child(_sprite)
	if label_text != "":
		var label := Label.new()
		label.text = label_text
		label.position = label_offset
		label.add_theme_font_size_override("font_size", 8)
		add_child(label)
	if is_interactive():
		add_to_group("interactable")


# --- Interfaz que usa Player ---------------------------------------------------

func get_interact_rect() -> Rect2:
	return Rect2(global_position, size)


func set_focused(value: bool) -> void:
	_focused = value
	queue_redraw()


func interact(by: Node) -> void:
	_on_interact(by)


# --- Métodos virtuales (sobrescribir en los hijos) --------------------------------

## Qué pasa al apretar E. Por defecto avisa con `used` (Main/Hub deciden qué abrir).
func _on_interact(_by: Node) -> void:
	used.emit()


## Rectángulo de colisión en coordenadas locales. Por defecto: todo el objeto menos 1 px por lado.
## Rect vacío = sin colisión.
func _collision_rect() -> Rect2:
	return Rect2(Vector2.ONE, size - Vector2(2, 2))


## false = no entra al grupo "interactable" (ej. arbustos decorativos).
func is_interactive() -> bool:
	return true


## Dibujo extra encima del sprite (avisos, placeholders). Se llama desde _draw().
func _draw_overlay() -> void:
	pass


func _draw() -> void:
	_draw_overlay()
	if _focused:
		draw_rect(Rect2(Vector2.ZERO, size).grow(1), Color.WHITE, false, 1.0)
