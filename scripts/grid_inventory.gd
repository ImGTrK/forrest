class_name GridInventory
extends RefCounted
## Inventario en grilla: cada ítem ocupa grid_size celdas (port del diseño
## "Inventario del Jugador" de BarrenRoots: ItemInstance[,] grilla 6×4).
## Soporta ítems rotados, intercambio, ordenar y crecimiento automático (almacén).
## Lógica pura, sin UI: la UI escucha `changed`.

signal changed

var size: Vector2i
## Si es true, la grilla agrega filas cuando hace falta y mantiene siempre
## FREE_ROWS filas libres abajo (almacén "sin límite"). Son 2 para que siempre
## entre un ítem de 1x2 parado.
var auto_grow := false
const FREE_ROWS := 2
var _cells: Array = []  # size.x * size.y; ItemInstance o null
var _positions: Dictionary = {}  # ItemInstance -> Vector2i (esquina superior izquierda)
var _sizes: Dictionary = {}  # ItemInstance -> Vector2i (tamaño con el que se colocó)


func _init(p_size: Vector2i = Vector2i(6, 4), p_auto_grow: bool = false) -> void:
	size = p_size
	auto_grow = p_auto_grow
	_cells.resize(size.x * size.y)
	_cells.fill(null)


func items() -> Array[ItemInstance]:
	var out: Array[ItemInstance] = []
	for item: ItemInstance in _positions:
		out.append(item)
	return out


func count() -> int:
	return _positions.size()


func is_empty() -> bool:
	return _positions.is_empty()


func has(item: ItemInstance) -> bool:
	return _positions.has(item)


func position_of(item: ItemInstance) -> Vector2i:
	return _positions.get(item, Vector2i(-1, -1))


func item_at(cell: Vector2i) -> ItemInstance:
	if not _in_bounds(cell):
		return null
	return _cells[cell.y * size.x + cell.x]


func rect_in_bounds(pos: Vector2i, item_size: Vector2i) -> bool:
	return _in_bounds(pos) and _in_bounds(pos + item_size - Vector2i.ONE)


func can_place(item_size: Vector2i, pos: Vector2i) -> bool:
	return rect_in_bounds(pos, item_size) and items_in_rect(pos, item_size).is_empty()


## Ítems distintos que se superponen con el rectángulo (para intercambiar).
func items_in_rect(pos: Vector2i, item_size: Vector2i) -> Array[ItemInstance]:
	var out: Array[ItemInstance] = []
	for y in range(pos.y, pos.y + item_size.y):
		for x in range(pos.x, pos.x + item_size.x):
			var it := item_at(Vector2i(x, y))
			if it and not out.has(it):
				out.append(it)
	return out


## Primera posición libre recorriendo por filas. (-1,-1) si no hay lugar.
func find_space(item_size: Vector2i) -> Vector2i:
	for y in size.y - item_size.y + 1:
		for x in size.x - item_size.x + 1:
			if can_place(item_size, Vector2i(x, y)):
				return Vector2i(x, y)
	return Vector2i(-1, -1)


## ¿Entra en alguna orientación?
func has_space(item_size: Vector2i) -> bool:
	if auto_grow:
		return true
	return find_space(item_size).x >= 0 or find_space(Vector2i(item_size.y, item_size.x)).x >= 0


## Agrega donde haya lugar; si no entra derecho, prueba rotado.
func add(item: ItemInstance) -> bool:
	var pos := find_space(item.grid_size())
	if pos.x < 0 and item.can_rotate():
		item.rotated = not item.rotated
		pos = find_space(item.grid_size())
		if pos.x < 0:
			item.rotated = not item.rotated
	if pos.x < 0 and auto_grow:
		_grow(item.grid_size().y)
		pos = find_space(item.grid_size())
	return pos.x >= 0 and add_at(item, pos)


func add_at(item: ItemInstance, pos: Vector2i) -> bool:
	if _positions.has(item) or not can_place(item.grid_size(), pos):
		return false
	var s := item.grid_size()
	_set_cells(pos, s, item)
	_positions[item] = pos
	_sizes[item] = s
	_keep_free_row()
	changed.emit()
	return true


func remove(item: ItemInstance) -> bool:
	if not _positions.has(item):
		return false
	_set_cells(_positions[item], _sizes[item], null)
	_positions.erase(item)
	_sizes.erase(item)
	changed.emit()
	return true


func clear() -> void:
	_cells.fill(null)
	_positions.clear()
	_sizes.clear()
	changed.emit()


func total_weight() -> float:
	var total := 0.0
	for item: ItemInstance in _positions:
		total += item.weight()
	return total


## Reacomoda todo para compactar: primero lo más grande, después por tipo y calidad.
## Si por algún motivo no entra todo, deja la grilla como estaba y devuelve false.
func sort() -> bool:
	var snapshot := {}
	for item: ItemInstance in _positions:
		snapshot[item] = [_positions[item], item.rotated]
	var list := items()
	list.sort_custom(func(a: ItemInstance, b: ItemInstance) -> bool:
		var area_a := a.data.grid_size.x * a.data.grid_size.y
		var area_b := b.data.grid_size.x * b.data.grid_size.y
		if area_a != area_b:
			return area_a > area_b
		if a.data.id != b.data.id:
			return String(a.data.id) < String(b.data.id)
		return a.quality > b.quality)
	clear()
	for item in list:
		item.rotated = false
		if not add(item):
			clear()
			for it: ItemInstance in snapshot:
				it.rotated = snapshot[it][1]
				add_at(it, snapshot[it][0])
			return false
	return true


func _grow(rows: int) -> void:
	size.y += rows
	_cells.resize(size.x * size.y)  # las celdas nuevas quedan en null


func _keep_free_row() -> void:
	if not auto_grow:
		return
	var empty_rows := 0
	for y in range(size.y - 1, -1, -1):
		var row_empty := true
		for x in size.x:
			if _cells[y * size.x + x] != null:
				row_empty = false
				break
		if not row_empty:
			break
		empty_rows += 1
	if empty_rows < FREE_ROWS:
		_grow(FREE_ROWS - empty_rows)


func _set_cells(pos: Vector2i, s: Vector2i, value: ItemInstance) -> void:
	for y in range(pos.y, pos.y + s.y):
		for x in range(pos.x, pos.x + s.x):
			_cells[y * size.x + x] = value


func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y
