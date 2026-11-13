class_name InventoryGridView
extends Control
## Dibuja un GridInventory (mochila o almacén) y reporta hover y clics por celda.
## La lógica de agarrar/soltar vive en InventoryUI; esta vista solo muestra la
## vista previa del ítem agarrado (verde = entra, amarillo = intercambia, rojo = no entra).

signal cell_pressed(view: InventoryGridView, cell: Vector2i, button: int, shift: bool)
signal item_hovered(view: InventoryGridView, item: ItemInstance)  # item null al salir

## Celda = 16 px de ícono + 1 px de borde a cada lado.
const CELL := 18
const SLOT := preload("res://assets/sprites/ui/slot.png")  # 18x18

const PREVIEW_OK := Color(0.4, 0.9, 0.4, 0.35)
const PREVIEW_SWAP := Color(0.95, 0.8, 0.3, 0.35)
const PREVIEW_BAD := Color(0.95, 0.3, 0.3, 0.35)

var inventory: GridInventory
## Ítem que el jugador tiene agarrado (lo setea InventoryUI) para la vista previa.
var held: ItemInstance

var _hover_cell := Vector2i(-1, -1)
var _hover_item: ItemInstance


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func show_grid(inv: GridInventory) -> void:
	inventory = inv
	custom_minimum_size = Vector2(inv.size * CELL)
	if _hover_item and not inv.has(_hover_item):
		_set_hover_item(null)
	queue_redraw()


## Dónde quedaría la esquina del ítem agarrado si se suelta en `cell` (centrado en el mouse).
func anchor_for(cell: Vector2i, item_size: Vector2i) -> Vector2i:
	return cell - (item_size - Vector2i.ONE) / 2


func hovered_item() -> ItemInstance:
	return _hover_item


func _draw() -> void:
	if inventory == null:
		return
	for y in inventory.size.y:
		for x in inventory.size.x:
			draw_texture(SLOT, Vector2(x, y) * CELL)
	for item in inventory.items():
		var r := Rect2(Vector2(inventory.position_of(item) * CELL), Vector2(item.grid_size() * CELL))
		draw_item(self, item, r)
		if item == _hover_item and held == null:
			draw_rect(r.grow(-0.5), Color.WHITE, false, 1.0)
	if held and _hover_cell.x >= 0:
		var s := held.grid_size()
		var anchor := anchor_for(_hover_cell, s)
		var color := PREVIEW_BAD
		if inventory.rect_in_bounds(anchor, s):
			match inventory.items_in_rect(anchor, s).size():
				0: color = PREVIEW_OK
				1: color = PREVIEW_SWAP
		draw_rect(Rect2(Vector2(anchor * CELL), Vector2(s * CELL)), color)


## Dibuja un ítem en `rect` (incluye rotación y marca de calidad). Lo usa también
## el cursor del ítem agarrado.
static func draw_item(ci: CanvasItem, item: ItemInstance, rect: Rect2) -> void:
	var inner := rect.grow(-1)
	var icon := item.data.icon
	if icon == null:
		ci.draw_rect(inner, item.data.color)
	elif item.rotated:
		# El ícono está dibujado en la orientación original: se rota 90° alrededor del centro
		ci.draw_set_transform(inner.get_center(), PI / 2.0)
		var unrotated := Vector2(inner.size.y, inner.size.x)
		ci.draw_texture_rect(icon, Rect2(-unrotated / 2.0, unrotated), false)
		ci.draw_set_transform(Vector2.ZERO)
	else:
		ci.draw_texture_rect(icon, inner, false)
	var q := quality_color(item.quality)
	if q.a > 0.0:
		ci.draw_rect(Rect2(rect.end - Vector2(4, 4), Vector2(3, 3)), q)


static func quality_color(q: int) -> Color:
	if q >= 80:
		return Color("f2c94c")  # dorado
	if q >= 55:
		return Color("8fd16a")  # verde
	return Color(0, 0, 0, 0)


func _gui_input(event: InputEvent) -> void:
	if inventory == null:
		return
	if event is InputEventMouseMotion:
		var cell := Vector2i((event.position / CELL).floor())
		if cell != _hover_cell:
			_hover_cell = cell
			queue_redraw()
		_set_hover_item(inventory.item_at(cell))
	elif event is InputEventMouseButton and event.pressed \
			and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		var cell := Vector2i((event.position / CELL).floor())
		cell_pressed.emit(self, cell, event.button_index, event.shift_pressed)
		accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hover_cell = Vector2i(-1, -1)
		_set_hover_item(null)
		queue_redraw()


func _set_hover_item(item: ItemInstance) -> void:
	if item == _hover_item:
		return
	_hover_item = item
	item_hovered.emit(self, item)
	queue_redraw()
