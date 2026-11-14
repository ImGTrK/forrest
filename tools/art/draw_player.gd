extends SceneTree
## Rig del jugador por partes, "horneado" a una hoja de sprites.
##
## El personaje se arma con piezas (pelo + cara, torso, bufanda, mochila, brazos y piernas).
## Cada frame es una POSE: cuánto se corre el cuerpo y dónde quedan manos y pies. El script
## dibuja las piezas en esa pose con el pincel del bosque (luz arriba-izquierda, contorno ink)
## y pega el frame en la hoja. Sumar una animación = escribir sus poses en _pose().
##
## Uso:   godot --headless --path . --script res://tools/art/draw_player.gd
## Pisa assets/sprites/player/player.png.
##
## Hoja: 16 columnas × 9 filas de frames de 24×24 (se usa a escala 1: 1 px de la hoja = 1 px del juego).
##   Filas 0-7 = dirección: 0 S · 1 SW · 2 W · 3 NW · 4 N · 5 NE · 6 E · 7 SE
##     (SW, W y NW son el espejo de SE, E y NE)
##   Columnas: 0-3 quieto · 4-7 caminar · 8-11 ataque · 12-15 dash
##   Fila 8 = muerte: 0-3 cae con la cabeza a la izquierda · 4-7 espejo (cabeza a la derecha)

const PC := preload("res://tools/art/pixel_canvas.gd")
const OUT := "res://assets/sprites/player/player.png"
const F := 24
const COLS := 16
const ROWS := 9
const DEATH_ROW := 8
const DRAWN := {0: "S", 7: "SE", 6: "E", 5: "NE", 4: "N"}
const MIRROR := {1: 7, 2: 6, 3: 5}
const DIR_VEC := {
	"S": Vector2(0, 1), "SE": Vector2(0.71, 0.71), "E": Vector2(1, 0),
	"NE": Vector2(0.71, -0.71), "N": Vector2(0, -1),
}

# Paletas [luz, medio, sombra, sombra profunda]
const HAIR := ["hair_light", "hair", "hair_dark", "hair_dark"]
const SKIN := ["skin", "skin", "sand"]
const SHIRT := ["ivory", "cream", "sand", "path_shadow"]
const PANTS := ["bark", "brown", "brown_dark"]
const BOOTS := ["brown", "brown_dark", "plum"]
const SCARF := ["rose", "red", "red_dark"]
const BAG := ["wood_light", "bark", "brown", "brown_dark"]


func _init() -> void:
	var sheet := Image.create_empty(F * COLS, F * ROWS, false, Image.FORMAT_RGBA8)
	for row: int in DRAWN:
		for col in COLS:
			var fr: RefCounted = _figure(DRAWN[row], _pose(DRAWN[row], col))
			sheet.blit_rect(fr.img, Rect2i(0, 0, F, F), Vector2i(col * F, row * F))
	for row: int in MIRROR:
		for col in COLS:
			var img := sheet.get_region(Rect2i(col * F, int(MIRROR[row]) * F, F, F))
			img.flip_x()
			sheet.blit_rect(img, Rect2i(0, 0, F, F), Vector2i(col * F, row * F))
	for col in 4:
		var d := _death(col)
		sheet.blit_rect(d, Rect2i(0, 0, F, F), Vector2i(col * F, DEATH_ROW * F))
		var m := d.duplicate() as Image
		m.flip_x()
		sheet.blit_rect(m, Rect2i(0, 0, F, F), Vector2i((col + 4) * F, DEATH_ROW * F))
	var err := sheet.save_png(ProjectSettings.globalize_path(OUT))
	print("ok player" if err == OK else "error %d" % err)
	quit()


