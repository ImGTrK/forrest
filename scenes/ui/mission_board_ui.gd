class_name MissionBoardUI
extends CanvasLayer
## Pantalla del tablón: las misiones activas con su progreso y recompensa, botón
## para reclamar, y el resumen de mejoras permanentes obtenidas.
## Hito 11: en las misiones de entrega, "Reclamar" abre un selector para elegir qué
## ejemplares dar (vienen marcados los peores que sirven).
## Pausa el juego mientras está abierta (process_mode = ALWAYS en Main.tscn).

var _list: VBoxContainer
var _upgrades: Label
var _status: Label
var _picker: VBoxContainer
var _picking: Mission
var _chosen: Array = []


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
	_picker = VBoxContainer.new()
	_picker.add_theme_constant_override("separation", 6)
	_picker.visible = false
	root.add_child(_picker)
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
	close_picker()
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
		b.pressed.connect(func() -> void:
			if m.needs_items():
				open_picker(m)
			else:
				Missions.claim(m))
		row.add_child(b)
		_list.add_child(row)
	_upgrades.text = "Mejoras obtenidas: +%d kg · +%d energía · +%d corazones  (%d misiones)" % [
		GameState.bonus_weight, GameState.bonus_energy,
		GameState.bonus_health / GameState.UPGRADE_HEALTH, Missions.completed]


# --- Elegir qué entregar ---------------------------------------------------------------

func open_picker(m: Mission) -> void:
	_picking = m
	_chosen = Missions.default_choice(m)
	_list.visible = false
	_picker.visible = true
	_build_picker()


func close_picker() -> void:
	_picking = null
	_chosen = []
	_picker.visible = false
	_list.visible = true


func is_picking() -> bool:
	return _picking != null


func chosen() -> Array:
	return _chosen


## Marca o desmarca un ejemplar. Si ya hay `count` marcados, reemplaza el más viejo.
func toggle_choice(it: ItemInstance) -> void:
	if _picking == null:
		return
	if _chosen.has(it):
		_chosen.erase(it)
	else:
		if _chosen.size() >= _picking.count:
			_chosen.pop_front()
		_chosen.append(it)
	_build_picker()


func confirm_picker() -> bool:
	if _picking == null or not Missions.is_valid_choice(_picking, _chosen):
		return false
	var m := _picking
	var give := _chosen.duplicate()
	close_picker()
	return Missions.claim(m, give)


func _build_picker() -> void:
	for c in _picker.get_children():
		_picker.remove_child(c)
		c.queue_free()
	var m := _picking
	_picker.add_child(_label("%s · Recompensa: %s" % [m.title(), GameState.upgrade_text(m.reward)]))
	var head := _label("Elegí qué entregar (%d de %d). Vienen marcados los peores." % [_chosen.size(), m.count])
	head.modulate = Color(1, 1, 1, 0.7)
	_picker.add_child(head)
	var hint := _label("")
	hint.modulate = Color(0.85, 0.9, 1.0)
	var flow := HFlowContainer.new()
	flow.custom_minimum_size.x = 400
	flow.add_theme_constant_override("h_separation", 2)
	flow.add_theme_constant_override("v_separation", 2)
	for it in m.qualifying_items():
		var chip := ItemChip.new(it)
		chip.selected = _chosen.has(it)
		chip.pressed.connect(func(c: ItemChip) -> void: toggle_choice(c.item))
		chip.hovered.connect(func(i: ItemInstance) -> void: hint.text = i.describe() if i else "")
		flow.add_child(chip)
	_picker.add_child(flow)
	_picker.add_child(hint)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	var give := Button.new()
	give.text = "Entregar"
	give.focus_mode = Control.FOCUS_NONE
	give.disabled = not Missions.is_valid_choice(m, _chosen)
	give.pressed.connect(confirm_picker)
	buttons.add_child(give)
	var back := Button.new()
	back.text = "Volver"
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(close_picker)
	buttons.add_child(back)
	_picker.add_child(buttons)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		if is_picking():
			close_picker()  # Esc en el selector vuelve a la lista
		else:
			close()
		get_viewport().set_input_as_handled()


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	return l
