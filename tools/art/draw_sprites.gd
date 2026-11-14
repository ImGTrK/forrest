extends SceneTree
## Sprites del juego (ítems, herramientas, props del pueblo, UI y enemigo) dibujados por código
## con el mismo pincel que el bosque (tools/art/pixel_canvas.gd): paleta Forrest, luz desde
## arriba a la izquierda, contorno de 1 px. Objetos usables y actores: contorno "ink".
##
## Uso:   godot --headless --path . --script res://tools/art/draw_sprites.gd [-- solo=items,props,ui,enemy]
## Pisa los PNG que genera. Lo retocado a mano conviene versionarlo antes.

const PC := preload("res://tools/art/pixel_canvas.gd")
const OUT := "res://assets/sprites/"


func _init() -> void:
	var only := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("solo="):
			only = a.trim_prefix("solo=").split(",")
	var jobs := {"items": _items, "props": _props, "ui": _ui, "enemy": _enemy}
	for k: String in jobs:
		if only.is_empty() or only.has(k):
			jobs[k].call()
			print("ok ", k)
	quit()


func _save(c: RefCounted, rel: String) -> void:
	c.save(ProjectSettings.globalize_path(OUT + rel))


func _layer(w: int, h: int, s := 1) -> RefCounted:
	return PC.new(w, h, s)


# =====================================================================================
# ÍTEMS — se ven en la mochila (1 celda = 16 px). Herramientas: mango abajo, cabeza arriba.
# =====================================================================================

func _items() -> void:
	_save(_wood(), "items/wood.png")
	_save(_stone_item(), "items/stone.png")
	_save(_iron_item(), "items/iron.png")
	_save(_axe("stone"), "items/stone_axe.png")
	_save(_axe("iron"), "items/iron_axe.png")
	_save(_pickaxe("stone"), "items/stone_pickaxe.png")
	_save(_pickaxe("iron"), "items/iron_pickaxe.png")
	_save(_sword_item("wood"), "items/wood_sword.png")
	_save(_sword_item("iron"), "items/iron_sword.png")
	_save(_lantern(), "items/lantern.png")
	_save(_oil(), "items/oil.png")


## Tronco parado (1×2): corte con anillos arriba, corteza con vetas y un brote.
func _wood() -> RefCounted:
	var c := _layer(16, 32, 11)
	var k := _layer(16, 32, 12)
	k.rect(4, 5, 8, 23, "bark")
	k.ellipse(8, 28, 4, 1.6, "bark")
	k.shade("wood_light", "bark", "brown", "brown_dark")
	for y in [9, 14, 20, 24]:
		k.line(6, y, 7, y + 2, "brown")
	k.line(10, 11, 10, 17, "brown")
	k.px(5, 12, "wood_light")
	k.px(5, 18, "wood_light")
	k.ellipse(8, 5, 4, 2, "wood_light")  # cara del corte
	k.ellipse(8, 5, 2.6, 1.2, "sand")
	k.px(8, 5, "honey")
	k.px(6, 4, "cream")
	k.outline("ink")
	c.stamp(k)
	# brote
	c.px(12, 15, "leaf")
	c.px(13, 14, "leaf_light")
	c.px(13, 15, "leaf_dark")
	return c


func _stone_item() -> RefCounted:
	var c := _layer(16, 16, 13)
	var k := _layer(16, 16, 14)
	k.poly(PackedVector2Array([Vector2(2, 12), Vector2(3, 7), Vector2(7, 3), Vector2(12, 4), Vector2(14, 9), Vector2(12, 13), Vector2(5, 14)]), "stone")
	k.shade("stone_light", "stone", "stone_dark", "stone_dark", PC.col("stone").lerp(PC.col("stone_light"), 0.5))
	k.line(8, 5, 7, 9, "stone_dark")
	k.line(7, 9, 11, 11, "stone_dark")
	k.px(6, 5, "white")
	k.outline("ink")
	c.stamp(k)
	return c


