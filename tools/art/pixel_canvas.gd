extends RefCounted
## Lienzo de pixel art por código (sin antialiasing, sin reescalar). Lo usa tools/art/draw_world.gd.
##
## Idea de trabajo: cada forma se dibuja en su propio lienzo como una "máscara" de un color,
## después shade() la ilumina desde arriba a la izquierda según sus bordes, se le agrega textura,
## se le pone contorno de 1 px y recién ahí se pega sobre el lienzo final con stamp().

## Paleta Forrest (assets/PALETA_FORREST.gpl) + los tonos de agua que suma la 0.2.
const P := {
	"ink": "211C2B", "plum": "3B2D45", "brown_dark": "4B373B", "brown": "744B46",
	"bark": "9A6550", "wood_light": "D1996D", "grass_dark": "5E8869", "grass": "84AB78",
	"grass_light": "B8D18E", "leaf_dark": "2B6653", "leaf": "4C9465", "leaf_light": "90C57B",
	"pale_leaf": "D4E2A1", "cream": "F6E3BE", "ivory": "FFF1D6", "sand": "E8C69C",
	"path": "D8AD82", "path_shadow": "B88064", "blush": "F2BAC5", "rose": "E390A8",
	"red": "D34B55", "red_dark": "963D4D", "stone_dark": "596574", "stone": "939DA6",
	"stone_light": "D0D2D1", "iron": "47738A", "iron_light": "93BDCE", "gold": "E5BA6B",
	"gold_light": "FFE1A0", "white": "F4F0E8", "jade_deep": "245848", "jade_bright": "72B36C",
	"leaf_sun": "B9D88B", "flower_light": "FFE0DE", "flower_pink": "F8A9BC", "ore_blue": "376E96",
	"ore_glint": "80C9E8", "honey": "D4A258", "hair_dark": "2E253A", "hair": "52364F",
	"hair_light": "80566E", "skin": "F5CBA3",
	# Nuevos (0.2): agua de estanque, jade frío para que no compita con el pasto
	"water_deep": "2F5E6E", "water": "4F8C94", "water_light": "8CC4BE", "foam": "D6EEE4",
	"moss": "6E9A5A", "ember": "F28C4A", "flame": "FFD27A",
}

var w: int
var h: int
var img: Image
var rng := RandomNumberGenerator.new()


func _init(p_w: int, p_h: int, seed_value := 1) -> void:
	w = p_w
	h = p_h
	img = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	rng.seed = seed_value


static func col(name_or_color: Variant, alpha := 1.0) -> Color:
	var c: Color = name_or_color if name_or_color is Color else Color.html(P[name_or_color])
	c.a = alpha
	return c


func new_layer() -> RefCounted:
	var layer: RefCounted = get_script().new(w, h, rng.randi())
	return layer


# --- Primitivas -----------------------------------------------------------------

func inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < w and y < h


func px(x: int, y: int, c: Variant) -> void:
	if inside(x, y):
		img.set_pixel(x, y, col(c) if not (c is Color) else c)


func get_px(x: int, y: int) -> Color:
	return img.get_pixel(x, y) if inside(x, y) else Color(0, 0, 0, 0)


func solid(x: int, y: int) -> bool:
	return get_px(x, y).a > 0.5


func rect(x: int, y: int, rw: int, rh: int, c: Variant) -> void:
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			px(xx, yy, c)


