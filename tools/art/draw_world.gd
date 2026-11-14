extends SceneTree
## Arte del mundo para la 0.2, dibujado por código con la paleta Forrest.
## Dirección: bosque primaveral de inspiración japonesa — salvia y jade, caminos crema,
## flores rosa claro frecuentes, bermellón solo en acentos chicos. Sombras ciruela, contornos
## oscuros de 1 px, luz desde arriba a la izquierda. Siluetas legibles en 16×16.
##
## Uso:   godot --headless --path . --script res://tools/art/draw_world.gd [-- solo=terrain,trees]
## Pisa los PNG que genera (lista en OUTPUTS). Lo editado a mano conviene versionarlo antes.

const PC := preload("res://tools/art/pixel_canvas.gd")
const T := 16
const OUT := "res://assets/"


func _init() -> void:
	var only := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("solo="):
			only = a.trim_prefix("solo=").split(",")
	var jobs := {
		"terrain": _terrain,
		"trees": _trees,
		"rocks": _rocks,
		"bushes": _bushes,
		"deco": _deco,
		"events": _events,
	}
	for k: String in jobs:
		if only.is_empty() or only.has(k):
			jobs[k].call()
			print("ok ", k)
	quit()


func _save(c: RefCounted, rel: String) -> void:
	c.save(ProjectSettings.globalize_path(OUT + rel))


# =====================================================================================
# TERRENO — assets/tilesets/terrain.png (256×128, 16×8 tiles; orden en GUIA §2.1)
# Base tranquila + variantes con detalle (el generador las mezcla con probabilidad) +
# juegos de transición tipo "isla" (esquinas externas e internas) para unir terrenos.
# =====================================================================================

## Posición de cada pieza dentro de un juego de transición de 5×3 tiles.
## o = esquina externa (el terreno está adentro), i = esquina interna (pasto solo en ese rincón).
const SET_LAYOUT := {
	Vector2i(0, 0): "otl", Vector2i(1, 0): "t", Vector2i(2, 0): "otr", Vector2i(3, 0): "itl", Vector2i(4, 0): "itr",
	Vector2i(0, 1): "l", Vector2i(1, 1): "c", Vector2i(2, 1): "r", Vector2i(3, 1): "ibl", Vector2i(4, 1): "ibr",
	Vector2i(0, 2): "obl", Vector2i(1, 2): "b", Vector2i(2, 2): "obr",
}


func _terrain() -> void:
	var c: RefCounted = PC.new(256, 128, 7)
	# --- Fila 0: bases (las 4 primeras no cambian de lugar: el juego actual las usa) ---
	_grass_calm(c, 0, 0, 10)
	_hedge(c, 1, 0, 21, false)
	_floor(c, 2, 0, 31, false)
	_path_calm(c, 3, 0)
	_dirt(c, 4, 0, 51, false)
	_dark_grass(c, 5, 0, 61, false)
	_water_fill(c, 6, 0, false)
	_ruin(c, 7, 0, 71, 0)
	# Variantes con detalle (para mezclar con poca probabilidad)
	_grass(c, 8, 0, 12, 0)
	_grass(c, 9, 0, 13, 1)
	_grass(c, 10, 0, 14, 2)
	_grass(c, 11, 0, 15, 3)
	_path(c, 12, 0, 42, true)
	_dirt(c, 13, 0, 52, true)
	_floor(c, 14, 0, 32, true)
	_dark_grass(c, 15, 0, 62, true)
	# --- Fila 1: más variantes ---
	_hedge(c, 0, 1, 22, true)
	_hedge(c, 1, 1, 23, false)
	_water_fill(c, 2, 1, true)
	_ruin(c, 3, 1, 72, 1)
	_ruin(c, 4, 1, 73, 2)
	_grass_calm(c, 5, 1, 16)
	_path(c, 6, 1, 41, false)
	# --- Filas 2-4 y 5-7: juegos de transición sobre pasto ---
	_tset(c, 0, 2, _fill_of(func(k: RefCounted) -> void: _path_calm(k, 0, 0)), "soft_path")
	_tset(c, 5, 2, _fill_of(func(k: RefCounted) -> void: _dirt(k, 0, 0, 51, false)), "soft_dirt")
	_tset(c, 10, 2, _fill_of(func(k: RefCounted) -> void: _water_fill(k, 0, 0, false)), "water")
	_tset(c, 0, 5, _fill_of(func(k: RefCounted) -> void: _dark_grass(k, 0, 0, 61, false)), "dither")
	_tset(c, 5, 5, _fill_of(func(k: RefCounted) -> void: _hedge(k, 0, 0, 21, false)), "hedge")
	_tset(c, 10, 5, _fill_of(func(k: RefCounted) -> void: _ruin(k, 0, 0, 71, 0)), "ruin")
	_save(c, "tilesets/terrain.png")


## Pinta un tile en un lienzo de 16×16 y devuelve la imagen (relleno sin costuras).
func _fill_of(painter: Callable) -> Image:
	var k: RefCounted = PC.new(16, 16, 1)
	painter.call(k)
	return k.img


## Ruido de borde periódico (se repite cada 16 px): bordes orgánicos que igual empalman.
func _jit(t: int) -> int:
	var a := TAU * posmod(t, 16) / 16.0
	return roundi(sin(a) * 1.1 + sin(a * 2.0 + 1.3) * 0.8)


## ¿El píxel (x, y) de la pieza `kind` es terreno (true) o pasto (false)?
func _fg(kind: String, x: int, y: int) -> bool:
	var top := y >= 5 + _jit(x)
	var bottom := y <= 10 - _jit(x + 3)
	var left := x >= 5 + _jit(y + 5)
	var right := x <= 10 - _jit(y + 9)
	var p := Vector2(x + 0.5, y + 0.5)
	match kind:
		"c": return true
		"t": return top
		"b": return bottom
		"l": return left
		"r": return right
		"otl": return top and left and (x >= 9 or y >= 9 or p.distance_to(Vector2(9, 9)) <= 4.4)
		"otr": return top and right and (x <= 6 or y >= 9 or p.distance_to(Vector2(7, 9)) <= 4.4)
		"obl": return bottom and left and (x >= 9 or y <= 6 or p.distance_to(Vector2(9, 7)) <= 4.4)
		"obr": return bottom and right and (x <= 6 or y <= 6 or p.distance_to(Vector2(7, 7)) <= 4.4)
		"itl": return not (not left and not top and p.distance_to(Vector2(0, 0)) <= 6.2)
		"itr": return not (not right and not top and p.distance_to(Vector2(16, 0)) <= 6.2)
		"ibl": return not (not left and not bottom and p.distance_to(Vector2(0, 16)) <= 6.2)
		"ibr": return not (not right and not bottom and p.distance_to(Vector2(16, 16)) <= 6.2)
	return false


