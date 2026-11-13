class_name GameHUD
extends CanvasLayer
## HUD: vida, reloj, energía, ubicación, resumen de lo cargado, mensajes y minimapa.
## CanvasLayer ≈ un Canvas de Unity en Screen Space Overlay.

const ICON_CLOCK := preload("res://assets/sprites/ui/icon_clock.png")    # 8x8
const ICON_ENERGY := preload("res://assets/sprites/ui/icon_energy.png")  # 8x8
const BAR_UNDER := preload("res://assets/sprites/ui/energy_bar_under.png")  # 64x8
const BAR_FILL := preload("res://assets/sprites/ui/energy_bar_fill.png")    # 64x8
## Tinte de la barra por estado de energía (Energy.State). El PNG del relleno es claro
## (blanco/gris) para que el tinte decida el color: normal, cansado, agotado, desmayado.
const BAR_TINTS := [Color(0.45, 0.85, 0.35), Color(0.95, 0.8, 0.25), Color(0.95, 0.35, 0.25), Color(0.95, 0.35, 0.25)]

## Corazones de BarrenRoots (16x16). Cada corazón = 2 de vida.
const HEART_FULL := preload("res://assets/sprites/ui/hearts/heart_full.png")
const HEART_HALF := preload("res://assets/sprites/ui/hearts/heart_half.png")
const HEART_EMPTY := preload("res://assets/sprites/ui/hearts/heart_empty.png")

## Casillas de equipo: [tipo de herramienta o &"weapon", letra si está vacía]
const EQUIP_SLOTS := [[&"axe", "H"], [&"pickaxe", "P"], [&"weapon", "E"], [&"light", "L"]]
## Para la barra de aceite: minutos que se consideran "lleno".
const OIL_BAR_FULL := 180.0
const EQUIP_CELL := 18
const SLOT := preload("res://assets/sprites/ui/slot.png")

var _equip: Control
var _hearts: HBoxContainer
var _clock: Label
var _energy_bar: TextureProgressBar
var _last_minute := -1
var _location: Label
var _carried: Label
var _toast: Label
var _hint: Label
var _minimap: Minimap
var _toast_tween: Tween
var _in_hub := false


func _ready() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(8, 6)
	add_child(box)

	_hearts = HBoxContainer.new()
	_hearts.add_theme_constant_override("separation", 1)
	box.add_child(_hearts)

	var clock_row := HBoxContainer.new()
	clock_row.add_child(_icon(ICON_CLOCK))
	_clock = Label.new()
	clock_row.add_child(_clock)
	box.add_child(clock_row)

	var energy_row := HBoxContainer.new()
	energy_row.add_child(_icon(ICON_ENERGY))
	_energy_bar = TextureProgressBar.new()
	_energy_bar.texture_under = BAR_UNDER
	_energy_bar.texture_progress = BAR_FILL
	_energy_bar.max_value = Energy.max_value()
	_energy_bar.step = 0.01
	_energy_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	energy_row.add_child(_energy_bar)
	box.add_child(energy_row)

	_location = Label.new()
	_carried = Label.new()
	box.add_child(_location)
	box.add_child(_carried)

	_minimap = Minimap.new()
	_minimap.anchor_left = 1.0
	_minimap.anchor_right = 1.0
	_minimap.offset_left = -108
	_minimap.offset_right = -8
	_minimap.offset_top = 8
	_minimap.offset_bottom = 78
	add_child(_minimap)

	_toast = Label.new()
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.offset_top = -48
	_toast.offset_bottom = -32
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	add_child(_toast)

	_hint = Label.new()
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_hint.offset_top = -18
	_hint.offset_left = 8
	_hint.modulate = Color(1, 1, 1, 0.6)
	_hint.text = "WASD mover · Clic/J atacar · Espacio dash · E usar · L luz · Tab inventario"
	add_child(_hint)

	# Equipo en uso (abajo a la derecha): hacha, pico, arma
	_equip = Control.new()
	_equip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_equip.anchor_left = 1.0
	_equip.anchor_right = 1.0
	_equip.anchor_top = 1.0
	_equip.anchor_bottom = 1.0
	_equip.offset_left = -(EQUIP_SLOTS.size() * (EQUIP_CELL + 2)) - 6
	_equip.offset_top = -EQUIP_CELL - 10
	_equip.offset_right = -6
	_equip.offset_bottom = -6
	_equip.draw.connect(_draw_equipment)
	add_child(_equip)
	GameState.equipment_changed.connect(_equip.queue_redraw)
	GameState.lantern_changed.connect(_equip.queue_redraw)

	GameState.bag_changed.connect(_refresh_carried)
	GameState.storage_changed.connect(func() -> void:
		if _in_hub:
			set_hub())
	GameState.message.connect(show_toast)
	ForestSession.zone_entered.connect(_on_zone_entered)
	Clock.time_advanced.connect(func(_m: float) -> void: refresh_clock())
	Energy.changed.connect(_on_energy_changed)
	Energy.state_changed.connect(_on_energy_state)
	_refresh_carried()
	refresh_clock()
	_on_energy_changed(Energy.value, Energy.max_value())
	_on_energy_state(Energy.state)


func bind_player(player: Player) -> void:
	player.health.changed.connect(update_hearts)
	update_hearts(player.health.current, player.health.max_health)


