class_name CraftingUI
extends CanvasLayer
## Mesa de crafting (port de "UI de Crafting" de BarrenRoots):
##   Panel 1: recetas (y reparación)
##   Panel 2: para cada ingrediente, qué ejemplares usar (de la mochila y del almacén)
##   Panel 3: vista previa del resultado comparada con lo que ya tenés + Fabricar
## Pausa el juego mientras está abierta (process_mode = ALWAYS en Main.tscn).

## Anchos de columna (el viewport mide 640 px)
const COL_RECIPES := 135
const COL_MATERIALS := 160
const COL_RESULT := 165

var _recipe: RecipeData
var _selection := {}  # índice de ingrediente -> Array[ItemInstance]

var _recipe_buttons: Array[Button] = []
var _repair_box: VBoxContainer
var _materials_box: VBoxContainer
var _result_title: Label
var _result_stats: RichTextLabel
var _craft_button: Button
var _status: Label
var _tooltip: PanelContainer
var _tooltip_label: Label


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
	root.add_child(_label("Mesa de trabajo"))

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	root.add_child(columns)

	# --- Panel 1: recetas + reparar ---
	var col1 := VBoxContainer.new()
	col1.custom_minimum_size.x = COL_RECIPES
	columns.add_child(col1)
	col1.add_child(_label("Recetas", true))
	for r: RecipeData in Crafting.RECIPES:
		var b := Button.new()
		b.text = r.result.display_name
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.custom_minimum_size.x = COL_RECIPES
		b.pressed.connect(select_recipe.bind(r))
		col1.add_child(b)
		_recipe_buttons.append(b)
	col1.add_child(_label("Reparar", true))
	_repair_box = VBoxContainer.new()
	col1.add_child(_repair_box)

	# --- Panel 2: materiales ---
	var col2 := VBoxContainer.new()
	col2.custom_minimum_size.x = COL_MATERIALS
	columns.add_child(col2)
	col2.add_child(_label("Materiales", true))
	_materials_box = VBoxContainer.new()
	col2.add_child(_materials_box)

	# --- Panel 3: resultado ---
	var col3 := VBoxContainer.new()
	col3.custom_minimum_size.x = COL_RESULT
	columns.add_child(col3)
	col3.add_child(_label("Resultado", true))
	_result_title = _label("")
	col3.add_child(_result_title)
	_result_stats = RichTextLabel.new()
	_result_stats.bbcode_enabled = true
	_result_stats.fit_content = true
	_result_stats.scroll_active = false
	_result_stats.custom_minimum_size = Vector2(COL_RESULT, 0)
	col3.add_child(_result_stats)
	_craft_button = Button.new()
	_craft_button.text = "Fabricar"
	_craft_button.focus_mode = Control.FOCUS_NONE
	_craft_button.pressed.connect(craft)
	col3.add_child(_craft_button)

	_status = _label("")
	_status.modulate = Color(1, 0.85, 0.5)
	root.add_child(_status)
	var footer := _label("Clic en un material: elegir/quitar · Esc / E: cerrar")
	footer.modulate = Color(1, 1, 1, 0.6)
	root.add_child(footer)

	_tooltip = PanelContainer.new()
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.visible = false
	_tooltip_label = Label.new()
	_tooltip.add_child(_tooltip_label)
	add_child(_tooltip)

	GameState.message.connect(func(text: String) -> void:
		if visible:
			_status.text = text)


# --- API (pública para testear) ------------------------------------------------

func open() -> void:
	_status.text = ""
	visible = true
	get_tree().paused = true
	select_recipe(_recipe if _recipe else Crafting.RECIPES[0])


func close() -> void:
	visible = false
	_tooltip.visible = false
	get_tree().paused = false


func is_open() -> bool:
	return visible


func selection() -> Dictionary:
	return _selection


func select_recipe(recipe: RecipeData) -> void:
	_recipe = recipe
	_selection = Crafting.auto_select(recipe, GameState.owned_items())
	_refresh()


## Elegir/quitar un ejemplar para el ingrediente `i`. Si ya está lleno, reemplaza el último.
func toggle_material(i: int, item: ItemInstance) -> void:
	var chosen: Array = _selection[i]
	if chosen.has(item):
		chosen.erase(item)
	else:
		if chosen.size() >= _recipe.ingredient_count(i):
			chosen.pop_back()
		chosen.append(item)
	_refresh()


func craft() -> ItemInstance:
	var item := Crafting.craft(_recipe, _selection)
	if item:
		select_recipe(_recipe)  # nueva selección con lo que quedó
	return item


# --- Dibujo --------------------------------------------------------------------