## Un juego de transición (5×3 tiles en sx, sy): pasto tranquilo afuera, `fill` adentro,
## y un estilo de borde según el material.
func _tset(c: RefCounted, sx: int, sy: int, fill: Image, style: String) -> void:
	var grass := _fill_of(func(k: RefCounted) -> void: _grass_calm(k, 0, 0, 10))
	for cell: Vector2i in SET_LAYOUT:
		var kind: String = SET_LAYOUT[cell]
		var tx := sx + cell.x
		var ty := sy + cell.y
		var is_fg := func(x: int, y: int) -> bool:
			# fuera del tile se asume que el borde sigue igual (para decidir los bordes)
			return _fg(kind, clampi(x, 0, 15), clampi(y, 0, 15)) if (x < 0 or y < 0 or x > 15 or y > 15) else _fg(kind, x, y)
		for y in 16:
			for x in 16:
				_tp(c, tx, ty, x, y, fill.get_pixel(x, y) if is_fg.call(x, y) else grass.get_pixel(x, y))
		for y in 16:
			for x in 16:
				var f: bool = is_fg.call(x, y)
				var up: bool = is_fg.call(x, y - 1)
				var down: bool = is_fg.call(x, y + 1)
				var lf: bool = is_fg.call(x - 1, y)
				var rt: bool = is_fg.call(x + 1, y)
				_edge(c, tx, ty, x, y, style, f, up, down, lf, rt)


## Estilo del borde entre pasto (bg) y terreno (fg). La luz viene de arriba-izquierda: el pasto
## está "un escalón arriba" de caminos y tierra, y el agua está más abajo que la orilla.
func _edge(c: RefCounted, tx: int, ty: int, x: int, y: int, style: String,
		f: bool, up: bool, down: bool, lf: bool, rt: bool) -> void:
	var odd := posmod(x + y, 2) == 0
	match style:
		"soft_path", "soft_dirt":
			var shadow := "sand" if style == "soft_path" else "path"
			if f and (not up or not lf):
				_tp(c, tx, ty, x, y, shadow)  # sombra del pasto sobre el camino
			elif not f and (down or rt):
				_tp(c, tx, ty, x, y, "grass_dark")  # borde de abajo/derecha del pasto
			elif not f and (up or lf):
				_tp(c, tx, ty, x, y, "grass_light" if odd else "grass")
		"water":
			if f and not up:
				_tp(c, tx, ty, x, y, "brown")  # barranca de tierra bajo la orilla de arriba
			elif f and not lf:
				_tp(c, tx, ty, x, y, "water_deep")
			elif f and (not down or not rt):
				_tp(c, tx, ty, x, y, "foam")
			elif not f and (down or rt or up or lf):
				_tp(c, tx, ty, x, y, "jade_deep")
		"dither":
			if f and (not up or not down or not lf or not rt) and odd:
				_tp(c, tx, ty, x, y, "grass")
		"hedge":
			if f and (not down or not rt):
				_tp(c, tx, ty, x, y, "plum")  # contorno abajo-derecha del cerco
			elif f and (not up or not lf):
				_tp(c, tx, ty, x, y, "leaf_sun")
			elif not f and up:
				_tp(c, tx, ty, x, y, "grass_dark")  # sombra proyectada sobre el pasto
		"ruin":
			if f and (not up or not lf or not down or not rt):
				_tp(c, tx, ty, x, y, "moss" if odd else "stone_dark")


## Pasto tranquilo: un solo tono con dos marcas casi invisibles. Es el que más se repite.
func _grass_calm(c: RefCounted, tx: int, ty: int, seed_value: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	_tfill(c, tx, ty, "grass")
	var soft := PC.col("grass").lerp(PC.col("grass_light"), 0.22)
	var deep := PC.col("grass").lerp(PC.col("grass_dark"), 0.25)
	var x := r.randi_range(2, 12)
	var y := r.randi_range(2, 12)
	_tp(c, tx, ty, x, y, soft)
	_tp(c, tx, ty, x + 1, y + 1, deep)
	_tp(c, tx, ty, x + 6, y + 5, soft)


## Camino tranquilo: crema casi liso.
func _path_calm(c: RefCounted, tx: int, ty: int) -> void:
	_tfill(c, tx, ty, "cream")
	_tp(c, tx, ty, 4, 6, PC.col("cream").lerp(PC.col("sand"), 0.5))
	_tp(c, tx, ty, 11, 12, PC.col("cream").lerp(PC.col("sand"), 0.5))
	_tp(c, tx, ty, 12, 3, "ivory")


## Agua de estanque (relleno). sparkle = con un brillo extra (variante).
func _water_fill(c: RefCounted, tx: int, ty: int, sparkle: bool) -> void:
	_tfill(c, tx, ty, "water")
	for p in [Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5)]:
		_tp(c, tx, ty, p.x, p.y, "water_light")
	_tp(c, tx, ty, 11, 11, PC.col("water").lerp(PC.col("water_light"), 0.5))
	_tp(c, tx, ty, 12, 11, PC.col("water").lerp(PC.col("water_light"), 0.5))
	if sparkle:
		_tp(c, tx, ty, 6, 5, "foam")
		_tp(c, tx, ty, 10, 10, "foam")
		_tp(c, tx, ty, 9, 13, "water_deep")
		_tp(c, tx, ty, 10, 13, "water_deep")


## Escribe en el tile (tx, ty) con coordenadas locales que dan la vuelta (tile sin costuras).
func _tp(c: RefCounted, tx: int, ty: int, x: int, y: int, col: Variant) -> void:
	c.px(tx * T + posmod(x, T), ty * T + posmod(y, T), col)


func _tget(c: RefCounted, tx: int, ty: int, x: int, y: int) -> Color:
	return c.get_px(tx * T + posmod(x, T), ty * T + posmod(y, T))


func _tfill(c: RefCounted, tx: int, ty: int, col: Variant) -> void:
	c.rect(tx * T, ty * T, T, T, col)


## Matita de pasto: punta clara arriba, base oscura (2-3 px). Se lee como textura, no como ruido.
func _tuft(c: RefCounted, tx: int, ty: int, x: int, y: int, light: Variant, dark: Variant) -> void:
	_tp(c, tx, ty, x, y, light)
	_tp(c, tx, ty, x, y + 1, dark)
	_tp(c, tx, ty, x + 1, y + 1, dark)


## Pasto. extra: 0 nada · 1 pétalo caído · 2 florcitas · 3 piedritas
func _grass(c: RefCounted, tx: int, ty: int, seed_value: int, extra: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	_tfill(c, tx, ty, "grass")
	# Variación de tono muy suave en manchones de 3-4 px (no ruido de 1 px)
	for i in 3:
		var x := r.randi_range(0, 15)
		var y := r.randi_range(0, 15)
		for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]:
			_tp(c, tx, ty, x + d.x, y + d.y, PC.col("grass").lerp(PC.col("grass_light"), 0.18))
	# 3-4 matitas por tile
	var spots := [Vector2i(2, 3), Vector2i(10, 6), Vector2i(5, 11), Vector2i(13, 13)]
	for i in spots.size():
		var s: Vector2i = spots[i] + Vector2i(r.randi_range(-1, 1), r.randi_range(-1, 1))
		if i == 3 and r.randf() < 0.5:
			continue
		_tuft(c, tx, ty, s.x, s.y, "grass_light", "grass_dark")
	match extra:
		1:  # pétalos de cerezo caídos
			_tp(c, tx, ty, 6, 7, "blush")
			_tp(c, tx, ty, 7, 7, "flower_light")
			_tp(c, tx, ty, 12, 2, "blush")
		2:  # florcitas silvestres
			_blossom_t(c, tx, ty, 4, 6, "flower_pink", "gold_light")
			_blossom_t(c, tx, ty, 11, 11, "cream", "gold")
			_tp(c, tx, ty, 13, 4, "blush")
		3:  # piedritas
			_pebble(c, tx, ty, 5, 8)
			_pebble(c, tx, ty, 12, 3)
			_tp(c, tx, ty, 9, 13, "stone")


