extends SceneTree
## Sprites del juego (ítems, herramientas, props del pueblo, UI y enemigo) dibujados por código
## con el mismo pincel que el bosque (tools/art/pixel_canvas.gd): paleta Forrest, luz desde
## arriba a la izquierda, contorno de 1 px. Objetos usables y actores: contorno "ink".
##
## Uso:   godot --headless --path . --script res://tools/art/draw_sprites.gd [-- solo=items,props,ui,enemy]
## `enemy` también genera la espora y la espada del swing.
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
	_save(_ore_item("copper"), "items/copper.png")
	_save(_axe("copper"), "items/copper_axe.png")
	_save(_pickaxe("copper"), "items/copper_pickaxe.png")
	_save(_sword_item("copper"), "items/copper_sword.png")
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
	match mat:
		"stone":
			return ["stone_light", "stone", "stone_dark", "plum"]
		"copper":
			return ["copper_light", "copper", "copper_dark", "brown_dark"]
		"wood":
			return ["cream", "wood_light", "bark", "brown"]
	return ["white", "iron_light", "iron", "ore_blue"]


## Mineral en bruto (cobre): piedra con vetas del metal y una manchita de pátina.
func _ore_item(mat: String) -> RefCounted:
	var c := _layer(16, 16, 17)
	var k := _layer(16, 16, 18)
	k.poly(PackedVector2Array([Vector2(2, 11), Vector2(3, 6), Vector2(7, 3), Vector2(12, 4), Vector2(14, 9), Vector2(12, 14), Vector2(4, 14)]), "stone_dark")
	k.shade("stone", "stone_dark", "plum", "plum")
	var m := _metal(mat)
	for p in [Vector2i(4, 9), Vector2i(5, 8), Vector2i(5, 9), Vector2i(6, 8), Vector2i(8, 5), Vector2i(9, 5), Vector2i(9, 6), Vector2i(10, 6), Vector2i(7, 11), Vector2i(8, 11), Vector2i(8, 12), Vector2i(11, 9), Vector2i(12, 9)]:
		k.px(p.x, p.y, m[1])
	for p in [Vector2i(5, 8), Vector2i(8, 5), Vector2i(7, 11), Vector2i(11, 9)]:
		k.px(p.x, p.y, m[0])
	k.px(10, 6, m[2])
	k.px(12, 11, "patina")
	k.px(4, 10, "patina")
	k.outline("ink")
	c.stamp(k)
	return c


func _axe(mat: String) -> RefCounted:
	var c := _layer(16, 32, 21)
	var k := _layer(16, 32, 22)
	_handle(k, 7, 6, 29)
	k.rect(6, 10, 4, 2, "cream" if mat == "stone" else "stone_dark")  # atadura / abrazadera
	var m := _metal(mat)
	var head := _layer(16, 32, 23)
	if mat == "stone":
		head.poly(PackedVector2Array([Vector2(8, 3), Vector2(12, 2), Vector2(15, 5), Vector2(15, 10), Vector2(12, 12), Vector2(8, 11)]), m[1])
	elif mat == "copper":  # hoja ancha y redondeada
		head.poly(PackedVector2Array([Vector2(8, 4), Vector2(12, 3), Vector2(15, 4), Vector2(15, 12), Vector2(12, 11), Vector2(8, 10)]), m[1])
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
	var m := _metal(mat)
	var metal := mat != "wood"
	# hoja
	k.poly(PackedVector2Array([Vector2(8, 1), Vector2(10, 3), Vector2(10, 20), Vector2(6, 20), Vector2(6, 3)]), m[1])
	k.shade(m[0], m[1], m[2], m[3])
	k.line(8, 3, 8, 19, m[0] if metal else m[1])  # canal
	k.line(9, 4, 9, 19, m[2])
	# guarda y mango
	k.rect(3, 20, 10, 2, "honey" if metal else "brown")
	k.px(3, 20, "gold_light" if metal else "bark")
	k.rect(7, 22, 2, 6, "brown")
	for y in range(22, 28, 2):
		k.px(7, y, "bark")
	k.rect(6, 28, 4, 2, "honey" if metal else "bark")  # pomo
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
	_save(_iron_vein("copper"), "world/copper_vein.png")


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
func _iron_vein(mat := "iron") -> RefCounted:
	var c := _layer(16, 16, 111)
	c.ground_shadow(8, 13.5, 6.5, 2.0)
	var k := _layer(16, 16, 112)
	k.poly(PackedVector2Array([Vector2(2, 13), Vector2(2, 9), Vector2(5, 5), Vector2(9, 4), Vector2(13, 7), Vector2(14, 13)]), "stone")
	k.shade("stone_light", "stone", "stone_dark", "stone_dark", PC.col("stone").lerp(PC.col("stone_light"), 0.5))
	var ore := "copper" if mat == "copper" else "ore_blue"
	var glint := "copper_light" if mat == "copper" else "ore_glint"
	for p in [Vector2i(5, 8), Vector2i(6, 8), Vector2i(6, 9), Vector2i(9, 6), Vector2i(10, 7), Vector2i(10, 8), Vector2i(8, 11), Vector2i(9, 11), Vector2i(12, 10)]:
		k.px(p.x, p.y, ore)
	for p in [Vector2i(6, 8), Vector2i(10, 7), Vector2i(9, 11)]:
		k.px(p.x, p.y, glint)
	if mat == "copper":
		k.px(4, 11, "patina")
		k.px(12, 9, "patina")
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
# ENEMIGOS — hoja estándar de 64×64: 4×4 frames de 16×16, mirando a la derecha.
#   fila 0 quieto · fila 1 moverse · fila 2 amago (cols 0-1) + golpe (cols 2-3) · fila 3 muerte
# El rojo intenso es peligro: cuerpo del erizo, ojo del embestidor, boquilla del lanzador.
# =====================================================================================