func _refresh() -> void:
	for b in _recipe_buttons:
		b.button_pressed = b.text == _recipe.result.display_name
	_build_materials()
	_build_result()
	_build_repairs()


func _build_materials() -> void:
	_clear(_materials_box)
	var owned := GameState.owned_items()
	for i in _recipe.ingredients.size():
		var data := _recipe.ingredient_item(i)
		var need := _recipe.ingredient_count(i)
		var chosen: Array = _selection[i]
		var cands := Crafting.candidates(_recipe, i, owned)
		var head := _label("%s  %d/%d" % [data.display_name, chosen.size(), need])
		if cands.size() < need:
			head.text += "  (te faltan %d)" % (need - cands.size())
			head.modulate = Color(0.95, 0.4, 0.35)
		_materials_box.add_child(head)
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 1)
		flow.add_theme_constant_override("v_separation", 1)
		for it in cands:
			var chip := ItemChip.new(it)
			chip.selected = chosen.has(it)
			chip.pressed.connect(func(_c: ItemChip) -> void: toggle_material(i, it))
			chip.hovered.connect(_show_tooltip)
			flow.add_child(chip)
		_materials_box.add_child(flow)


func _build_result() -> void:
	var preview := Crafting.preview(_recipe, _selection)
	var data := _recipe.result
	_result_title.text = data.display_name + ("  · nivel %d" % data.tool_level if data.tool_level > 0 else "")
	_craft_button.disabled = preview == null
	if preview == null:
		_result_stats.text = "[color=gray]Elegí todos los materiales para ver el resultado.[/color]"
		return
	var current := GameState.best_owned_like(data)
	var lines: PackedStringArray = ["calidad %d%%" % preview.quality]
	for stat in ["poder", "durabilidad", "peso"]:
		var v: float = preview.stats.get(stat, 0.0)
		var line := "%s %s" % [stat, _fmt(stat, v)]
		if current:
			var diff: float = v - current.stats.get(stat, 0.0)
			var better := diff < 0.0 if stat == "peso" else diff > 0.0
			if absf(diff) >= 0.05:
				line += "  [color=%s](%s%s)[/color]" % ["#8fd16a" if better else "#f26b5b",
					"+" if diff > 0 else "", _fmt(stat, diff)]
		lines.append(line)
	if current:
		lines.append("[color=gray]vs. la que tenés[/color]")
	else:
		lines.append("[color=gray]no tenés ninguno de este tipo[/color]")
	_result_stats.text = "\n".join(lines)


func _build_repairs() -> void:
	_clear(_repair_box)
	var owned := GameState.owned_items()
	var any := false
	for it in owned:
		if not Crafting.needs_repair(it):
			continue
		any = true
		var mat := Crafting.repair_material_for(it, owned)
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.custom_minimum_size.x = COL_RECIPES
		var recipe := Crafting.recipe_for(it.data)
		var cost := recipe.repair_material.display_name if recipe and recipe.repair_material else "?"
		b.text = it.display_name()
		b.modulate = it.condition_color().lerp(Color.WHITE, 0.5)
		b.disabled = mat == null
		b.pressed.connect(func() -> void:
			Crafting.repair(it)
			_refresh())
		_repair_box.add_child(b)
		var detail := _label("  %d/%d · cuesta 1 %s" % [ceili(it.durability), roundi(it.max_durability()), cost])
		detail.modulate = Color(1, 1, 1, 0.6) if mat else Color(0.95, 0.4, 0.35)
		_repair_box.add_child(detail)
	if not any:
		var l := _label("Nada para reparar")
		l.modulate = Color(1, 1, 1, 0.5)
		_repair_box.add_child(l)


static func _fmt(stat: String, v: float) -> String:
	if stat == "durabilidad":
		return "%d" % roundi(v)
	return "%.1f%s" % [v, " kg" if stat == "peso" else ""]


# --- Tooltip / input -----------------------------------------------------------

func _show_tooltip(item: ItemInstance) -> void:
	_tooltip.visible = item != null
	if item:
		_tooltip_label.text = item.describe()
		_tooltip.reset_size()


func _process(_delta: float) -> void:
	if visible and _tooltip.visible:
		var vp := get_viewport().get_visible_rect().size
		var pos := get_viewport().get_mouse_position() + Vector2(10, 10)
		_tooltip.position = pos.clamp(Vector2.ZERO, vp - _tooltip.size)


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact")):
		close()
		get_viewport().set_input_as_handled()


# --- Helpers -------------------------------------------------------------------

func _label(text: String, header: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	if header:
		l.modulate = Color(0.75, 0.8, 0.9)
	return l


static func _clear(box: Node) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