func _blossom_t(c: RefCounted, tx: int, ty: int, x: int, y: int, petal: Variant, center: Variant) -> void:
	for d in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]:
		_tp(c, tx, ty, x + d.x, y + d.y, petal)
	_tp(c, tx, ty, x, y, center)
	_tp(c, tx, ty, x + 1, y + 1, "grass_dark")  # sombrita abajo-derecha


func _pebble(c: RefCounted, tx: int, ty: int, x: int, y: int) -> void:
	_tp(c, tx, ty, x, y, "stone_light")
	_tp(c, tx, ty, x + 1, y, "stone")
	_tp(c, tx, ty, x, y + 1, "stone")
	_tp(c, tx, ty, x + 1, y + 1, "stone_dark")
	_tp(c, tx, ty, x + 2, y + 1, "grass_dark")


## Pasto oscuro bajo las arboledas: misma lógica, tonos de sombra y algo de musgo.
func _dark_grass(c: RefCounted, tx: int, ty: int, seed_value: int, petals: bool) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	_tfill(c, tx, ty, "grass_dark")
	for i in 3:
		var x := r.randi_range(0, 15)
		var y := r.randi_range(0, 15)
		for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			_tp(c, tx, ty, x + d.x, y + d.y, PC.col("grass_dark").lerp(PC.col("leaf_dark"), 0.35))
	for s in [Vector2i(3, 2), Vector2i(11, 5), Vector2i(6, 10), Vector2i(13, 12)]:
		var p: Vector2i = s + Vector2i(r.randi_range(-1, 1), r.randi_range(-1, 1))
		_tuft(c, tx, ty, p.x, p.y, "moss", "leaf_dark")
	if petals:
		_tp(c, tx, ty, 8, 7, "rose")
		_tp(c, tx, ty, 2, 13, "blush")


## Cerco de follaje tupido (el borde que no se cruza). Escamas de hojas en tresbolillo.
func _hedge(c: RefCounted, tx: int, ty: int, seed_value: int, blossoms: bool) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	_tfill(c, tx, ty, "jade_deep")
	# Centros de las matas: dos filas desfasadas que dan la vuelta (sin costura)
	var centers := [Vector2i(4, 3), Vector2i(12, 3), Vector2i(0, 11), Vector2i(8, 11), Vector2i(16, 11)]
	if seed_value % 2 == 1:
		centers = [Vector2i(0, 3), Vector2i(8, 3), Vector2i(16, 3), Vector2i(4, 11), Vector2i(12, 11)]
	for ctr: Vector2i in centers:
		for oy in [-16, 0, 16]:
			for ox in [-16, 0, 16]:
				_leaf_clump(c, tx, ty, ctr + Vector2i(ox, oy))
	# brillos sueltos
	for i in 3:
		_tp(c, tx, ty, r.randi_range(0, 15), r.randi_range(0, 15), "leaf_light")
	if blossoms:
		_blossom_t(c, tx, ty, 5, 4, "flower_pink", "flower_light")
		_blossom_t(c, tx, ty, 12, 11, "blush", "flower_light")


## Mata redonda de radio ~4.5: borde inferior-derecho jade_deep, cuerpo leaf, brillo arriba-izq.
func _leaf_clump(c: RefCounted, tx: int, ty: int, ctr: Vector2i) -> void:
	for y in range(-5, 6):
		for x in range(-5, 6):
			var d := Vector2(x + 0.5, y + 0.5).length()
			var gx := ctr.x + x
			var gy := ctr.y + y
			if gx < 0 or gy < 0 or gx > 15 or gy > 15:
				continue
			if d <= 4.6:
				var col: Variant = "leaf"
				if x + y >= 4 and d > 3.0:
					col = "leaf_dark"
				elif x + y <= -3 and d > 2.6:
					col = "leaf_light"
				elif x + y <= -5:
					col = "leaf_sun"
				_tp(c, tx, ty, gx, gy, col)
			elif d <= 5.4 and x + y >= 0:
				_tp(c, tx, ty, gx, gy, "jade_deep")


## Piso del pueblo: baldosas crema en junta trabada, borde claro arriba.
func _floor(c: RefCounted, tx: int, ty: int, seed_value: int, variant: bool) -> void:
	_tfill(c, tx, ty, "sand")
	# juntas
	for x in 16:
		_tp(c, tx, ty, x, 7, "path")
		_tp(c, tx, ty, x, 15, "path")
	for y in range(0, 7):
		_tp(c, tx, ty, 7, y, "path")
	for y in range(8, 15):
		_tp(c, tx, ty, 15, y, "path")
	# luz arriba-izquierda de cada baldosa
	for x in 16:
		if x != 7:
			_tp(c, tx, ty, x, 0, "cream")
		if x != 15:
			_tp(c, tx, ty, x, 8, "cream")
	for y in range(1, 7):
		_tp(c, tx, ty, 8, y, "cream")
		_tp(c, tx, ty, 0, y, "cream")
	for y in range(9, 15):
		_tp(c, tx, ty, 0, y, "cream")
	# sombra abajo de cada baldosa
	for x in range(0, 16):
		if x != 7 and x != 0 and x != 8:
			_tp(c, tx, ty, x, 6, PC.col("sand").lerp(PC.col("path"), 0.4))
		if x != 15 and x != 0:
			_tp(c, tx, ty, x, 14, PC.col("sand").lerp(PC.col("path"), 0.4))
	if variant:
		# grieta + pétalo
		_tp(c, tx, ty, 3, 10, "path")
		_tp(c, tx, ty, 4, 11, "path")
		_tp(c, tx, ty, 4, 12, "path_shadow")
		_tp(c, tx, ty, 11, 3, "blush")
		_tp(c, tx, ty, 12, 3, "flower_light")
	else:
		_tp(c, tx, ty, 12, 11, "cream")
		_tp(c, tx, ty, 3, 3, PC.col("sand").lerp(PC.col("cream"), 0.5))


## Camino de tierra clara (crema), sin bordes: une en las 4 direcciones.
func _path(c: RefCounted, tx: int, ty: int, seed_value: int, variant: bool) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	_tfill(c, tx, ty, "cream")
	for i in 5:
		var x := r.randi_range(0, 15)
		var y := r.randi_range(0, 15)
		_tp(c, tx, ty, x, y, "sand")
		_tp(c, tx, ty, x + 1, y, "sand")
	for i in 3:
		var x := r.randi_range(0, 15)
		var y := r.randi_range(0, 15)
		_tp(c, tx, ty, x, y, "ivory")
	_tp(c, tx, ty, r.randi_range(0, 15), r.randi_range(0, 15), "path")
	if variant:
		# piedrita y huellita de pétalo
		_tp(c, tx, ty, 4, 9, "path")
		_tp(c, tx, ty, 5, 9, "path_shadow")
		_tp(c, tx, ty, 4, 8, "sand")
		_tp(c, tx, ty, 11, 4, "blush")