# =====================================================================================
# POSES — desplazamientos respecto de la pose de reposo
#   body: corre torso + cabeza + hombros (los pies quedan plantados)
#   head: extra solo para la cabeza
#   foot_f / foot_b: pie de adelante / de atrás (de perfil) o derecho / izquierdo (de frente)
#   hand_f / hand_b: mano de adelante (la que ataca) / de atrás, respecto de la mano en reposo
#   blink: ojos cerrados · scarf: cuánto flamea la bufanda (0-2)
# =====================================================================================

func _pose(dir: String, col: int) -> Dictionary:
	var d: Vector2 = DIR_VEC[dir]
	var side := dir != "S" and dir != "N"
	var p := {
		"body": Vector2.ZERO, "head": Vector2.ZERO, "foot_f": Vector2.ZERO, "foot_b": Vector2.ZERO,
		"hand_f": Vector2.ZERO, "hand_b": Vector2.ZERO, "blink": false, "scarf": 0,
	}
	var k := col % 4
	if col < 4:  # quieto: respira (la cabeza baja 1 px) y parpadea
		p.head = Vector2(0, 1) if k == 2 else Vector2.ZERO
		p.blink = k == 3
	elif col < 8:  # caminar: 2 pasos, el cuerpo sube en el paso intermedio
		p.body = Vector2(0, -1) if k % 2 == 1 else Vector2.ZERO
		if side:
			var s: float = [2.0, 0.0, -2.0, 0.0][k]
			p.foot_f = Vector2(s, 0)
			p.foot_b = Vector2(-s, 0)
			p.hand_f = Vector2(-s * 0.5, 0)
			p.hand_b = Vector2(s * 0.5, 0)
		else:
			if k == 0:
				p.foot_b = Vector2(0, -1)
				p.hand_f = Vector2(0, 1)
				p.hand_b = Vector2(0, -1)
			elif k == 2:
				p.foot_f = Vector2(0, -1)
				p.hand_b = Vector2(0, 1)
				p.hand_f = Vector2(0, -1)
		p.scarf = 1 if k % 2 == 1 else 0
	elif col < 12:  # ataque: carga atrás, estocada, sigue, vuelve
		var rest := Vector2(0, 4)  # la mano en reposo cuelga 4 px bajo el hombro
		match k:
			0:
				p.body = -d
				p.hand_f = -d * 2.0 + Vector2(0, -2) - rest
			1:
				p.body = d
				p.hand_f = d * 6.0 - rest
				p.foot_f = d
			2:
				p.body = d
				p.hand_f = d * 5.0 - rest
				p.foot_f = d
			3:
				p.hand_f = d * 3.0 - rest
		p.hand_b = -d
		p.scarf = 1
	else:  # dash: se agacha, se lanza inclinado con los brazos atrás, se endereza
		var lean: float = [1.0, 2.0, 2.0, 1.0][k]
		p.body = d * lean + (Vector2(0, 1) if k == 0 else Vector2.ZERO)
		p.foot_f = d
		p.foot_b = -d * (3.0 if k == 1 or k == 2 else 1.0)
		p.hand_f = -d * 2.0
		p.hand_b = -d * 2.0
		p.scarf = 2 if k == 1 or k == 2 else 1
	return p


# =====================================================================================
# FIGURA — arma un frame con las piezas en la pose dada
# =====================================================================================

## Geometría de reposo por dirección: torso, hombros y caderas.
func _rig(dir: String) -> Dictionary:
	match dir:
		"S", "N":
			return {"torso": Rect2i(9, 13, 7, 5), "sh_f": Vector2i(16, 14), "sh_b": Vector2i(7, 14),
				"hip_f": Vector2i(13, 18), "hip_b": Vector2i(10, 18)}
		"SE", "NE":
			return {"torso": Rect2i(9, 13, 6, 5), "sh_f": Vector2i(15, 14), "sh_b": Vector2i(8, 14),
				"hip_f": Vector2i(12, 18), "hip_b": Vector2i(10, 18)}
		_:  # E
			return {"torso": Rect2i(10, 13, 5, 5), "sh_f": Vector2i(12, 14), "sh_b": Vector2i(11, 14),
				"hip_f": Vector2i(12, 18), "hip_b": Vector2i(11, 18)}


