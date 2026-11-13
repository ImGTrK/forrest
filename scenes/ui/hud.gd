class_name GameHUD
extends CanvasLayer
## HUD: ubicación, resumen de lo cargado, mensajes y minimapa.
## CanvasLayer ≈ un Canvas de Unity en Screen Space Overlay.

var _location: Label
var _carried: Label
var _toast: Label
var _hint: Label
var _minimap: Minimap
var _toast_tween: Tween


func _ready() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(8, 6)
	add_child(box)
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
	_hint.text = "WASD mover · E interactuar · Tab inventario"
	add_child(_hint)

	GameState.run_inventory_changed.connect(_refresh_carried)
	GameState.message.connect(show_toast)
	ForestSession.zone_entered.connect(_on_zone_entered)
	_refresh_carried()


func set_hub() -> void:
	_location.text = "Pueblo  ·  almacén: %d ítems" % GameState.storage.size()
	_minimap.visible = false


func _on_zone_entered(coord: Vector2i) -> void:
	var z: ZoneData = ForestSession.zones[coord]
	_location.text = "Bosque (%d, %d)  ·  profundidad %d  ·  presupuesto %d" % [
		coord.x, coord.y, z.depth, z.budget]
	_minimap.visible = true


func _refresh_carried() -> void:
	if GameState.run_inventory.is_empty():
		_carried.text = "Cargando: nada"
		return
	var counts := {}
	for item in GameState.run_inventory:
		counts[item.name] = counts.get(item.name, 0) + 1
	var parts: PackedStringArray = []
	for item_name: String in counts:
		parts.append("%s ×%d" % [item_name, counts[item_name]])
	_carried.text = "Cargando: " + ", ".join(parts)


func show_toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.4)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)