## Tierra de claro: más cálida que el camino, con piedritas.
func _dirt(c: RefCounted, tx: int, ty: int, seed_value: int, variant: bool) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	_tfill(c, tx, ty, "sand")
	for i in 4:
		var x := r.randi_range(0, 15)
		var y := r.randi_range(0, 15)
		for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 0)]:
			_tp(c, tx, ty, x + d.x, y + d.y, "path")
	for i in 3:
		var x := r.randi_range(0, 15)
		var y := r.randi_range(0, 15)
		_tp(c, tx, ty, x, y, "path_shadow")
		_tp(c, tx, ty, x - 1, y - 1, "cream")
	if variant:
		_tuft(c, tx, ty, 3, 4, "grass_light", "grass")
		_tuft(c, tx, ty, 12, 11, "grass_light", "grass")
		_tp(c, tx, ty, 9, 6, "blush")


## Losas de piedra antiguas, irregulares y gastadas. variant: 0 entera · 1 rota · 2 con musgo
func _ruin(c: RefCounted, tx: int, ty: int, seed_value: int, variant: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	var joint := PC.col("stone").lerp(PC.col("stone_dark"), 0.6)
	var face := PC.col("stone").lerp(PC.col("sand"), 0.12)
	_tfill(c, tx, ty, face)
	# Losas: una ancha arriba y dos desparejas abajo (junta trabada, distinta por variante)
	var split: int = [9, 6, 11][variant]
	var slabs := [Rect2i(0, 0, 16, 7), Rect2i(0, 7, split, 9), Rect2i(split, 7, 16 - split, 9)]
	for sl: Rect2i in slabs:
		for x in range(sl.position.x, sl.end.x):
			_tp(c, tx, ty, x, sl.position.y, "stone_light")
			_tp(c, tx, ty, x, sl.end.y - 1, joint)
		for y in range(sl.position.y, sl.end.y):
			_tp(c, tx, ty, sl.position.x, y, "stone_light")
			_tp(c, tx, ty, sl.end.x - 1, y, joint)
		_tp(c, tx, ty, sl.position.x, sl.end.y - 1, face)
		_tp(c, tx, ty, sl.end.x - 1, sl.position.y, face)
		# desgaste
		for i in 2:
			_tp(c, tx, ty, r.randi_range(sl.position.x + 2, sl.end.x - 3), r.randi_range(sl.position.y + 2, sl.end.y - 3), "stone")
	# pasto en las juntas
	_tp(c, tx, ty, split - 1, 12, "grass")
	_tp(c, tx, ty, 6, 6, "grass_dark")
	_tp(c, tx, ty, 15, 3, "grass")
	match variant:
		1:  # esquina partida: se ve la tierra con pasto
			for y in range(10, 16):
				for x in range(10, 16):
					if (x - 10) + (y - 10) > 4:
						_tp(c, tx, ty, x, y, "path")
			for i in 6:
				_tp(c, tx, ty, 15 - i, 10 + i, joint)
			_tp(c, tx, ty, 14, 13, "path_shadow")
			_tuft(c, tx, ty, 13, 13, "grass_light", "grass")
			_tp(c, tx, ty, 4, 3, joint)
			_tp(c, tx, ty, 5, 4, joint)
		2:  # musgo desde las juntas
			for p in [Vector2i(split - 2, 8), Vector2i(split - 1, 9), Vector2i(split, 9), Vector2i(split - 1, 10), Vector2i(split, 11),
					Vector2i(1, 14), Vector2i(2, 14), Vector2i(1, 13), Vector2i(13, 1), Vector2i(14, 1), Vector2i(14, 2)]:
				_tp(c, tx, ty, p.x, p.y, "moss")
			for p in [Vector2i(split - 1, 9), Vector2i(1, 13), Vector2i(13, 1)]:
				_tp(c, tx, ty, p.x, p.y, "leaf_light")
			_tp(c, tx, ty, 4, 3, "blush")


# =====================================================================================
# ÁRBOLES, ROCAS Y ARBUSTOS — tiras de variantes (el código elige una por entidad)
# =====================================================================================

## Copa de follaje hecha de "matas" (bolitas) superpuestas. Cada mata se ilumina sola
## (clara arriba-izquierda, oscura abajo-derecha) y se dibujan de arriba hacia abajo: el borde
## oscuro de cada una queda visible donde la de abajo no la tapa → grupos de hojas con volumen.
## Las de abajo usan un escalón más oscuro (la copa se sombrea a sí misma).
func _crown(puffs: Array, w: int, h: int, seed_value: int,
		pal := ["leaf_sun", "leaf_light", "leaf", "leaf_dark", "jade_deep"]) -> RefCounted:
	var k: RefCounted = PC.new(w, h, seed_value)
	var top := 999.0
	var bottom := -999.0
	for p: Vector3 in puffs:
		top = minf(top, p.y - p.z)
		bottom = maxf(bottom, p.y + p.z)
	var sorted := puffs.duplicate()
	sorted.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	for p: Vector3 in sorted:
		var t := clampf((p.y - top) / maxf(bottom - top, 1.0), 0.0, 1.0)
		var shift := 1 if t > 0.62 else 0  # matas de abajo: un tono más oscuro
		for y in range(floori(p.y - p.z) - 1, ceili(p.y + p.z) + 1):
			for x in range(floori(p.x - p.z) - 1, ceili(p.x + p.z) + 1):
				var v := Vector2(x + 0.5 - p.x, y + 0.5 - p.y)
				var d := v.length()
				if d > p.z:
					continue
				var diag := (v.x + v.y) / p.z  # -1.4 arriba-izq ... +1.4 abajo-der
				var idx := 2
				if d > p.z - 1.0 and diag > 0.2:
					idx = 4  # borde de separación
				elif diag > 0.45:
					idx = 3
				elif diag < -0.85 and d > p.z - 1.4:
					idx = 0
				elif diag < -0.45:
					idx = 1
				idx = mini(idx + shift, 4)
				k.px(x, y, pal[idx])
	# Hojitas sueltas en el borde superior para que la silueta no sea un círculo perfecto
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	for x in w:
		for y in h:
			if k.solid(x, y) and not k.solid(x, y - 1) and r.randf() < 0.07 and y > 0:
				k.px(x, y - 1, pal[1])
	k.outline("plum")
	return k


## Matas distribuidas dentro de una elipse (para no escribirlas a mano).
func _puffs_in(cx: float, cy: float, rx: float, ry: float, pr: float, seed_value: int, step := 0.0) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	var out := []
	var s := step if step > 0.0 else pr * 1.15
	var y := cy - ry + pr * 0.8
	var row := 0
	while y <= cy + ry - pr * 0.5:
		var x := cx - rx + pr * 0.8 + (s * 0.5 if row % 2 == 1 else 0.0)
		while x <= cx + rx - pr * 0.6:
			var dx := (x - cx) / rx
			var dy := (y - cy) / ry
			if dx * dx + dy * dy <= 0.6:
				out.append(Vector3(x + r.randf_range(-0.7, 0.7), y + r.randf_range(-0.6, 0.6), pr + r.randf_range(-0.5, 0.6)))
			x += s
		y += s * 0.82
		row += 1
	# Borde festoneado: matas un poco más grandes repartidas sobre el contorno
	var n := maxi(6, int(TAU * (rx + ry) * 0.5 / (pr * 1.25)))
	for i in n:
		var ang := TAU * i / n + r.randf_range(-0.12, 0.12)
		out.append(Vector3(cx + cos(ang) * (rx - pr * 0.9), cy + sin(ang) * (ry - pr * 0.9), pr * 1.05 + r.randf_range(-0.3, 0.4)))
	return out


func _trunk(w: int, h: int, x0: int, y0: int, tw: int, y1: int) -> RefCounted:
	var k: RefCounted = PC.new(w, h, 3)
	k.poly(PackedVector2Array([Vector2(x0, y0), Vector2(x0 + tw, y0), Vector2(x0 + tw + 1, y1 - 2),
		Vector2(x0 + tw + 3, y1), Vector2(x0 - 3, y1), Vector2(x0 - 1, y1 - 2)]), "bark")
	k.shade("wood_light", "bark", "brown", "brown_dark")
	# vetas y sombra de la copa sobre el tronco
	for y in range(y0 + 4, y1 - 3):
		if y % 4 != 0:
			k.px(x0 + tw - 2, y, "brown")
	for x in range(x0 - 1, x0 + tw + 2):
		for y in range(y0, y0 + 3):
			if k.solid(x, y):
				k.px(x, y, "brown" if y > y0 else "brown_dark")
	k.outline("brown_dark")
	return k


func _tree(variant: int) -> RefCounted:
	var c: RefCounted = PC.new(32, 32, 100 + variant)
	c.ground_shadow(16, 29.5, 11.5, 2.6)
	var trunk := _trunk(32, 32, 14, 18, 4, 31)
	var crown: RefCounted
	match variant:
		0:  # copa redonda de cerezo
			crown = _crown(_puffs_in(16, 12, 13.5, 11, 4.3, 41), 32, 32, 11)
		1:  # copa alta y ovalada (ciprés)
			trunk = _trunk(32, 32, 14, 22, 4, 31)
			crown = _crown(_puffs_in(16, 12.5, 8.5, 12, 3.7, 51), 32, 32, 12, ["leaf_light", "jade_bright", "leaf", "leaf_dark", "jade_deep"])
		2:  # copa ancha y baja con frutos (níspero)
			crown = _crown(_puffs_in(16, 13, 15, 10, 4.2, 61), 32, 32, 13)
	c.stamp(trunk)
	c.stamp(crown)
	match variant:
		0:
			for p in [Vector2i(8, 6), Vector2i(17, 4), Vector2i(23, 8), Vector2i(12, 11), Vector2i(5, 13), Vector2i(20, 14), Vector2i(26, 15)]:
				c.blossom(p.x, p.y, "flower_pink", "flower_light")
			for p in [Vector2i(14, 17), Vector2i(9, 18), Vector2i(22, 19)]:
				c.px(p.x, p.y, "blush")
		1:
			for p in [Vector2i(14, 5), Vector2i(11, 11), Vector2i(19, 12), Vector2i(8, 18), Vector2i(22, 19)]:
				c.px(p.x, p.y, "blush")
		2:
			for p in [Vector2i(9, 9), Vector2i(19, 6), Vector2i(14, 14), Vector2i(24, 12), Vector2i(6, 16), Vector2i(20, 17)]:
				c.px(p.x, p.y, "gold_light")
				c.px(p.x + 1, p.y, "honey")
				c.px(p.x, p.y + 1, "honey")
				c.px(p.x + 1, p.y + 1, "brown")
	return c


func _trees() -> void:
	var strip: RefCounted = PC.new(96, 32)
	for v in 3:
		strip.stamp(_tree(v), v * 32, 0)
	_save(strip, "sprites/world/tree.png")


func _rock(variant: int, iron := false) -> RefCounted:
	var c: RefCounted = PC.new(16, 16, 200 + variant)
	c.ground_shadow(8, 13.5, 6.5, 2.0)
	var k: RefCounted = PC.new(16, 16, 210 + variant)
	match variant:
		0:  # redondeada
			k.poly(PackedVector2Array([Vector2(2, 13), Vector2(2, 9), Vector2(5, 5), Vector2(9, 4), Vector2(13, 7), Vector2(14, 13)]), "stone")
		1:  # alta y puntuda
			k.poly(PackedVector2Array([Vector2(3, 14), Vector2(4, 8), Vector2(7, 2), Vector2(10, 4), Vector2(13, 9), Vector2(13, 14)]), "stone")
		2:  # chata y ancha
			k.poly(PackedVector2Array([Vector2(1, 14), Vector2(2, 10), Vector2(6, 7), Vector2(11, 7), Vector2(15, 10), Vector2(15, 14)]), "stone")
	k.shade("stone_light", "stone", "stone_dark", "stone_dark", PC.col("stone").lerp(PC.col("stone_light"), 0.5))
	# facetas: una arista diagonal
	match variant:
		0:
			k.line(9, 6, 7, 10, "stone_dark")
			k.px(8, 7, "stone_light")
		1:
			k.line(8, 4, 8, 9, "stone_dark")
			k.px(7, 5, "white")
		2:
			k.line(6, 9, 9, 11, "stone_dark")
			for p in [Vector2i(5, 8), Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 7), Vector2i(9, 8), Vector2i(10, 7)]:
				k.px(p.x, p.y, "moss")
			k.px(6, 7, "leaf_light")
	k.outline("plum")
	c.stamp(k)
	return c