## Misma lógica que UIHeartsManager.UpdateHearts() de BarrenRoots.
func update_hearts(current: int, max_value: int) -> void:
	var total := ceili(max_value / 2.0)
	while _hearts.get_child_count() < total:
		var r := TextureRect.new()
		r.stretch_mode = TextureRect.STRETCH_KEEP
		_hearts.add_child(r)
	while _hearts.get_child_count() > total:
		var last := _hearts.get_child(_hearts.get_child_count() - 1)
		_hearts.remove_child(last)
		last.queue_free()
	for i in total:
		var heart_value := (i + 1) * 2
		var r: TextureRect = _hearts.get_child(i)
		if current >= heart_value:
			r.texture = HEART_FULL
		elif current == heart_value - 1:
			r.texture = HEART_HALF
		else:
			r.texture = HEART_EMPTY


func refresh_clock() -> void:
	var minute := floori(Clock.total_minutes)
	if minute == _last_minute:
		return
	_last_minute = minute
	_clock.text = "Día %d  ·  %s  ·  %s" % [Clock.day(), Clock.time_string(), Clock.period_name()]


func _on_energy_changed(value: float, max_value: float) -> void:
	_energy_bar.max_value = max_value
	_energy_bar.value = value


func _on_energy_state(state: int) -> void:
	_energy_bar.tint_progress = BAR_TINTS[state]


## Dibuja la mejor herramienta/arma de cada tipo que hay en la mochila, con su durabilidad.
func _draw_equipment() -> void:
	var font := ThemeDB.fallback_font
	for k in EQUIP_SLOTS.size():
		var kind: StringName = EQUIP_SLOTS[k][0]
		var pos := Vector2(k * (EQUIP_CELL + 2), 0)
		_equip.draw_texture(SLOT, pos)
		var item := GameState.best_weapon() if kind == &"weapon" else GameState.best_tool(kind)
		if item == null:
			item = _broken_in_bag(kind)  # mostrarla en rojo para que se sepa que hay que repararla
		var cell := Rect2(pos + Vector2.ONE, Vector2(EQUIP_CELL - 2, EQUIP_CELL - 2))
		if item == null:
			_equip.draw_string(font, pos + Vector2(6, 13), EQUIP_SLOTS[k][1],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.3))
			continue
		var tex := item.data.icon.get_size()
		var s := tex * minf(cell.size.x / tex.x, cell.size.y / tex.y)
		_equip.draw_texture_rect(item.data.icon, Rect2(cell.position + (cell.size - s) / 2.0, s), false)
		var bar := Rect2(pos + Vector2(1, EQUIP_CELL + 1), Vector2(EQUIP_CELL - 2, 2))
		_equip.draw_rect(bar, Color(0, 0, 0, 0.6))
		if kind == &"light":
			# Linterna: la barra es el aceite que queda; borde amarillo si está prendida
			bar.size.x *= clampf(GameState.oil_minutes() / OIL_BAR_FULL, 0.0, 1.0)
			_equip.draw_rect(bar, Color(0.95, 0.8, 0.3) if GameState.lantern_on else Color(0.6, 0.6, 0.6))
			if GameState.lantern_on:
				_equip.draw_rect(Rect2(pos, Vector2(EQUIP_CELL, EQUIP_CELL)).grow(-0.5), Color(0.95, 0.8, 0.3), false, 1.0)
		else:
			bar.size.x *= item.durability_ratio()
			_equip.draw_rect(bar, item.condition_color())


func _broken_in_bag(kind: StringName) -> ItemInstance:
	for it in GameState.bag.items():
		if not it.is_broken:
			continue
		var is_weapon := it.data.item_type == ItemData.ItemType.WEAPON
		if (kind == &"weapon" and is_weapon) or (not is_weapon and it.data.tool_type == kind):
			return it
	return null


func _icon(tex: Texture2D) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return r


func set_hub() -> void:
	_in_hub = true
	_location.text = "Pueblo  ·  almacén: %d ítems" % GameState.storage.count()
	_minimap.visible = false


func _on_zone_entered(coord: Vector2i) -> void:
	_in_hub = false
	var z: ZoneData = ForestSession.zones[coord]
	var text := "Bosque (%d, %d) · prof. %d · presupuesto %d" % [coord.x, coord.y, z.depth, z.budget]
	if z.rarity > 0:
		text += " · hora: ×%.1f, rareza +%d" % [z.difficulty, z.rarity]
	_location.text = text
	_minimap.visible = true


func _refresh_carried() -> void:
	var bag := GameState.bag
	var weight := "%.1f/%.0f kg" % [GameState.carried_weight(), GameState.max_weight()]
	_carried.modulate = Color(1, 0.45, 0.4) if GameState.is_overweight() else Color.WHITE
	if bag.is_empty():
		_carried.text = "Mochila vacía"
		return
	var counts := {}
	for item in bag.items():
		counts[item.display_name()] = counts.get(item.display_name(), 0) + 1
	var parts: PackedStringArray = []
	for item_name: String in counts:
		parts.append("%s ×%d" % [item_name, counts[item_name]])
	_carried.text = "Mochila: %s · %s%s" % [", ".join(parts), weight,
		"  (sobrepeso)" if GameState.is_overweight() else ""]


func show_toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.4)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)
