class_name InventoryUI
extends CanvasLayer
## Pantalla de mochila (Tab) y de almacén (cofre del pueblo), lado a lado.
## Pausa el juego mientras está abierta (GDD §4.1), por eso usa process_mode = ALWAYS.
##
## Controles (estilo inventario por grilla):
##   Clic          agarrar / soltar (si se suelta encima de UN ítem, se intercambian)
##   R / clic der. rotar (el agarrado, o el que está bajo el mouse)
##   Shift + clic  pasar directo a la otra grilla (solo en el cofre)
##   Supr / X      tirar (el agarrado o el que está bajo el mouse), o soltar en "Tirar"
##   Ordenar       compacta la grilla

const BAR_UNDER := preload("res://assets/sprites/ui/energy_bar_under.png")  # 64x8
const BAR_FILL := preload("res://assets/sprites/ui/energy_bar_fill.png")    # 64x8
const ICON_WEIGHT := preload("res://assets/sprites/ui/icon_weight.png")     # 8x8
const STORAGE_VISIBLE_ROWS := 5
const CELL := InventoryGridView.CELL

var _chest_mode := false

# Ítem agarrado (sacado de su grilla, sigue al mouse) y de dónde salió
var _held: ItemInstance
var _held_origin: GridInventory
var _held_origin_pos := Vector2i.ZERO
var _held_origin_rot := false
var _hover_item: ItemInstance
var _hover_inv: GridInventory

var _title: Label
var _bag_view: InventoryGridView
var _weight_bar: TextureProgressBar
var _weight_label: Label
var _chest_box: VBoxContainer
var _storage_title: Label
var _storage_view: InventoryGridView
var _discard_button: Button
var _status: Label
var _footer: Label
var _tooltip: PanelContainer
var _tooltip_label: Label
var _cursor: Control


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

	_title = Label.new()
	root.add_child(_title)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	root.add_child(columns)

	# --- Mochila ---
	var bag_box := VBoxContainer.new()
	columns.add_child(bag_box)
	bag_box.add_child(_header("Mochila", func() -> void: _sort(GameState.bag)))
	_bag_view = InventoryGridView.new()
	bag_box.add_child(_bag_view)
	var weight_row := HBoxContainer.new()
	var weight_icon := TextureRect.new()
	weight_icon.texture = ICON_WEIGHT
	weight_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	weight_row.add_child(weight_icon)
	_weight_bar = TextureProgressBar.new()
	_weight_bar.texture_under = BAR_UNDER
	_weight_bar.texture_progress = BAR_FILL
	_weight_bar.step = 0.01
	_weight_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	weight_row.add_child(_weight_bar)
	_weight_label = Label.new()
	weight_row.add_child(_weight_label)
	bag_box.add_child(weight_row)
	_discard_button = _button("Tirar", func() -> void:
		if _held:
			discard_held())
	_discard_button.tooltip_text = ""
	bag_box.add_child(_discard_button)

	# --- Almacén (solo en el cofre) ---
	_chest_box = VBoxContainer.new()
	columns.add_child(_chest_box)
	var storage_header := _header("Almacén", func() -> void: _sort(GameState.storage))
	_storage_title = storage_header.get_child(0)
	_chest_box.add_child(storage_header)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(
		GameState.STORAGE_SIZE.x * CELL + 10, STORAGE_VISIBLE_ROWS * CELL)
	_chest_box.add_child(scroll)
	_storage_view = InventoryGridView.new()
	scroll.add_child(_storage_view)
	_chest_box.add_child(_button("Guardar todos los recursos",
		func() -> void: GameState.deposit_resources()))

	_status = Label.new()
	_status.modulate = Color(1, 0.85, 0.5)
	root.add_child(_status)
	_footer = Label.new()
	_footer.modulate = Color(1, 1, 1, 0.6)
	root.add_child(_footer)

	# --- Tooltip y cursor del ítem agarrado (siempre arriba de todo) ---
	_tooltip = PanelContainer.new()
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.visible = false
	_tooltip_label = Label.new()
	_tooltip.add_child(_tooltip_label)
	add_child(_tooltip)
	_cursor = Control.new()
	_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor.draw.connect(_draw_cursor)
	add_child(_cursor)

	for view in [_bag_view, _storage_view]:
		view.cell_pressed.connect(_on_cell_pressed)
		view.item_hovered.connect(_on_item_hovered)
	GameState.bag_changed.connect(_refresh)
	GameState.storage_changed.connect(_refresh)
	GameState.message.connect(func(text: String) -> void:
		if visible:
			_status.text = text)