func _rocks() -> void:
	var strip: RefCounted = PC.new(48, 16)
	for v in 3:
		strip.stamp(_rock(v), v * 16, 0)
	_save(strip, "sprites/world/rock.png")


func _bush(variant: int) -> RefCounted:
	var c: RefCounted = PC.new(16, 16, 300 + variant)
	c.ground_shadow(8, 13.5, 6.5, 2.0)
	var puffs := []
	match variant:
		0: puffs = [Vector3(8, 5.5, 3), Vector3(4.5, 7.5, 2.8), Vector3(11.5, 7.5, 2.8), Vector3(6, 10.5, 3), Vector3(10.5, 10.5, 3)]
		1: puffs = [Vector3(5.5, 6.5, 3.2), Vector3(4, 10.5, 3), Vector3(8.5, 10, 3), Vector3(12, 9.5, 2.6), Vector3(12, 12, 2.2)]
		2: puffs = [Vector3(8, 5, 2.8), Vector3(4.5, 8, 2.6), Vector3(11.5, 8, 2.6), Vector3(3.5, 11.5, 2.4), Vector3(8, 10.5, 3), Vector3(12.5, 11.5, 2.4)]
	var k := _crown(puffs, 16, 16, 310 + variant)
	c.stamp(k)
	match variant:
		0:
			c.blossom(6, 7, "flower_pink", "flower_light")
			c.px(11, 10, "blush")
		1:
			c.px(5, 6, "flower_light")
			c.px(6, 6, "blush")
		2:  # bayas violeta
			for p in [Vector2i(5, 9), Vector2i(10, 8), Vector2i(8, 11), Vector2i(12, 11)]:
				c.px(p.x, p.y, "hair_light")
				c.px(p.x + 1, p.y + 1, "hair")
	return c


func _bushes() -> void:
	var strip: RefCounted = PC.new(48, 16)
	for v in 3:
		strip.stamp(_bush(v), v * 16, 0)
	_save(strip, "sprites/world/bush.png")


# =====================================================================================
# DECORACIÓN (hito 9) — lo blando se pisa, lo duro bloquea
# =====================================================================================

func _deco() -> void:
	_save(_flowers(), "sprites/world/deco_flowers.png")
	_save(_tall_grass(), "sprites/world/deco_tall_grass.png")
	_save(_mushrooms(), "sprites/world/deco_mushrooms.png")
	_save(_stump(), "sprites/world/deco_stump.png")
	_save(_log(), "sprites/world/deco_log.png")
	_save(_boulder(), "sprites/world/deco_boulder.png")
	_save(_ruin_pillar(), "sprites/world/deco_ruin_pillar.png")
	_save(_ruin_wall(), "sprites/world/deco_ruin_wall.png")
	_save(_lilypads(), "sprites/world/deco_lilypad.png")


