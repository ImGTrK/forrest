class_name ItemChip
extends Control
## Un ítem clickeable de una celda (para elegir materiales en la mesa).
## El ícono se achica a la celda manteniendo proporción; seleccionado = borde dorado.

signal pressed(chip: ItemChip)
signal hovered(item: ItemInstance)  # null al salir

const CELL := InventoryGridView.CELL
const SLOT := preload("res://assets/sprites/ui/slot.png")

var item: ItemInstance
var selected := false:
	set(v):
		selected = v
		queue_redraw()


func _init(p_item: ItemInstance = null) -> void:
	item = p_item
	custom_minimum_size = Vector2(CELL, CELL)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func() -> void: hovered.emit(item))
	mouse_exited.connect(func() -> void: hovered.emit(null))


func _draw() -> void:
	draw_texture(SLOT, Vector2.ZERO)
	if item == null:
		return
	var inner := Rect2(Vector2.ONE, Vector2(CELL - 2, CELL - 2))
	var icon := item.data.icon
	if icon:
		var tex := icon.get_size()
		var k := minf(inner.size.x / tex.x, inner.size.y / tex.y)
		var s := tex * k
		draw_texture_rect(icon, Rect2(inner.position + (inner.size - s) / 2.0, s), false)
	var q := InventoryGridView.quality_color(item.quality)
	if q.a > 0.0:
		draw_rect(Rect2(Vector2(CELL - 4, CELL - 4), Vector2(3, 3)), q)
	InventoryGridView.draw_trait_mark(self, item, Rect2(Vector2.ZERO, Vector2(CELL, CELL)))
	if selected:
		draw_rect(Rect2(Vector2.ZERO, Vector2(CELL, CELL)).grow(-0.5), Color("f2c94c"), false, 1.0)
	else:
		draw_rect(Rect2(Vector2.ZERO, Vector2(CELL, CELL)), Color(0, 0, 0, 0.35))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(self)
		accept_event()