func _figure(dir: String, p: Dictionary, shadow := true) -> RefCounted:
	var c: RefCounted = PC.new(F, F, 7)
	var r := _rig(dir)
	var body := Vector2i((p.body as Vector2).round())
	var side := dir != "S" and dir != "N"
	var from_back := dir == "N" or dir == "NE"
	if shadow:
		c.ground_shadow(12, 22.5, 5.5, 1.5)

	var sh_f: Vector2i = r.sh_f + body
	var sh_b: Vector2i = r.sh_b + body
	var hand_f := sh_f + Vector2i(0, 4) + Vector2i((p.hand_f as Vector2).round())
	var hand_b := sh_b + Vector2i(0, 4) + Vector2i((p.hand_b as Vector2).round())
	var hip_f: Vector2i = r.hip_f + Vector2i(0, body.y if body.y > 0 else 0) + Vector2i(body.x, 0)
	var hip_b: Vector2i = r.hip_b + Vector2i(0, body.y if body.y > 0 else 0) + Vector2i(body.x, 0)
	var foot_f: Vector2i = r.hip_f + Vector2i(0, 4) + Vector2i((p.foot_f as Vector2).round())
	var foot_b: Vector2i = r.hip_b + Vector2i(0, 4) + Vector2i((p.foot_b as Vector2).round())
	var torso: Rect2i = r.torso
	torso.position += body
	var scarf: int = p.scarf

	# --- Capa de atrás (de perfil): brazo y pierna lejanos, mochila y cola de la bufanda ---
	if side:
		var far: RefCounted = PC.new(F, F, 8)
		_leg(far, hip_b, foot_b)
		_arm(far, sh_b, hand_b)
		if dir == "E" or dir == "SE":
			_part(far, BAG, func(k: RefCounted) -> void:
				var w := 3 if dir == "E" else 2
				k.rect(torso.position.x - w, torso.position.y + 1, w + 1, 4, "bark"))
		_scarf_tail(far, dir, torso, scarf)
		far.outline("ink")
		c.stamp(far)

	# --- Cuerpo: piernas, torso, bufanda (y brazos de frente / mochila de espaldas) ---
	var bd: RefCounted = PC.new(F, F, 9)
	if not side:
		_leg(bd, hip_b, foot_b)
	_leg(bd, hip_f, foot_f)
	_part(bd, SHIRT, func(k: RefCounted) -> void:
		k.rect(torso.position.x, torso.position.y, torso.size.x, torso.size.y, "cream")
		_clear(k, torso.position.x, torso.position.y)
		_clear(k, torso.end.x - 1, torso.position.y))
	if from_back:
		_part(bd, BAG, func(k: RefCounted) -> void:
			var bx := torso.position.x + (1 if dir == "N" else 0)
			var bw := torso.size.x - (2 if dir == "N" else 2)
			k.rect(bx, torso.position.y, bw, 5, "bark"))
		bd.px(torso.position.x + torso.size.x / 2 - (0 if dir == "N" else 1), torso.position.y + 2, "gold")
	_part(bd, SCARF, func(k: RefCounted) -> void:
		k.rect(torso.position.x, torso.position.y - 1, torso.size.x, 2, "red"))
	if not side:
		_scarf_tail(bd, dir, torso, scarf)
	if dir == "S" or dir == "SE":  # tiras de la mochila
		bd.px(torso.position.x + 1, torso.position.y + 1, "brown")
		bd.px(torso.position.x + 1, torso.position.y + 2, "brown")
		if dir == "S":
			bd.px(torso.end.x - 2, torso.position.y + 1, "brown")
			bd.px(torso.end.x - 2, torso.position.y + 2, "brown")
	for x in range(torso.position.x, torso.end.x):  # cinturón
		bd.px(x, torso.end.y - 1, "brown_dark" if x != torso.position.x + torso.size.x / 2 else "gold")
	bd.outline("ink")
	c.stamp(bd)
	if from_back:  # brote de la mochila (asoma arriba a la derecha)
		var sx := torso.end.x - 2
		c.px(sx, torso.position.y - 2, "leaf")
		c.px(sx + 1, torso.position.y - 3, "leaf_light")
		c.px(sx - 1, torso.position.y - 3, "leaf_dark")
	elif side:
		c.px(torso.position.x - 2, torso.position.y - 1, "leaf")
		c.px(torso.position.x - 3, torso.position.y - 2, "leaf_light")

	# --- Brazos con su propio contorno (así se separan del torso) ---
	# de perfil solo el de adelante (el de atrás va en la capa lejana)
	var arms: RefCounted = PC.new(F, F, 10)
	if not side:
		_arm(arms, sh_b, hand_b)
	_arm(arms, sh_f, hand_f)
	arms.outline("ink")
	c.stamp(arms)

	# --- Cabeza ---
	var head := Vector2i((p.head as Vector2).round()) + body
	c.stamp(_head(dir, head, p.blink))
	return c