# --- Abrir / cerrar ------------------------------------------------------------

func open_bag() -> void:
	_open(false)


func open_chest() -> void:
	_open(true)


func is_open() -> bool:
	return visible


func close() -> void:
	_return_held()
	visible = false
	_tooltip.visible = false
	get_tree().paused = false


func _open(chest: bool) -> void:
	_chest_mode = chest
	_title.text = "Almacén del pueblo" if chest else "Inventario"
	_chest_box.visible = chest
	_footer.text = "Clic: agarrar/soltar · R o clic der.: rotar · Supr: tirar\n" \
		+ ("Shift+clic: pasar al otro lado · " if chest else "") + "Esc: cerrar"
	_status.text = ""
	_refresh()
	visible = true
	get_tree().paused = true


func _refresh() -> void:
	_bag_view.show_grid(GameState.bag)
	_storage_view.show_grid(GameState.storage)
	var w := GameState.carried_weight()
	_weight_bar.max_value = GameState.max_weight()
	_weight_bar.value = w
	_weight_bar.tint_progress = Color(0.95, 0.35, 0.25) if GameState.is_overweight() else Color(0.45, 0.7, 0.95)
	_weight_label.text = "%.1f / %.0f kg%s" % [w, GameState.max_weight(),
		"  ¡sobrepeso!" if GameState.is_overweight() else ""]
	_storage_title.text = "Almacén (%d)" % GameState.storage.count()
	_discard_button.disabled = _held == null
	for view in [_bag_view, _storage_view]:
		view.held = _held
		view.queue_redraw()
	_cursor.queue_redraw()


# --- Acciones (públicas para poder testearlas) --------------------------------

func is_holding() -> bool:
	return _held != null


func held_item() -> ItemInstance:
	return _held


## Saca el ítem de su grilla y lo deja "en la mano".
func pick_up(inv: GridInventory, item: ItemInstance) -> void:
	if _held or not inv.has(item):
		return
	_held = item
	_held_origin = inv
	_held_origin_pos = inv.position_of(item)
	_held_origin_rot = item.rotated
	inv.remove(item)
	_tooltip.visible = false
	_refresh()


## Suelta el ítem agarrado con su esquina en `anchor`. Si debajo hay exactamente un
## ítem, se intercambian (el de abajo pasa a la mano). Devuelve true si se soltó.
func place_held(inv: GridInventory, anchor: Vector2i) -> bool:
	if _held == null:
		return false
	var s := _held.grid_size()
	if not inv.rect_in_bounds(anchor, s):
		return false
	var below := inv.items_in_rect(anchor, s)
	if below.size() > 1:
		GameState.notify("Hay más de un ítem en ese lugar")
		return false
	var item := _held
	_held = null
	if below.size() == 1:
		var other: ItemInstance = below[0]
		var other_pos := inv.position_of(other)
		inv.remove(other)
		inv.add_at(item, anchor)
		_held = other
		_held_origin = inv
		_held_origin_pos = other_pos
		_held_origin_rot = other.rotated
	else:
		inv.add_at(item, anchor)
	_refresh()
	return true


func rotate_held() -> void:
	if _held and _held.can_rotate():
		_held.rotated = not _held.rotated
		_refresh()