func _iron_item() -> RefCounted:
	var c := _layer(16, 16, 15)
	var k := _layer(16, 16, 16)
	k.poly(PackedVector2Array([Vector2(2, 11), Vector2(4, 6), Vector2(8, 3), Vector2(13, 5), Vector2(14, 10), Vector2(11, 14), Vector2(4, 14)]), "stone_dark")
	k.shade("stone", "stone_dark", "plum", "plum")
	# cristales de hierro
	for p in [Vector2i(5, 8), Vector2i(6, 7), Vector2i(6, 8), Vector2i(9, 6), Vector2i(10, 6), Vector2i(10, 7), Vector2i(8, 11), Vector2i(9, 11), Vector2i(11, 10)]:
		k.px(p.x, p.y, "iron")
	for p in [Vector2i(6, 7), Vector2i(9, 6), Vector2i(8, 11)]:
		k.px(p.x, p.y, "iron_light")
	k.px(10, 6, "white")
	k.outline("ink")
	c.stamp(k)
	return c


## Mango de herramienta: madera con vendaje cerca de la cabeza y punta oscura abajo.
func _handle(k: RefCounted, x: int, y0: int, y1: int) -> void:
	k.rect(x, y0, 2, y1 - y0, "bark")
	for y in range(y0, y1):
		k.px(x, y, "wood_light" if y % 5 != 0 else "bark")
		k.px(x + 1, y, "brown")
	k.rect(x, y1, 2, 1, "brown_dark")


func _metal(mat: String) -> Array:
	# [luz, medio, sombra, profunda]
	return ["stone_light", "stone", "stone_dark", "plum"] if mat == "stone" else ["white", "iron_light", "iron", "ore_blue"]


func _axe(mat: String) -> RefCounted:
	var c := _layer(16, 32, 21)
	var k := _layer(16, 32, 22)
	_handle(k, 7, 6, 29)
	k.rect(6, 10, 4, 2, "cream" if mat == "stone" else "stone_dark")  # atadura / abrazadera
	var m := _metal(mat)
	var head := _layer(16, 32, 23)
	if mat == "stone":
		head.poly(PackedVector2Array([Vector2(8, 3), Vector2(12, 2), Vector2(15, 5), Vector2(15, 10), Vector2(12, 12), Vector2(8, 11)]), m[1])
	else:
		head.poly(PackedVector2Array([Vector2(8, 4), Vector2(11, 4), Vector2(15, 1), Vector2(15, 13), Vector2(11, 10), Vector2(8, 10)]), m[1])
	head.shade(m[0], m[1], m[2], m[3])
	head.line(14, 3, 14, 10, m[0])  # filo brillante
	k.stamp(head)
	k.rect(5, 4, 3, 6, m[2])  # contrapeso del otro lado
	k.px(5, 4, m[1])
	k.outline("ink")
	c.stamp(k)
	return c


func _pickaxe(mat: String) -> RefCounted:
	var c := _layer(16, 32, 31)
	var k := _layer(16, 32, 32)
	_handle(k, 7, 5, 29)
	var m := _metal(mat)
	var head := _layer(16, 32, 33)
	# cabeza curva de lado a lado
	for x in range(1, 15):
		var t := (x - 7.5) / 6.5
		var y := 2 + roundi(t * t * 4.0)
		var thick := 4 if absf(t) < 0.4 else (3 if absf(t) < 0.8 else 2)
		head.rect(x, y, 1, thick, m[1])
	head.shade(m[0], m[1], m[2], m[3])
	head.px(1, 6, m[0])
	head.px(14, 6, m[0])
	k.stamp(head)
	k.rect(6, 6, 4, 2, "cream" if mat == "stone" else "stone_dark")
	k.outline("ink")
	c.stamp(k)
	return c