func _part(group: RefCounted, pal: Array, painter: Callable) -> void:
	var k: RefCounted = PC.new(F, F, 3)
	painter.call(k)
	k.shade(pal[0], pal[1], pal[2], pal[3] if pal.size() > 3 else null)
	group.stamp(k)


func _clear(k: RefCounted, x: int, y: int) -> void:
	k.px(x, y, Color(0, 0, 0, 0))


## Línea de 2 px de ancho.
func _thick(k: RefCounted, a: Vector2i, b: Vector2i, c: String) -> void:
	k.line(a.x, a.y, b.x, b.y, c)
	k.line(a.x + 1, a.y, b.x + 1, b.y, c)


## Pierna: pantalón y bota (las 2 últimas filas).
func _leg(group: RefCounted, hip: Vector2i, foot: Vector2i) -> void:
	_part(group, PANTS, func(k: RefCounted) -> void: _thick(k, hip, foot, "brown"))
	_part(group, BOOTS, func(k: RefCounted) -> void:
		var knee := Vector2i(lerpf(hip.x, foot.x, 0.6), maxi(foot.y - 1, hip.y))
		_thick(k, knee, foot, "brown_dark"))


## Brazo: manga corta y mano.
func _arm(group: RefCounted, sh: Vector2i, hand: Vector2i) -> void:
	var mid := Vector2i(roundi(lerpf(sh.x, hand.x, 0.4)), roundi(lerpf(sh.y, hand.y, 0.4)))
	_part(group, SKIN, func(k: RefCounted) -> void: _thick(k, mid, hand, "skin"))
	_part(group, SHIRT, func(k: RefCounted) -> void: _thick(k, sh, mid, "cream"))


## Cola de la bufanda: cuelga adelante de frente y flamea hacia atrás de perfil.
func _scarf_tail(group: RefCounted, dir: String, torso: Rect2i, flutter: int) -> void:
	var top := torso.position
	var a := Vector2i(top.x, top.y - 1)
	var tails: Array[Vector2i] = [Vector2i(-2, 3), Vector2i(-3, 2), Vector2i(-5, 0)]
	var b: Vector2i = a + tails[flutter]
	if dir == "S":
		a = Vector2i(torso.end.x - 3, top.y)
		b = a + Vector2i(1 + flutter, 3 - flutter)
	elif dir == "N":
		a = Vector2i(top.x + 2, top.y)
		b = a + Vector2i(-flutter, 3 - flutter)
	_part(group, SCARF, func(k: RefCounted) -> void: _thick(k, a, b, "red"))


