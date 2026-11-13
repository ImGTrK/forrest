class_name PauseMenu
extends CanvasLayer
## Menú de pausa (Esc cuando no hay otro menú abierto). process_mode = ALWAYS en Main.tscn.

signal quit_to_menu

var _warning: Label


func _ready() -> void:
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)
	var title := Label.new()
	title.text = "Pausa"
	box.add_child(title)
	box.add_child(_button("Volver al juego", close))
	box.add_child(_button("Salir al menú principal", func() -> void:
		close()
		quit_to_menu.emit()))
	_warning = Label.new()
	_warning.modulate = Color(1, 0.75, 0.45)
	box.add_child(_warning)


func open(in_hub: bool) -> void:
	_warning.text = "Se guarda la partida." if in_hub \
		else "Estás en el bosque: se vuelve al último guardado\n(lo de este run se pierde)."
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false


func is_open() -> bool:
	return visible


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if visible:
		close()
		get_viewport().set_input_as_handled()
	elif not get_tree().paused:  # si hay otro menú abierto, Esc lo cierra a él
		var main := get_parent()
		open(main.is_in_hub() if main.has_method("is_in_hub") else true)
		get_viewport().set_input_as_handled()


func _button(text: String, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(on_pressed)
	return b
