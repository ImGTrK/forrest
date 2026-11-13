class_name MissionBoardUI
extends CanvasLayer
## Pantalla del tablón: las misiones activas con su progreso y recompensa, botón
## para reclamar, y el resumen de mejoras permanentes obtenidas.
## Pausa el juego mientras está abierta (process_mode = ALWAYS en Main.tscn).

var _list: VBoxContainer
var _upgrades: Label
var _status: Label


func _ready() -> void:
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	panel.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	margin.add_child(root)

	root.add_child(_label("Tablón de misiones"))
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	root.add_child(_list)
	_upgrades = _label("")
	_upgrades.modulate = Color(0.75, 0.8, 0.9)
	root.add_child(_upgrades)
	_status = _label("")
	_status.modulate = Color(1, 0.85, 0.5)
	root.add_child(_status)
	var footer := _label("Las entregas usan la mochila y el almacén · Esc / E: cerrar")
	footer.modulate = Color(1, 1, 1, 0.6)
	root.add_child(footer)

	Missions.changed.connect(_refresh)
	GameState.message.connect(func(text: String) -> void:
		if visible:
			_status.text = text)


func open() -> void:
	_status.text = ""
	_refresh()
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false


func is_open() -> bool:
	return visible


func _refresh() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	for m in Missions.active:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var info := VBoxContainer.new()
		info.custom_minimum_size.x = 400
		info.add_child(_label(m.title()))
		var detail := _label("Progreso %s · Recompensa: %s" % [
			m.progress_text(), GameState.upgrade_text(m.reward)])
		detail.modulate = Color(0.55, 0.85, 0.45) if m.is_complete() else Color(1, 1, 1, 0.65)
		info.add_child(detail)
		row.add_child(info)
		var b := Button.new()
		b.text = "Reclamar"
		b.focus_mode = Control.FOCUS_NONE
		b.disabled = not m.is_complete()
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(func() -> void: Missions.claim(m))
		row.add_child(b)
		_list.add_child(row)
	_upgrades.text = "Mejoras obtenidas: +%d kg · +%d energía · +%d corazones  (%d misiones)" % [
		GameState.bonus_weight, GameState.bonus_energy,
		GameState.bonus_health / GameState.UPGRADE_HEALTH, Missions.completed]


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact")):
		close()
		get_viewport().set_input_as_handled()


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	return l