func _sword_item(mat: String) -> RefCounted:
	var c := _layer(16, 32, 41)
	var k := _layer(16, 32, 42)
	var m := ["cream", "wood_light", "bark", "brown"] if mat == "wood" else ["white", "iron_light", "iron", "ore_blue"]
	# hoja
	k.poly(PackedVector2Array([Vector2(8, 1), Vector2(10, 3), Vector2(10, 20), Vector2(6, 20), Vector2(6, 3)]), m[1])
	k.shade(m[0], m[1], m[2], m[3])
	k.line(8, 3, 8, 19, m[0] if mat == "iron" else m[1])  # canal
	k.line(9, 4, 9, 19, m[2])
	# guarda y mango
	k.rect(3, 20, 10, 2, "honey" if mat == "iron" else "brown")
	k.px(3, 20, "gold_light" if mat == "iron" else "bark")
	k.rect(7, 22, 2, 6, "brown")
	for y in range(22, 28, 2):
		k.px(7, y, "bark")
	k.rect(6, 28, 4, 2, "honey" if mat == "iron" else "bark")  # pomo
	k.outline("ink")
	c.stamp(k)
	return c


## Linterna de piedra (tōrō): techito, ventana con luz, pie.
func _lantern() -> RefCounted:
	var c := _layer(16, 16, 51)
	var k := _layer(16, 16, 52)
	k.poly(PackedVector2Array([Vector2(8, 0), Vector2(14, 4), Vector2(2, 4)]), "stone")  # techo
	k.rect(4, 5, 8, 5, "stone")  # caja de luz
	k.rect(6, 10, 4, 3, "stone")  # pie
	k.rect(3, 13, 10, 2, "stone")  # base
	k.shade("stone_light", "stone", "stone_dark", "stone_dark")
	k.rect(6, 6, 4, 3, "gold")  # ventana con luz
	k.rect(6, 6, 2, 1, "flame")
	k.px(9, 8, "honey")
	k.outline("ink")
	c.stamp(k)
	return c


func _oil() -> RefCounted:
	var c := _layer(16, 16, 61)
	var k := _layer(16, 16, 62)
	k.ellipse(8, 10, 5, 4.2, "honey")  # cuerpo
	k.rect(6, 3, 4, 4, "stone_light")  # cuello
	k.shade("gold_light", "honey", "brown", "brown_dark")
	k.rect(6, 3, 4, 2, "bark")  # corcho
	k.px(6, 3, "wood_light")
	k.line(4, 9, 4, 11, "white")  # brillo del vidrio
	k.px(5, 8, "white")
	k.rect(5, 10, 6, 2, "cream")  # etiqueta
	k.px(7, 10, "red_dark")
	k.outline("ink")
	c.stamp(k)
	return c


# =====================================================================================
# PROPS DEL PUEBLO Y VETA DE HIERRO
# =====================================================================================

func _props() -> void:
	_save(_chest(), "world/chest.png")
	_save(_bed(), "world/bed.png")
	_save(_bench(), "world/bench.png")
	_save(_board(), "world/board.png")
	_save(_iron_vein(), "world/iron_vein.png")


func _chest() -> RefCounted:
	var c := _layer(16, 16, 71)
	c.ground_shadow(8, 14, 7, 1.8)
	var k := _layer(16, 16, 72)
	k.rect(1, 6, 14, 8, "bark")  # cuerpo
	k.rect(1, 3, 14, 3, "bark")  # tapa
	k.rect(2, 2, 12, 1, "bark")
	k.shade("wood_light", "bark", "brown", "brown_dark")
	k.line(1, 6, 14, 6, "brown_dark")  # junta de la tapa
	for x in [4, 11]:  # refuerzos dorados
		k.line(x, 2, x, 13, "honey")
		k.px(x, 2, "gold_light")
	k.rect(7, 6, 2, 3, "gold")  # cerradura
	k.px(7, 6, "gold_light")
	k.px(8, 8, "brown_dark")
	k.outline("ink")
	c.stamp(k)
	return c


