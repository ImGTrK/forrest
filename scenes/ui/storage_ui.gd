class_name StorageUI
extends CanvasLayer
## Pantalla de inventario/almacén. Pausa el juego mientras está abierta
## (GDD §4.1: los menús pausan el reloj). Por eso este nodo usa
## process_mode = ALWAYS (en Main.tscn): sigue recibiendo input con el árbol pausado.

var _title: Label
var _list: RichTextLabel


func _ready() -> void:
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 32)
	add_child(panel)

	var box := VBoxContainer.new()
	panel.add_child(box)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 11)
	box.add_child(_title)
	_list = RichTextLabel.new()
	_list.bbcode_enabled = true
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_list)
	var footer := Label.new()
	footer.text = "Esc / E / Tab: cerrar"
	footer.modulate = Color(1, 1, 1, 0.6)
	box.add_child(footer)


func open_storage() -> void:
	_open("Almacén del pueblo", GameState.storage)


func open_run_inventory() -> void:
	_open("Lo que cargás (se pierde parte si colapsás o morís)", GameState.run_inventory)


func close() -> void:
	visible = false
	get_tree().paused = false


func _open(title: String, items: Array[Dictionary]) -> void:
	_title.text = "%s  —  %d ítems" % [title, items.size()]
	_list.text = _format(items)
	visible = true
	get_tree().paused = true


func _unhandled_input(event: InputEvent) -> void:
	if visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact") \
				or event.is_action_pressed("toggle_inventory"):
			close()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_inventory"):
		open_run_inventory()
		get_viewport().set_input_as_handled()


## Agrupa por tipo y ordena por calidad (lo mejor arriba).
static func _format(items: Array[Dictionary]) -> String:
	if items.is_empty():
		return "[i]Vacío.[/i]"
	var by_type := {}
	for item in items:
		if not by_type.has(item.name):
			by_type[item.name] = []
		by_type[item.name].append(item)
	var out := ""
	for type_name: String in by_type:
		var list: Array = by_type[type_name]
		list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.quality > b.quality)
		out += "[b]%s[/b] ×%d\n" % [type_name, list.size()]
		for item: Dictionary in list:
			var stats: PackedStringArray = []
			for s: String in item.stats:
				stats.append("%s %.1f" % [s, item.stats[s]])
			out += "   [color=%s]%3d%%[/color]   %s   [color=gray](prof. %d)[/color]\n" % [
				_quality_color(item.quality), item.quality, "  ·  ".join(stats), item.depth]
		out += "\n"
	return out


static func _quality_color(q: int) -> String:
	if q >= 80:
		return "gold"
	if q >= 55:
		return "lightgreen"
	return "white"