## Hojitas de una mata de flores (base de cada variante).
func _leaves_at(c: RefCounted, ox: int, pts: Array) -> void:
	for p: Vector2i in pts:
		c.px(ox + p.x, p.y, "leaf")
		c.px(ox + p.x, p.y + 1, "leaf_dark")
		c.px(ox + p.x - 1, p.y + 1, "leaf_light")


func _flowers() -> RefCounted:
	var c: RefCounted = PC.new(64, 16, 400)
	var leaves := [Vector2i(4, 11), Vector2i(7, 12), Vector2i(10, 11), Vector2i(12, 13), Vector2i(5, 13)]
	# 0: cerezo silvestre rosa
	_leaves_at(c, 0, leaves)
	for p in [Vector2i(5, 8), Vector2i(10, 7), Vector2i(8, 11), Vector2i(12, 10)]:
		c.blossom(p.x, p.y, "flower_pink", "flower_light")
		c.px(p.x + 1, p.y + 1, "rose")
	# 1: margaritas crema
	_leaves_at(c, 16, leaves)
	for p in [Vector2i(5, 9), Vector2i(10, 8), Vector2i(8, 12)]:
		c.blossom(16 + p.x, p.y, "ivory", "gold")
		c.px(16 + p.x + 1, p.y + 1, "sand")
	# 2: campanillas celestes
	_leaves_at(c, 32, leaves)
	for p in [Vector2i(4, 8), Vector2i(9, 7), Vector2i(11, 10), Vector2i(7, 11)]:
		c.px(32 + p.x, p.y, "iron_light")
		c.px(32 + p.x + 1, p.y, "ore_glint")
		c.px(32 + p.x, p.y + 1, "iron")
		c.px(32 + p.x + 1, p.y + 1, "iron_light")
		c.px(32 + p.x, p.y - 1, "leaf_dark")
	# 3: tulipanes rosados (sin rojo intenso: reservado para peligro y hallazgos)
	_leaves_at(c, 48, leaves)
	for p in [Vector2i(5, 7), Vector2i(10, 8)]:
		c.px(48 + p.x, p.y, "blush")
		c.px(48 + p.x + 1, p.y, "rose")
		c.px(48 + p.x, p.y + 1, "rose")
		c.px(48 + p.x + 1, p.y + 1, "red_dark")
		c.px(48 + p.x, p.y - 1, "flower_light")
		c.line(48 + p.x, p.y + 2, 48 + p.x, p.y + 4, "leaf_dark")
	return c


func _tall_grass() -> RefCounted:
	var c: RefCounted = PC.new(32, 16, 410)
	var blades := [Vector3(2, 13, 7), Vector3(4, 14, 9), Vector3(6, 13, 6), Vector3(8, 14, 10),
		Vector3(10, 13, 7), Vector3(12, 14, 8), Vector3(13, 13, 5)]
	for f in 2:
		for b: Vector3 in blades:
			var x0 := f * 16 + int(b.x)
			var lean := 1 if f == 1 else 0
			for i in int(b.z):
				var y := int(b.y) - i
				var x := x0 + (lean if i > b.z * 0.5 else 0)
				var tone := "grass_dark" if i < 2 else ("grass" if i < b.z - 2 else "grass_light")
				c.px(x, y, tone)
			c.px(x0 + lean, int(b.y) - int(b.z), "pale_leaf")
		c.px(f * 16 + 9, 6 + f, "blush")  # una florcita escondida
	return c


func _mushrooms() -> RefCounted:
	var c: RefCounted = PC.new(32, 16, 420)
	# 0: hongos crema con lunares miel
	for m in [Vector3(5, 12, 3), Vector3(10, 13, 2), Vector3(12, 10, 2)]:
		_mushroom(c, int(m.x), int(m.y), int(m.z), "cream", "honey", "sand")
	# 1: hongos rosados con puntos claros
	for m in [Vector3(21, 12, 3), Vector3(26, 13, 2), Vector3(18, 14, 2)]:
		_mushroom(c, int(m.x), int(m.y), int(m.z), "rose", "flower_light", "red_dark")
	return c


func _mushroom(c: RefCounted, x: int, y: int, r: int, cap: String, dot: String, cap_dark: String) -> void:
	c.rect(x, y - 1, 1, 3, "ivory")  # pie
	c.px(x + 1, y, "sand")
	c.px(x + 1, y + 1, "sand")
	for dx in range(-r, r + 2):  # sombrero
		c.px(x + dx, y - 2, cap_dark if dx > 0 else cap)
	for dx in range(-r + 1, r + 1):
		c.px(x + dx, y - 3, cap)
	c.px(x - r + 1, y - 3, "white" if cap == "cream" else "flower_light")
	if r >= 3:
		for dx in range(-r + 2, r):
			c.px(x + dx, y - 4, cap)
		c.px(x + 1, y - 3, dot)
		c.px(x - 1, y - 4, dot)
	c.px(x, y + 2, "grass_dark")


func _stump() -> RefCounted:
	var c: RefCounted = PC.new(16, 16, 430)
	c.ground_shadow(8, 13, 6.5, 2.2)
	var k: RefCounted = PC.new(16, 16, 431)
	k.rect(3, 7, 10, 6, "bark")
	k.poly(PackedVector2Array([Vector2(2, 13), Vector2(3, 11), Vector2(13, 11), Vector2(14, 13)]), "bark")  # raíces
	k.shade("wood_light", "bark", "brown", "brown_dark")
	k.ellipse(8, 7, 5, 2.4, "wood_light")  # cara de arriba: anillos
	k.ellipse(8, 7, 3.4, 1.4, "sand")
	k.px(8, 7, "honey")
	k.px(6, 7, "wood_light")
	k.px(10, 6, "path")
	k.line(4, 9, 4, 11, "brown")
	k.line(11, 9, 11, 12, "brown_dark")
	for p in [Vector2i(3, 12), Vector2i(4, 12), Vector2i(12, 10), Vector2i(12, 11)]:
		k.px(p.x, p.y, "moss")
	k.outline("brown_dark")
	c.stamp(k)
	return c


func _log() -> RefCounted:
	var c: RefCounted = PC.new(32, 16, 440)
	c.ground_shadow(16, 13, 14, 2.2)
	var k: RefCounted = PC.new(32, 16, 441)
	k.rect(5, 6, 25, 7, "bark")
	k.shade("wood_light", "bark", "brown", "brown_dark")
	for x in range(8, 28, 4):
		k.line(x, 8, x + 2, 8, "brown")
		k.line(x + 1, 10, x + 3, 10, "brown")
	k.ellipse(5, 9.5, 2.6, 3.6, "wood_light")  # extremo cortado
	k.ellipse(5, 9.5, 1.4, 2.2, "sand")
	k.px(5, 9, "honey")
	for x in range(13, 22):
		if x % 3 != 0:
			k.px(x, 6, "moss")
	k.px(15, 5, "leaf_light")
	k.px(19, 5, "moss")
	k.outline("brown_dark")
	c.stamp(k)
	_mushroom(c, 25, 7, 2, "cream", "honey", "sand")
	return c