## Futón sobre un bastidor de madera (vertical, cabecera arriba).
func _bed() -> RefCounted:
	var c := _layer(16, 32, 81)
	c.ground_shadow(8, 30, 7.5, 2)
	var k := _layer(16, 32, 82)
	k.rect(1, 1, 14, 29, "bark")  # bastidor
	k.shade("wood_light", "bark", "brown", "brown_dark")
	k.rect(2, 3, 12, 25, "cream")  # colchón
	k.rect(3, 4, 10, 5, "ivory")  # almohada
	k.line(3, 8, 12, 8, "sand")
	k.px(3, 4, "white")
	k.rect(2, 11, 12, 17, "rose")  # acolchado
	k.line(2, 11, 13, 11, "flower_pink")  # doblez
	k.line(2, 12, 13, 12, "blush")
	for y in [16, 21, 26]:  # pespunte
		for x in range(4, 13, 3):
			k.px(x, y, "flower_pink")
	for y in range(13, 28):
		k.px(13, y, "red_dark")  # sombra lateral
	k.outline("ink")
	c.stamp(k)
	return c


## Mesa de trabajo (2×1) con herramientas encima.
func _bench() -> RefCounted:
	var c := _layer(32, 16, 91)
	c.ground_shadow(16, 14.5, 15, 1.6)
	var k := _layer(32, 16, 92)
	k.rect(1, 5, 30, 4, "bark")  # tablero
	k.rect(3, 9, 3, 5, "brown")  # patas
	k.rect(26, 9, 3, 5, "brown")
	k.rect(6, 11, 20, 1, "brown")  # travesaño
	k.shade("wood_light", "bark", "brown", "brown_dark")
	for x in range(4, 30, 7):
		k.px(x, 7, "brown")  # vetas
	# encima: martillo, serrucho y una piedra
	k.rect(5, 3, 6, 2, "stone_dark")  # cabeza del martillo
	k.px(5, 3, "stone_light")
	k.line(8, 4, 13, 4, "wood_light")  # mango
	k.poly(PackedVector2Array([Vector2(17, 4), Vector2(25, 2), Vector2(25, 4)]), "stone_light")  # serrucho
	k.rect(25, 2, 2, 3, "bark")
	k.px(28, 4, "stone")
	k.px(29, 4, "stone_dark")
	k.outline("ink")
	c.stamp(k)
	return c


## Tablón de misiones (2×2): techito de tejas con musgo, papeles con chinches, patas (colisión abajo).
func _board() -> RefCounted:
	var c := _layer(32, 32, 101)
	c.ground_shadow(16, 30, 13, 2)
	var k := _layer(32, 32, 102)
	k.rect(5, 18, 2, 12, "brown")  # postes
	k.rect(25, 18, 2, 12, "brown")
	k.rect(3, 6, 26, 15, "bark")  # marco
	k.shade("wood_light", "bark", "brown", "brown_dark")
	k.rect(5, 8, 22, 11, "brown")  # fondo de corcho/madera oscura
	k.rect(5, 8, 22, 1, "brown_dark")
	# techito
	k.poly(PackedVector2Array([Vector2(1, 6), Vector2(16, 1), Vector2(31, 6), Vector2(29, 7), Vector2(3, 7)]), "leaf_dark")
	for x in range(3, 29, 3):
		k.px(x, 6, "leaf")
	k.line(4, 5, 15, 2, "leaf_light")
	k.line(17, 2, 28, 5, "leaf")
	# papeles
	for r in [Rect2i(7, 9, 5, 6), Rect2i(14, 10, 5, 5), Rect2i(21, 9, 4, 7), Rect2i(10, 15, 6, 3)]:
		k.rect(r.position.x, r.position.y, r.size.x, r.size.y, "cream")
		k.line(r.position.x, r.position.y, r.end.x - 1, r.position.y, "ivory")
		for y in range(r.position.y + 2, r.end.y - 1, 2):
			k.line(r.position.x + 1, y, r.end.x - 2, y, "sand")
		k.px(r.position.x + r.size.x / 2, r.position.y, "red")  # chinche
	k.outline("ink")
	c.stamp(k)
	# florcitas al pie de los postes
	c.blossom(3, 28, "flower_pink", "flower_light")
	c.blossom(29, 29, "blush", "flower_light")
	return c