## Rota un ítem que ya está en la grilla, sin moverlo de su esquina.
func rotate_in_place(inv: GridInventory, item: ItemInstance) -> bool:
	if not item.can_rotate() or not inv.has(item):
		return false
	var pos := inv.position_of(item)
	inv.remove(item)
	item.rotated = not item.rotated
	if inv.add_at(item, pos):
		return true
	item.rotated = not item.rotated
	inv.add_at(item, pos)
	GameState.notify("No hay lugar para rotarlo ahí")
	return false


func discard_held() -> void:
	if _held == null:
		return
	GameState.discard(_held)
	_held = null
	_refresh()


func discard(inv: GridInventory, item: ItemInstance) -> void:
	if inv.remove(item):
		GameState.discard(item)


## Shift+clic: pasa el ítem a la otra grilla.
func quick_move(inv: GridInventory, item: ItemInstance) -> void:
	if inv == GameState.bag:
		GameState.deposit(item)
	else:
		GameState.withdraw(item)


func _sort(inv: GridInventory) -> void:
	_return_held()
	if not inv.sort():
		GameState.notify("No se pudo ordenar")


## Al cerrar (u ordenar) con algo en la mano, vuelve a donde estaba; si ese lugar
## se ocupó, al primer lugar libre de la mochila o del almacén.
func _return_held() -> void:
	if _held == null:
		return
	var item := _held
	_held = null
	var rot_now := item.rotated
	item.rotated = _held_origin_rot
	if not _held_origin.add_at(item, _held_origin_pos):
		item.rotated = rot_now
		if not _held_origin.add(item) and not GameState.bag.add(item):
			GameState.storage.add(item)
	_refresh()


# --- Input ---------------------------------------------------------------------

func _on_cell_pressed(view: InventoryGridView, cell: Vector2i, button: int, shift: bool) -> void:
	var inv := view.inventory
	var item := inv.item_at(cell)
	if button == MOUSE_BUTTON_RIGHT:
		if _held:
			rotate_held()
		elif item:
			rotate_in_place(inv, item)
		return
	if _held:
		place_held(inv, view.anchor_for(cell, _held.grid_size()))
	elif item:
		if shift and _chest_mode:
			quick_move(inv, item)
		else:
			pick_up(inv, item)


func _on_item_hovered(view: InventoryGridView, item: ItemInstance) -> void:
	if item == null and view.inventory != _hover_inv:
		return  # salió de una grilla mientras ya estaba sobre la otra
	_hover_item = item
	_hover_inv = view.inventory if item else null
	_tooltip.visible = item != null and _held == null
	if item:
		_tooltip_label.text = item.describe()
		_tooltip.reset_size()


func _unhandled_input(event: InputEvent) -> void:
	if visible:
		if event.is_action_pressed("rotate_item"):
			if _held:
				rotate_held()
			elif _hover_item:
				rotate_in_place(_hover_inv, _hover_item)
		elif event.is_action_pressed("discard_item"):
			if _held:
				discard_held()
			elif _hover_item:
				discard(_hover_inv, _hover_item)
				_tooltip.visible = false
		elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact") \
				or event.is_action_pressed("toggle_inventory"):
			close()
		else:
			return
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_inventory") and not get_tree().paused:
		# Si el juego ya está pausado por otra cosa (ej. durmiendo), no abrir encima.
		open_bag()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not visible:
		return
	var mouse := get_viewport().get_mouse_position()
	if _held:
		_cursor.position = mouse - Vector2(_held.grid_size() * CELL) / 2.0
		_cursor.queue_redraw()
	if _tooltip.visible:
		var vp := get_viewport().get_visible_rect().size
		_tooltip.position = (mouse + Vector2(10, 10)).clamp(Vector2.ZERO, vp - _tooltip.size)


func _draw_cursor() -> void:
	if _held:
		InventoryGridView.draw_item(_cursor, _held, Rect2(Vector2.ZERO, Vector2(_held.grid_size() * CELL)))


# --- Helpers de UI -------------------------------------------------------------

func _header(text: String, on_sort: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	row.add_child(_button("Ordenar", on_sort))
	return row


func _button(text: String, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(on_pressed)
	return b