func _enemy() -> void:
	_save(_sheet(_hog_frames()), "enemies/enemy_basic.png")
	_save(_sheet(_shroom_frames()), "enemies/enemy_spitter.png")
	_save(_sheet(_boar_frames()), "enemies/enemy_charger.png")
	_save(_spore(), "enemies/spore.png")
	_save(_swing_sword(), "player/sword.png")


func _sheet(frames: Array) -> RefCounted:
	var c := _layer(64, 64, 180)
	for i in frames.size():
		c.stamp(frames[i], (i % 4) * 16, (i / 4) * 16)
	return c


func _clear(k: RefCounted, x: int, y: int) -> void:
	k.px(x, y, Color(0, 0, 0, 0))


## Ojo en X (muerto).
func _x_eye(k: RefCounted, x: int, y: int) -> void:
	k.px(x - 1, y - 1, "ink")
	k.px(x + 1, y - 1, "ink")
	k.px(x, y, "ink")
	k.px(x - 1, y + 1, "ink")
	k.px(x + 1, y + 1, "ink")


# --- Erizo-fruta (enemigo básico) -------------------------------------------------

func _hog_frames() -> Array:
	return [
		_hog({}), _hog({"sy": 0.94}), _hog({"blink": true}), _hog({"sy": 0.97}),
		_hog({"sy": 0.92, "sx": 1.06}), _hog({"dy": -1.0, "sy": 1.05}), _hog({"dy": -2.0}), _hog({"dy": -1.0}),
		_hog({"sy": 0.86, "sx": 1.1, "dx": -1.0}), _hog({"sy": 0.8, "sx": 1.14, "dx": -1.0}),
		_hog({"dx": 2.0, "sx": 1.08, "bite": true}), _hog({"dx": 1.0, "bite": true}),
		_hog({"sy": 0.8, "sx": 1.08, "dead": 1}), _hog({"sy": 0.6, "sx": 1.2, "dead": 2}),
		_hog({"sy": 0.42, "sx": 1.25, "dead": 3}), _hog({"sy": 0.3, "sx": 1.2, "dead": 4}),
	]