func _boulder() -> RefCounted:
	var c: RefCounted = PC.new(32, 32, 450)
	c.ground_shadow(16, 28, 14, 3.2)
	var k: RefCounted = PC.new(32, 32, 451)
	k.poly(PackedVector2Array([Vector2(2, 28), Vector2(3, 18), Vector2(8, 9), Vector2(15, 5), Vector2(23, 7),
		Vector2(29, 14), Vector2(30, 28)]), "stone")
	k.shade("stone_light", "stone", "stone_dark", "stone_dark", PC.col("stone").lerp(PC.col("stone_light"), 0.5))
	k.line(15, 6, 13, 16, "stone_dark")  # facetas
	k.line(13, 16, 6, 22, "stone_dark")
	k.line(13, 16, 22, 21, "stone_dark")
	k.line(22, 21, 24, 27, "stone_dark")
	for y in range(7, 16):
		k.px(14, y, "stone_light")
	k.speckle(18, PC.col("stone").lerp(PC.col("stone_dark"), 0.5), 1, 0.5, "stone")
	k.speckle(8, "stone_light", 1, -0.7, "stone")
	for p in [Vector2i(10, 9), Vector2i(11, 9), Vector2i(12, 8), Vector2i(13, 8), Vector2i(16, 6), Vector2i(17, 6),
			Vector2i(18, 7), Vector2i(19, 7), Vector2i(11, 10), Vector2i(17, 7), Vector2i(9, 10)]:
		k.px(p.x, p.y, "moss")
	for p in [Vector2i(12, 8), Vector2i(17, 6)]:
		k.px(p.x, p.y, "leaf_light")
	k.outline("plum")
	c.stamp(k)
	c.blossom(19, 6, "flower_pink", "flower_light")
	return c


func _ruin_pillar() -> RefCounted:
	var c: RefCounted = PC.new(16, 32, 460)
	c.ground_shadow(8, 29, 6.5, 2.2)
	var k: RefCounted = PC.new(16, 32, 461)
	k.poly(PackedVector2Array([Vector2(4, 30), Vector2(4, 9), Vector2(6, 6), Vector2(8, 8), Vector2(10, 4),
		Vector2(12, 7), Vector2(12, 30)]), "stone")
	k.rect(2, 26, 12, 4, "stone")  # base
	k.shade("stone_light", "stone", "stone_dark", "stone_dark")
	for x in [6, 9]:
		k.line(x, 10, x, 25, PC.col("stone").lerp(PC.col("stone_dark"), 0.55))  # acanaladuras
	k.line(3, 26, 12, 26, "stone_light")
	k.line(10, 12, 8, 16, "stone_dark")  # grieta
	for p in [Vector2i(5, 14), Vector2i(6, 15), Vector2i(5, 16), Vector2i(4, 17), Vector2i(5, 18), Vector2i(6, 19),
			Vector2i(7, 20), Vector2i(6, 21), Vector2i(11, 22), Vector2i(10, 23), Vector2i(11, 24)]:
		k.px(p.x, p.y, "leaf")  # enredadera
	k.px(4, 17, "leaf_light")
	k.px(7, 20, "leaf_light")
	k.outline("plum")
	c.stamp(k)
	c.px(6, 15, "blush")
	return c


func _ruin_wall() -> RefCounted:
	var c: RefCounted = PC.new(32, 16, 470)
	c.ground_shadow(16, 13.5, 15, 2)
	var k: RefCounted = PC.new(32, 16, 471)
	k.poly(PackedVector2Array([Vector2(1, 14), Vector2(1, 6), Vector2(9, 6), Vector2(10, 4), Vector2(19, 4),
		Vector2(20, 7), Vector2(26, 7), Vector2(27, 9), Vector2(31, 9), Vector2(31, 14)]), "stone")
	k.shade("stone_light", "stone", "stone_dark", "stone_dark")
	for y in [9, 12]:
		k.line(1, y, 30, y, "stone_dark")
	for x in [6, 14]:
		k.line(x, 7, x, 8, "stone_dark")
	for x in [3, 10, 18, 26]:
		k.line(x, 10, x, 11, "stone_dark")
	for x in [8, 16, 24]:
		k.px(x, 13, "stone_dark")
	for p in [Vector2i(10, 4), Vector2i(11, 4), Vector2i(12, 4), Vector2i(17, 4), Vector2i(18, 5), Vector2i(2, 6),
			Vector2i(3, 6), Vector2i(27, 9), Vector2i(28, 9), Vector2i(29, 10)]:
		k.px(p.x, p.y, "moss")
	k.outline("plum")
	c.stamp(k)
	return c


func _lilypads() -> RefCounted:
	var c: RefCounted = PC.new(32, 16, 480)
	for v in 2:
		var ox := v * 16
		var pads := [Vector3(6, 9, 3.6), Vector3(11.5, 5, 2.4)] if v == 0 else [Vector3(8, 8, 4.2), Vector3(3.5, 12.5, 2.2)]
		for p: Vector3 in pads:
			var k: RefCounted = PC.new(16, 16, 481 + v)
			k.ellipse(p.x, p.y, p.z, p.z * 0.75, "leaf")
			k.shade("leaf_light", "leaf", "leaf_dark")
			k.px(int(p.x), int(p.y), "water")  # muesca
			k.px(int(p.x) + 1, int(p.y) - 1, "water")
			k.line(int(p.x) - 1, int(p.y) + 1, int(p.x) - 2, int(p.y) + 1, "leaf_dark")
			k.outline("jade_deep")
			c.stamp(k, ox, 0)
		if v == 1:  # flor de loto
			c.px(ox + 7, 6, "flower_light")
			c.px(ox + 6, 7, "flower_pink")
			c.px(ox + 8, 7, "flower_pink")
			c.px(ox + 7, 7, "gold_light")
			c.px(ox + 7, 8, "rose")
			c.px(ox + 6, 8, "flower_pink")
			c.px(ox + 8, 8, "flower_pink")
	return c


# =====================================================================================
# EVENTOS RAROS (hito 9) — se tienen que ver especiales desde lejos
# =====================================================================================

func _events() -> void:
	_save(_ancient_tree(), "sprites/world/ancient_tree.png")
	_save(_lost_chest(), "sprites/world/lost_chest.png")
	_save(_shiny_vein(), "sprites/world/shiny_vein.png")
	_save(_campfire(), "sprites/world/campfire.png")
	_save(_tent(), "sprites/world/camp_tent.png")