## Elipse rellena centrada en (cx, cy) con radios en píxeles (acepta medios).
func ellipse(cx: float, cy: float, rx: float, ry: float, c: Variant) -> void:
	for yy in range(floori(cy - ry) - 1, ceili(cy + ry) + 1):
		for xx in range(floori(cx - rx) - 1, ceili(cx + rx) + 1):
			var dx := (xx + 0.5 - cx) / rx
			var dy := (yy + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				px(xx, yy, c)


func disc(cx: float, cy: float, r: float, c: Variant) -> void:
	ellipse(cx, cy, r, r, c)


func line(x0: int, y0: int, x1: int, y1: int, c: Variant) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		px(x0, y0, c)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


func poly(points: PackedVector2Array, c: Variant) -> void:
	var r := Rect2(points[0], Vector2.ZERO)
	for p in points:
		r = r.expand(p)
	for yy in range(floori(r.position.y), ceili(r.end.y) + 1):
		for xx in range(floori(r.position.x), ceili(r.end.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(xx + 0.5, yy + 0.5), points):
				px(xx, yy, c)


## Sombra suave en el piso (ciruela transparente).
func ground_shadow(cx: float, cy: float, rx: float, ry: float, alpha := 0.32) -> void:
	var c := col("plum", alpha)
	for yy in range(floori(cy - ry) - 1, ceili(cy + ry) + 1):
		for xx in range(floori(cx - rx) - 1, ceili(cx + rx) + 1):
			var dx := (xx + 0.5 - cx) / rx
			var dy := (yy + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0 and get_px(xx, yy).a < 0.01:
				px(xx, yy, c)


# --- Luz, textura y contorno ------------------------------------------------------

## Ilumina una máscara: borde de arriba-izquierda = light, borde de abajo-derecha = dark
## (con un segundo escalón `deep` más adentro). Solo toca píxeles opacos.
func shade(light: Variant, mid: Variant, dark: Variant, deep: Variant = null, light2: Variant = null) -> void:
	var src := img.duplicate() as Image
	var is_in := func(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < w and y < h and src.get_pixel(x, y).a > 0.5
	for y in h:
		for x in w:
			if not is_in.call(x, y):
				continue
			var c: Variant = mid
			var up_left: bool = not is_in.call(x - 1, y) or not is_in.call(x, y - 1)
			var down_right: bool = not is_in.call(x + 1, y) or not is_in.call(x, y + 1)
			var down_right2: bool = not is_in.call(x + 2, y + 1) or not is_in.call(x + 1, y + 2)
			if down_right:
				c = deep if deep != null else dark
			elif down_right2:
				c = dark
			elif up_left:
				c = light
			elif light2 != null and (not is_in.call(x - 2, y - 1) or not is_in.call(x - 1, y - 2)):
				c = light2
			img.set_pixel(x, y, col(c))


## Manchitas de textura (grupos de 1-3 px) dentro de lo opaco. bias < 0 = hacia arriba-izquierda.
func speckle(count: int, c: Variant, size := 2, bias := 0.0, only_on: Variant = null) -> void:
	for i in count:
		var x := rng.randi_range(0, w - 1)
		var y := rng.randi_range(0, h - 1)
		if bias != 0.0 and rng.randf() < absf(bias):
			# Reintento sesgado: en sombras busca abajo-derecha, en luces arriba-izquierda
			var tx := rng.randi_range(0, w - 1)
			var ty := rng.randi_range(0, h - 1)
			if (bias < 0.0 and tx + ty < x + y) or (bias > 0.0 and tx + ty > x + y):
				x = tx
				y = ty
		for j in size:
			var xx := x + (j % 2)
			var yy := y + (j / 2)
			if solid(xx, yy) and (only_on == null or get_px(xx, yy).is_equal_approx(col(only_on))):
				px(xx, yy, c)


## Contorno de 1 px alrededor de todo lo opaco (vecinos en cruz).
func outline(c: Variant, diagonals := false) -> void:
	var src := img.duplicate() as Image
	var oc := col(c)
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.5:
				continue
			var hit := false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = Vector2i(x, y) + d
				if n.x >= 0 and n.y >= 0 and n.x < w and n.y < h and src.get_pixel(n.x, n.y).a > 0.5:
					hit = true
			if diagonals and not hit:
				for d in [Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
					var n: Vector2i = Vector2i(x, y) + d
					if n.x >= 0 and n.y >= 0 and n.x < w and n.y < h and src.get_pixel(n.x, n.y).a > 0.5:
						hit = true
			if hit:
				img.set_pixel(x, y, oc)


## Pega otra capa encima (respeta transparencia), con desplazamiento.
func stamp(layer: RefCounted, ox := 0, oy := 0) -> void:
	img.blend_rect(layer.img, Rect2i(0, 0, layer.w, layer.h), Vector2i(ox, oy))


## Pega una imagen de disco (ej. un sprite aprobado) en (ox, oy).
func stamp_image(src: Image, ox := 0, oy := 0, region := Rect2i()) -> void:
	var r := region if region.has_area() else Rect2i(0, 0, src.get_width(), src.get_height())
	var s := src.duplicate() as Image
	s.convert(Image.FORMAT_RGBA8)
	img.blend_rect(s, r, Vector2i(ox, oy))


## Florcita de cerezo: 4 pétalos + centro (5 px), o 1-2 px si `tiny`.
func blossom(x: int, y: int, petal: Variant = "flower_pink", center: Variant = "flower_light", tiny := false) -> void:
	if tiny:
		px(x, y, petal)
		px(x + 1, y, center)
		return
	for d in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]:
		px(x + d.x, y + d.y, petal)
	px(x, y, center)


func save(path: String) -> void:
	var err := img.save_png(path)
	if err != OK:
		push_error("No se pudo guardar %s" % path)