func _hog(o: Dictionary) -> RefCounted:
	var dx: float = o.get("dx", 0.0)
	var dy: float = o.get("dy", 0.0)
	var sx: float = o.get("sx", 1.0)
	var sy: float = o.get("sy", 1.0)
	var dead: int = o.get("dead", 0)
	var c := _layer(16, 16, 191)
	c.ground_shadow(8, 14.5, 6.0 * sx, 1.4, 0.32 if dy > -1.5 else 0.22)
	var rx := 5.5 * sx
	var ry := 4.6 * sy
	var cx := 7.0 + dx
	var cy := 14.1 - ry + dy
	var at := func(ox: float, oy: float) -> Vector2i:
		return Vector2i(roundi(cx + ox * sx), roundi(cy + oy * sy))
	var body := _layer(16, 16, 192)
	body.ellipse(cx, cy, rx, ry, "red")
	# púas en el lomo (se van cayendo al morir)
	var spikes := [Vector2(-5, -3.5), Vector2(-3, -5.5), Vector2(0, -6.5), Vector2(3, -5.5), Vector2(-6, -0.5)]
	if dead >= 2:
		spikes = [Vector2(-3, -5.5), Vector2(1, -6.5)]
	if dead >= 4:
		spikes = []
	for s: Vector2 in spikes:
		var p: Vector2i = at.call(s.x, s.y)
		body.px(p.x, p.y, "red")
		body.px(p.x + 1, p.y, "red")
		body.px(p.x, p.y - 1, "red")
	body.shade("rose", "red", "red_dark", "red_dark")
	# cara rosada a la derecha
	if dead < 4:
		body.ellipse(cx + 4.5 * sx, cy + 0.5 * sy, 3.0 * sx, maxf(2.6 * sy, 1.2), "blush")
		var snout: Vector2i = at.call(7, 0.5)
		body.px(snout.x, snout.y, "blush")
		var nose: Vector2i = at.call(7, 1.5)
		body.px(nose.x, nose.y, "rose")
		var eye: Vector2i = at.call(5, -0.5)
		if dead > 0:
			_x_eye(body, eye.x, eye.y)
		elif o.get("blink", false):
			body.line(eye.x - 1, eye.y, eye.x, eye.y, "ink")
		else:
			body.px(eye.x, eye.y, "ink")
			body.px(eye.x, eye.y - 1, "ink")
			body.px(eye.x - 1, eye.y - 1, "white")
		var cheek: Vector2i = at.call(3, 1.5)
		body.px(cheek.x, cheek.y, "rose")
		if o.get("bite", false):  # boca abierta con dientito
			var m: Vector2i = at.call(6.5, 2.0)
			body.px(m.x, m.y, "ink")
			body.px(m.x + 1, m.y, "ink")
			body.px(m.x + 1, m.y - 1, "white")
	# patitas
	if dead == 0:
		var lift := 1 if dy < -1.5 else 0
		body.px(roundi(cx - 3), roundi(cy + ry) - lift, "red_dark")
		body.px(roundi(cx + 2), roundi(cy + ry) - lift, "red_dark")
	body.outline("ink")
	c.stamp(body)
	# hojitas en la cabeza (es una fruta); al morir se caen al costado
	var leaf: Vector2i = at.call(0, -7.5) if dead < 3 else Vector2i(roundi(cx + 7), 13)
	c.px(leaf.x, leaf.y, "leaf")
	c.px(leaf.x + 1, leaf.y - 1, "leaf_light")
	c.px(leaf.x - 1, leaf.y - 1, "leaf_dark")
	return c


# --- Lanzador: hongo bufón de sombrero ciruela con boquilla roja -------------------

func _shroom_frames() -> Array:
	return [
		_shroom({}), _shroom({"dy": 0.0, "inflate": 0.3}), _shroom({"blink": true}), _shroom({"inflate": 0.3}),
		_shroom({"lean": 1.0, "dy": -1.0}), _shroom({"lean": 0.0, "dy": 0.0}), _shroom({"lean": -1.0, "dy": -1.0}), _shroom({}),
		_shroom({"inflate": 0.6}), _shroom({"inflate": 1.0}),
		_shroom({"squish": 1.0, "lean": 1.0, "puff": 2}), _shroom({"squish": 0.5, "puff": 1}),
		_shroom({"squish": 1.0, "dead": 1}), _shroom({"squish": 1.5, "lean": 2.0, "dead": 2}),
		_shroom({"squish": 2.0, "lean": 3.0, "dead": 3}), _shroom({"dead": 4}),
	]