## Veta de hierro: roca con cristales azules (sin el destello animado de la veta brillante).
func _iron_vein() -> RefCounted:
	var c := _layer(16, 16, 111)
	c.ground_shadow(8, 13.5, 6.5, 2.0)
	var k := _layer(16, 16, 112)
	k.poly(PackedVector2Array([Vector2(2, 13), Vector2(2, 9), Vector2(5, 5), Vector2(9, 4), Vector2(13, 7), Vector2(14, 13)]), "stone")
	k.shade("stone_light", "stone", "stone_dark", "stone_dark", PC.col("stone").lerp(PC.col("stone_light"), 0.5))
	for p in [Vector2i(5, 8), Vector2i(6, 8), Vector2i(6, 9), Vector2i(9, 6), Vector2i(10, 7), Vector2i(10, 8), Vector2i(8, 11), Vector2i(9, 11), Vector2i(12, 10)]:
		k.px(p.x, p.y, "ore_blue")
	for p in [Vector2i(6, 8), Vector2i(10, 7), Vector2i(9, 11)]:
		k.px(p.x, p.y, "ore_glint")
	k.outline("plum")
	c.stamp(k)
	return c


# =====================================================================================
# UI — se ve al doble; los rellenos que el código tiñe van en blanco/grises
# =====================================================================================

func _ui() -> void:
	_save(_heart(2), "ui/hearts/heart_full.png")
	_save(_heart(1), "ui/hearts/heart_half.png")
	_save(_heart(0), "ui/hearts/heart_empty.png")
	_save(_slot(), "ui/slot.png")
	_save(_icon_clock(), "ui/icon_clock.png")
	_save(_icon_energy(), "ui/icon_energy.png")
	_save(_icon_weight(), "ui/icon_weight.png")
	_save(_bar(false), "ui/energy_bar_under.png")
	_save(_bar(true), "ui/energy_bar_fill.png")


## 2 = lleno · 1 = medio · 0 = vacío
func _heart(fill: int) -> RefCounted:
	var c := _layer(16, 16, 121)
	var shape := _layer(16, 16, 122)
	shape.disc(5, 6, 3.6, "red")
	shape.disc(11, 6, 3.6, "red")
	shape.poly(PackedVector2Array([Vector2(1.5, 7), Vector2(14.5, 7), Vector2(8, 14.5)]), "red")
	var k := _layer(16, 16, 123)
	for y in 16:
		for x in 16:
			if not shape.solid(x, y):
				continue
			var full: bool = fill == 2 or (fill == 1 and x < 8)
			k.px(x, y, "red" if full else "hair_dark")
	# luz y sombra a mano (respetando la mitad vacía)
	for y in 16:
		for x in 16:
			if not k.solid(x, y):
				continue
			var full: bool = fill == 2 or (fill == 1 and x < 8)
			var edge_dr: bool = not shape.solid(x + 1, y) or not shape.solid(x, y + 1)
			if edge_dr:
				k.px(x, y, "red_dark" if full else "plum")
	if fill > 0:
		k.px(4, 4, "white")
		k.px(3, 5, "flower_light")
		k.px(4, 5, "flower_pink")
	else:
		k.px(4, 4, "hair")
	k.outline("ink")
	c.stamp(k)
	return c


## Celda de inventario 18×18: borde, bisel y fondo oscuro.
func _slot() -> RefCounted:
	var c := _layer(18, 18, 131)
	c.rect(0, 0, 18, 18, "ink")
	c.rect(1, 1, 16, 16, "plum")
	c.line(1, 1, 16, 1, "hair")
	c.line(1, 1, 1, 16, "hair")
	c.line(2, 16, 16, 16, "hair_dark")
	c.line(16, 2, 16, 16, "hair_dark")
	c.px(3, 3, "hair_light")
	return c


func _icon_clock() -> RefCounted:
	var c := _layer(8, 8, 141)
	c.disc(4, 4, 3.5, "cream")
	c.line(4, 2, 4, 4, "ink")
	c.line(4, 4, 6, 4, "ink")
	c.px(2, 2, "white")
	c.outline("ink")
	return c