func _head(dir: String, off: Vector2i, blink: bool) -> RefCounted:
	var k: RefCounted = PC.new(F, F, 11)
	var cx := 12.0 + off.x
	var cy := 7.3 + off.y
	var ix := 12 + off.x
	var iy := 7 + off.y
	k.ellipse(cx, cy, 5.5, 4.7, "hair")
	# remolino arriba y mechones a los costados (el de atrás más largo de perfil)
	k.px(ix, iy - 5, "hair")
	k.px(ix + 1, iy - 6, "hair")
	k.px(ix - 1, iy - 5, "hair")
	if dir == "S" or dir == "N":
		for y in range(iy + 2, iy + 5):
			k.px(ix - 6, y, "hair")
			k.px(ix + 5, y, "hair")
	else:
		for y in range(iy + 1, iy + 6):
			k.px(ix - 6, y, "hair")
		k.px(ix - 5, iy + 5, "hair")
	k.shade(HAIR[0], HAIR[1], HAIR[2], HAIR[3])

	# cara: elipse de piel recortada por el pelo y el flequillo
	var face := {"S": [0.0, 4.2], "SE": [2.0, 3.8], "E": [2.8, 3.0], "NE": [4.3, 1.4]}
	if face.has(dir):
		var fcx: float = cx + float(face[dir][0])
		var frx: float = face[dir][1]
		var f: RefCounted = PC.new(F, F, 12)
		f.ellipse(fcx, cy + 2.4, frx, 3.0, "skin")
		for y in F:
			for x in F:
				if not f.solid(x, y):
					continue
				var bang := iy + 1 + (1 if posmod(x - ix, 3) == 0 else 0)
				if not k.solid(x, y) or y < bang or (dir == "NE" and y < iy + 2):
					_clear(f, x, y)
		# Piel plana con sombra solo en el mentón: si se sombrea por bordes, los recortes del
		# pelo la oscurecen y la cara "desaparece" (en diagonal parecía mirar al otro lado)
		for x in F:
			for y in range(F - 1, -1, -1):
				if f.solid(x, y):
					f.px(x, y, "sand")
					break
		k.stamp(f)
		var ey := iy + 2
		var eyes: Array = {"S": [ix - 2, ix + 1], "SE": [ix + 1, ix + 4], "E": [ix + 3], "NE": []}[dir]
		for ex: int in eyes:
			k.px(ex, ey + 1, "ink")
			if not blink:
				k.px(ex, ey, "ink")
		var cheeks: Array = {"S": [ix - 3, ix + 2], "SE": [ix, ix + 4], "E": [ix + 2], "NE": [ix + 4]}[dir]
		for chx: int in cheeks:
			k.px(chx, ey + 2, "blush")
	k.outline("ink")
	return k


# =====================================================================================
# MUERTE — de frente se encoge y cae; tendido = el perfil rotado 90° (sin perder píxeles)
# =====================================================================================

func _death(k: int) -> Image:
	var c: RefCounted = PC.new(F, F, 21)
	if k == 0:  # el golpe: brazos arriba, ojos cerrados
		var p := _pose("S", 0)
		p.body = Vector2(0, -1)
		p.hand_f = Vector2(1, -7)
		p.hand_b = Vector2(-1, -7)
		p.blink = true
		p.scarf = 2
		return _figure("S", p).img
	if k == 1:  # se le aflojan las rodillas
		var p := _pose("S", 0)
		p.body = Vector2(0, 2)
		p.hand_f = Vector2(1, 0)
		p.hand_b = Vector2(-1, 0)
		p.blink = true
		return _figure("S", p).img
	var p := _pose("E", 0)
	p.blink = true
	p.scarf = 1
	var fig: Image = (_figure("E", p, false).img as Image).duplicate()
	fig.rotate_90(COUNTERCLOCKWISE)  # cabeza a la izquierda, boca arriba
	c.ground_shadow(12, 21.5, 10.0, 1.6)
	c.stamp_image(fig, 0, 4)
	if k == 3:  # polvito
		c.px(3, 20, "sand")
		c.px(21, 19, "sand")
		c.px(20, 21, "cream")
	return c.img