## Árbol antiguo: copa enorme más oscura, tronco retorcido con raíces y una cuerda sagrada
## (shimenawa) con papelitos en zigzag: se reconoce como especial a primera vista.
func _ancient_tree() -> RefCounted:
	var c: RefCounted = PC.new(48, 48, 500)
	c.ground_shadow(24, 44, 18, 3.5)
	var k: RefCounted = PC.new(48, 48, 501)
	k.poly(PackedVector2Array([Vector2(19, 24), Vector2(28, 24), Vector2(29, 34), Vector2(31, 39), Vector2(36, 44),
		Vector2(28, 43), Vector2(24, 45), Vector2(20, 43), Vector2(12, 44), Vector2(17, 39), Vector2(18, 33)]), "bark")
	k.shade("wood_light", "bark", "brown", "brown_dark")
	for i in 4:  # corteza retorcida
		k.line(20 + i * 2, 26, 21 + i * 2, 41, "brown" if i % 2 == 0 else "bark")
	k.line(24, 30, 26, 35, "brown_dark")  # hueco
	k.px(25, 32, "ink")
	k.px(25, 33, "ink")
	k.outline("brown_dark")
	c.stamp(k)
	var crown := _crown(_puffs_in(24, 15, 22, 14, 5.0, 503), 48, 48, 502,
		["jade_bright", "leaf", "leaf_dark", "jade_deep", "hair_dark"])
	c.stamp(crown)
	for x in range(17, 31):  # shimenawa: cuerda de paja + papelitos blancos
		c.px(x, 30, "honey" if x % 2 == 0 else "gold")
		c.px(x, 31, "brown" if x % 2 == 0 else "honey")
	for x in [19, 24, 29]:
		c.px(x, 32, "white")
		c.px(x + 1, 33, "white")
		c.px(x, 34, "white")
		c.px(x + 1, 35, "stone_light")
	for p in [Vector2i(22, 37), Vector2i(26, 27)]:  # brillo en la corteza
		c.px(p.x, p.y, "gold_light")
	for p in [Vector2i(8, 26), Vector2i(41, 22), Vector2i(36, 33), Vector2i(5, 12)]:  # luciérnagas
		c.px(p.x, p.y, "gold_light")
	for p in [Vector2i(12, 8), Vector2i(26, 5), Vector2i(36, 11), Vector2i(17, 16), Vector2i(31, 17), Vector2i(8, 19), Vector2i(40, 20)]:
		c.blossom(p.x, p.y, "flower_pink", "flower_light")
	return c


func _lost_chest() -> RefCounted:
	var c: RefCounted = PC.new(32, 16, 510)
	for f in 2:
		var ox := f * 16
		c.ground_shadow(ox + 8, 14, 7, 1.8)
		var k: RefCounted = PC.new(16, 16, 511)
		k.rect(2, 8, 12, 6, "brown")  # cuerpo
		k.shade("bark", "brown", "brown_dark")
		k.rect(2, 10, 12, 1, "stone_dark")  # zuncho de hierro
		k.px(7, 10, "gold")
		k.px(8, 10, "gold")
		k.px(7, 11, "honey")
		if f == 0:  # tapa cerrada, abombada, con musgo
			k.rect(2, 5, 12, 3, "bark")
			k.rect(3, 4, 10, 1, "bark")
			k.line(3, 4, 12, 4, "wood_light")
			k.line(2, 7, 13, 7, "brown_dark")
			for p in [Vector2i(3, 5), Vector2i(4, 4), Vector2i(5, 4), Vector2i(11, 5), Vector2i(12, 6)]:
				k.px(p.x, p.y, "moss")
		else:  # abierta: tapa atrás y brillo dorado
			k.rect(2, 2, 12, 3, "brown_dark")
			k.line(3, 2, 12, 2, "brown")
			k.rect(3, 7, 10, 1, "gold")
			k.px(5, 6, "gold_light")
			k.px(9, 6, "gold_light")
			k.px(7, 7, "white")
		k.outline("ink")
		c.stamp(k, ox, 0)
		if f == 1:
			c.px(ox + 7, 3, "gold_light")
			c.px(ox + 11, 1, "flower_light")
			c.px(ox + 4, 1, "gold_light")
	return c


func _shiny_vein() -> RefCounted:
	var c: RefCounted = PC.new(64, 16, 520)
	var base := _rock(0)
	var glint := [Vector2i(5, 7), Vector2i(7, 9), Vector2i(10, 8), Vector2i(12, 10)]
	for f in 4:
		var ox := f * 16
		c.stamp(base, ox, 0)
		for p in [Vector2i(5, 8), Vector2i(6, 8), Vector2i(7, 9), Vector2i(10, 8), Vector2i(11, 9), Vector2i(9, 11), Vector2i(4, 10)]:
			c.px(ox + p.x, p.y, "ore_blue")
		for p in [Vector2i(6, 7), Vector2i(10, 7)]:
			c.px(ox + p.x, p.y, "ore_glint")
		var g: Vector2i = glint[f]  # destello que recorre la veta
		c.px(ox + g.x, g.y, "white")
		c.px(ox + g.x - 1, g.y, "ore_glint")
		c.px(ox + g.x + 1, g.y, "ore_glint")
		c.px(ox + g.x, g.y - 1, "ore_glint")
		c.px(ox + g.x, g.y + 1, "ore_glint")
		if f % 2 == 0:
			c.px(ox + 13, 3, "white")
	return c


func _campfire() -> RefCounted:
	var c: RefCounted = PC.new(64, 16, 530)
	var heights := [[5, 7, 4], [6, 5, 6], [4, 7, 5], [6, 6, 4]]
	var xs := [6, 8, 10]
	for f in 4:
		var ox := f * 16
		c.ground_shadow(ox + 8, 13, 7, 2)
		for p in [Vector2i(2, 12), Vector2i(5, 13), Vector2i(10, 13), Vector2i(13, 12), Vector2i(3, 10), Vector2i(12, 10)]:
			c.px(ox + p.x, p.y, "stone")  # piedras en ronda
			c.px(ox + p.x + 1, p.y, "stone_dark")
			c.px(ox + p.x, p.y - 1, "stone_light")
		c.line(ox + 4, 12, ox + 11, 9, "brown")  # leños cruzados
		c.line(ox + 4, 9, ox + 11, 12, "bark")
		c.px(ox + 4, 9, "wood_light")
		var hts: Array = heights[f]
		for i in 3:  # tres lenguas de fuego que cambian de altura
			var x: int = ox + int(xs[i])
			var ht: int = hts[i]
			for j in ht:
				var y := 10 - j
				var tone := "red" if j < 2 else ("ember" if j < ht - 1 else "flame")
				c.px(x, y, tone)
				if j < ht - 2:
					c.px(x + (1 if i == 2 else -1) * (j % 2), y, "ember" if j > 0 else "red")
		c.px(ox + 8, 9, "flame")
		c.px(ox + 8, 8, "white")
		c.px(ox + [5, 11, 7, 10][f], [3, 2, 1, 3][f], "flame")  # chispa
	return c


func _tent() -> RefCounted:
	var c: RefCounted = PC.new(32, 32, 540)
	c.ground_shadow(16, 29, 15, 2.8)
	var k: RefCounted = PC.new(32, 32, 541)
	k.poly(PackedVector2Array([Vector2(16, 5), Vector2(30, 28), Vector2(2, 28)]), "sand")
	k.shade("cream", "sand", "path", "path_shadow")
	for y in range(6, 28):  # lado en sombra (la luz viene de la izquierda)
		for x in range(16, 31):
			if k.solid(x, y) and x > 16 + (y - 6) * 0.25:
				k.px(x, y, "path")
	k.poly(PackedVector2Array([Vector2(16, 14), Vector2(21, 28), Vector2(11, 28)]), "plum")  # entrada
	k.line(16, 14, 11, 27, "ink")
	k.line(13, 27, 16, 17, "red_dark")  # solapa
	k.rect(5, 22, 3, 3, "honey")  # parche
	k.line(9, 18, 14, 9, "path_shadow")
	k.outline("brown_dark")
	c.stamp(k)
	c.line(16, 1, 16, 6, "brown_dark")  # palo y banderita
	c.px(17, 1, "red")
	c.px(18, 2, "red")
	c.px(17, 2, "red_dark")
	return c