func _shroom(o: Dictionary) -> RefCounted:
	var dy: float = o.get("dy", 0.0)
	var lean: float = o.get("lean", 0.0)
	var inflate: float = o.get("inflate", 0.0)
	var squish: float = o.get("squish", 0.0)
	var dead: int = o.get("dead", 0)
	var c := _layer(16, 16, 301)
	c.ground_shadow(8, 14.5, 5.0 + inflate * 0.5, 1.3)
	if dead >= 4:  # solo queda el sombrero tirado y esporas
		var rest := _layer(16, 16, 309)
		rest.ellipse(8, 13, 5, 1.8, "hair")
		rest.shade("hair_light", "hair", "hair_dark", "ink")
		rest.px(6, 12, "blush")
		rest.outline("ink")
		c.stamp(rest)
		for p in [Vector2i(3, 9), Vector2i(12, 8), Vector2i(10, 6)]:
			c.px(p.x, p.y, "pale_leaf")
		return c
	# tallo con carita
	var stem_h := 6 - dead
	var top := 14 - stem_h
	var stem := _layer(16, 16, 302)
	stem.rect(5, top, 6, stem_h, "cream")
	stem.rect(6, 14, 4, 1, "cream")
	stem.shade("ivory", "cream", "sand", "path_shadow")
	# carita debajo del sombrero (el borde del sombrero tapa las filas top..top+2)
	if dead > 0:
		stem.px(8, top + 3, "ink")
		stem.px(10, top + 3, "ink")
	elif o.get("blink", false):
		stem.line(7, top + 3, 8, top + 3, "ink")
		stem.line(10, top + 3, 11, top + 3, "ink")
	else:
		stem.px(8, top + 3, "ink")
		stem.px(10, top + 3, "ink")
		stem.px(8, top + 4, "ink")
		stem.px(10, top + 4, "ink")
	stem.px(11, top + 4, "blush")  # cachete
	stem.outline("ink")
	c.stamp(stem)
	# sombrero: domo con la base plana
	var cap := _layer(16, 16, 303)
	var crx := 6.5 + inflate
	var cry := 4.2 + inflate * 0.7 - squish
	var ccx := 8.0 + lean
	var ccy := float(top) + 0.5 + dy - (0.0 if dead == 0 else -float(dead))
	cap.ellipse(ccx, ccy, crx, cry, "hair")
	for y in range(roundi(ccy + 1), 16):
		for x in 16:
			_clear(cap, x, y)
	cap.shade("hair_light", "hair", "hair_dark", "ink")
	# lunares
	for s in [Vector2(-3, -2), Vector2(1, -3), Vector2(-1, -0.5)]:
		cap.px(roundi(ccx + s.x * (1.0 + inflate * 0.15)), roundi(ccy + s.y * (1.0 + inflate * 0.12)), "blush")
	cap.px(roundi(ccx - 4), roundi(ccy - 1), "flower_light")
	# boquilla roja hacia adelante (de ahí sale la espora)
	var sp := Vector2i(roundi(ccx + crx - 1), roundi(ccy - 1))
	if dead == 0:
		cap.px(sp.x, sp.y, "red")
		cap.px(sp.x + 1, sp.y, "red_dark")
		cap.px(sp.x, sp.y - 1, "red")
	# borde de las laminillas
	cap.line(roundi(ccx - crx + 1), roundi(ccy), roundi(ccx + crx - 1), roundi(ccy), "rose")
	cap.outline("ink")
	c.stamp(cap)
	var puff: int = o.get("puff", 0)
	if puff > 0:
		c.px(sp.x + 2, sp.y, "pale_leaf")
		c.px(sp.x + 3, sp.y - 1, "leaf_sun")
		if puff > 1:
			c.px(sp.x + 3, sp.y + 1, "pale_leaf")
			c.px(sp.x + 4, sp.y, "cream")
	return c


# --- Embestidor: jabalí-escarabajo de caparazón marrón, cuerno crema y ojo rojo -------

func _boar_frames() -> Array:
	return [
		_boar({}), _boar({"sy": 0.95}), _boar({"dy": 0.0}), _boar({"sy": 0.95}),
		_boar({"legs": 1}), _boar({"legs": 2, "dy": -1.0}), _boar({"legs": 3}), _boar({"legs": 0, "dy": -1.0}),
		_boar({"down": 1, "legs": 1}), _boar({"down": 2, "legs": 3}),
		_boar({"down": 2, "sx": 1.12, "sy": 0.9, "legs": 2}), _boar({"down": 2, "sx": 1.12, "sy": 0.9, "legs": 0}),
		_boar({"dead": 1, "sy": 0.9}), _boar({"dead": 2, "dy": -2.0}), _boar({"dead": 3}), _boar({"dead": 3, "sy": 0.85}),
	]


