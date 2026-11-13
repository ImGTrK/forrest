extends Control
## Menú principal: Continuar (si hay guardado), Nueva partida, Salir.
## Nueva partida con guardado existente pide confirmación (segundo clic).

const GAME_SCENE := "res://scenes/Main.tscn"

var _continue: Button
var _new: Button
var _info: Label
var _confirm_new := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.09, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH

	var title := Label.new()
	title.text = "FORREST"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	box.add_child(title)
	_continue = _button("Continuar", continue_game)
	box.add_child(_continue)
	_new = _button("Nueva partida", _on_new_pressed)
	box.add_child(_new)
	box.add_child(_button("Salir", func() -> void: get_tree().quit()))
	_info = Label.new()
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.modulate = Color(1, 1, 1, 0.6)
	box.add_child(_info)

	_continue.disabled = not SaveSystem.has_save()
	_info.text = "Hay una partida guardada" if SaveSystem.has_save() else "Sin partida guardada"


func continue_game() -> void:
	if SaveSystem.load_game():
		get_tree().change_scene_to_file(GAME_SCENE)
	else:
		_info.text = SaveSystem.last_error if SaveSystem.last_error != "" else "No se pudo cargar la partida guardada"


func new_game() -> void:
	SaveSystem.new_game()
	SaveSystem.delete_save()
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_new_pressed() -> void:
	if SaveSystem.has_save() and not _confirm_new:
		_confirm_new = true
		_new.text = "¿Seguro? Se borra la partida guardada"
		return
	new_game()


func _button(text: String, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size.x = 200
	b.pressed.connect(on_pressed)
	return b