func _icon_energy() -> RefCounted:
	var c := _layer(8, 8, 151)
	c.poly(PackedVector2Array([Vector2(5, 0), Vector2(1, 4.5), Vector2(4, 4.5), Vector2(3, 8), Vector2(7, 3.5), Vector2(4, 3.5)]), "gold")
	c.px(4, 1, "gold_light")
	c.outline("ink")
	return c


func _icon_weight() -> RefCounted:
	var c := _layer(8, 8, 161)
	c.rect(1, 3, 6, 4, "stone")
	c.rect(2, 2, 4, 1, "stone")
	c.rect(3, 1, 2, 1, "stone_dark")
	c.px(2, 3, "stone_light")
	c.line(1, 6, 6, 6, "stone_dark")
	c.outline("ink")
	return c


func _bar(fill: bool) -> RefCounted:
	var c := _layer(64, 8, 171)
	if fill:
		# blanco/grises: el HUD lo tiñe (verde → amarillo → rojo)
		c.rect(1, 1, 62, 6, PC.col("white"))
		c.line(1, 1, 62, 1, Color(1, 1, 1))
		c.line(1, 5, 62, 5, Color(0.78, 0.78, 0.78))
		c.line(1, 6, 62, 6, Color(0.66, 0.66, 0.66))
	else:
		c.rect(0, 0, 64, 8, "ink")
		c.rect(1, 1, 62, 6, "plum")
		c.line(1, 6, 62, 6, "hair_dark")
	return c


# =====================================================================================
# ENEMIGO BÁSICO — erizo-fruta (2 frames de 16×16: 0 parpadeo, 1 normal). Mira a la derecha.
# El rojo intenso queda para el peligro: es el único enemigo rojo.
# =====================================================================================

func _enemy() -> void:
	var c := _layer(32, 16, 181)
	for f in 2:
		c.stamp(_enemy_frame(f == 0), f * 16, 0)
	_save(c, "enemies/enemy_basic.png")
	_save(_swing_sword(), "player/sword.png")


func _enemy_frame(blink: bool) -> RefCounted:
	var c := _layer(16, 16, 191)
	c.ground_shadow(8, 14.5, 6, 1.4)
	var body := _layer(16, 16, 192)
	body.ellipse(7, 9.5, 5.5, 4.6, "red")
	# púas en el lomo
	for p in [Vector2i(2, 6), Vector2i(4, 4), Vector2i(7, 3), Vector2i(10, 4), Vector2i(1, 9)]:
		body.px(p.x, p.y, "red")
		body.px(p.x + 1, p.y, "red")
		body.px(p.x, p.y - 1, "red")
	body.shade("rose", "red", "red_dark", "red_dark")
	# cara rosada a la derecha
	body.ellipse(11.5, 10, 3, 2.6, "blush")
	body.px(14, 10, "blush")
	body.px(10, 9, "flower_light")
	body.px(14, 11, "rose")  # hocico
	if blink:
		body.line(11, 9, 12, 9, "ink")
	else:
		body.px(12, 9, "ink")
		body.px(12, 8, "ink")
		body.px(11, 8, "white")
	body.px(10, 11, "rose")  # cachete
	# patitas
	body.px(4, 14, "red_dark")
	body.px(9, 14, "red_dark")
	body.outline("ink")
	c.stamp(body)
	# hojitas en la cabeza (es una fruta)
	c.px(7, 2, "leaf")
	c.px(8, 1, "leaf_light")
	c.px(6, 1, "leaf_dark")
	return c


## Espada del swing (16×16, apuntando hacia arriba; el código la rota).
func _swing_sword() -> RefCounted:
	var c := _layer(16, 16, 201)
	var k := _layer(16, 16, 202)
	k.poly(PackedVector2Array([Vector2(8, 0), Vector2(9.5, 2), Vector2(9.5, 10), Vector2(6.5, 10), Vector2(6.5, 2)]), "stone_light")
	k.shade("white", "stone_light", "stone", "stone_dark")
	k.rect(5, 10, 6, 1, "honey")
	k.rect(7, 11, 2, 3, "brown")
	k.rect(7, 14, 2, 1, "honey")
	k.outline("ink")
	c.stamp(k)
	return c