func _boar(o: Dictionary) -> RefCounted:
	var dy: float = o.get("dy", 0.0)
	var sx: float = o.get("sx", 1.0)
	var sy: float = o.get("sy", 1.0)
	var down: int = o.get("down", 0)
	var legs: int = o.get("legs", 0)
	var dead: int = o.get("dead", 0)
	var c := _layer(16, 16, 401)
	c.ground_shadow(8, 14.5, 7.0 * sx, 1.5)
	var k := _layer(16, 16, 402)
	var on_back := dead >= 2
	var rx := 5.8 * sx
	var ry := 4.3 * sy
	var cx := 7.0 - (1.0 if down > 0 else 0.0)
	var cy := 12.6 - ry + dy + (0.5 * down)
	# patas (detrás del cuerpo): 3 visibles, alternan al trotar; patas arriba si está boca arriba
	var lx := [roundi(cx - 3), roundi(cx), roundi(cx + 3)]
	for i in 3:
		if on_back:
			k.line(lx[i], roundi(cy - ry), lx[i] + (1 if i % 2 == 0 else -1), roundi(cy - ry) - 2, "ink")
		else:
			var long := 2 if (i + legs) % 2 == 0 else 1
			if down > 1 and i == 2:
				long = 2
			k.line(lx[i], roundi(cy + ry - 1), lx[i] + (1 if legs % 2 == 1 and i != 1 else 0), mini(roundi(cy + ry) + long - 1, 14), "ink")
	var shell := _layer(16, 16, 403)
	shell.ellipse(cx, cy, rx, ry, "brown")
	shell.shade("bark", "brown", "brown_dark", "plum", "wood_light" if not on_back else null)
	# surcos del caparazón
	var seam_y := roundi(cy + (1 if on_back else -1))
	for x in range(roundi(cx - rx + 2), roundi(cx + rx - 1)):
		if x % 3 != 0:
			shell.px(x, seam_y, "brown_dark")
	if not on_back:
		shell.px(roundi(cx - 2), roundi(cy - ry + 1), "wood_light")
		shell.px(roundi(cx - 1), roundi(cy - ry + 1), "sand")
	k.stamp(shell)
	# cabeza con cuerno (baja al raspar y embestir)
	var hx := cx + rx - 0.5
	var hy := cy + 0.5 + down * 0.8
	if on_back:
		hy = cy + 1.5
	var head := _layer(16, 16, 404)
	head.ellipse(hx, hy, 3.0, 2.6, "brown_dark")
	head.shade("brown", "brown_dark", "plum", "ink")
	var ex := roundi(hx)
	var ey := roundi(hy - 1)
	if dead > 0:
		head.px(ex, ey, "ink")
		head.px(ex + 1, ey + 1, "ink")
		head.px(ex + 1, ey - 1, "ink")
	else:
		head.px(ex, ey, "red")
		head.px(ex + 1, ey, "flame" if down > 1 else "red")
	k.stamp(head)
	# cuerno: hacia arriba en reposo, hacia adelante al embestir
	var tip := Vector2i(roundi(hx + 3), roundi(hy - 1))
	if down > 1:
		k.px(tip.x, tip.y + 1, "cream")
		k.px(tip.x + 1, tip.y + 1, "ivory")
		k.px(tip.x + 2, tip.y + 1, "ivory")
	elif not on_back:
		k.px(tip.x, tip.y, "cream")
		k.px(tip.x, tip.y - 1, "ivory")
		k.px(tip.x + 1, tip.y - 2, "ivory")
	else:
		k.px(tip.x, tip.y + 2, "cream")
		k.px(tip.x + 1, tip.y + 3, "ivory")
	k.outline("ink")
	c.stamp(k)
	return c


## Espora del Lanzador: 2 frames de 8×8 (late un poco).
func _spore() -> RefCounted:
	var c := _layer(16, 8, 501)
	for f in 2:
		var k := _layer(8, 8, 502 + f)
		var r := 2.4 if f == 0 else 2.0
		k.disc(4, 4, r, "pale_leaf")
		k.shade("cream", "pale_leaf", "leaf_sun", "jade_bright")
		k.px(3, 3, "ivory")
		k.outline("leaf_dark")
		if f == 1:
			k.px(1, 1, "pale_leaf")
			k.px(6, 6, "leaf_sun")
		c.stamp(k, f * 8, 0)
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
