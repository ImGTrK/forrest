extends SceneTree
## Arma una escena de muestra (640×360, como el juego) con el arte de la 0.2 y la guarda en
## docs/PREVIEW_ARTE_V02.png (1×) y docs/PREVIEW_ARTE_V02_2X.png. No usa el generador real:
## es una composición a mano para revisar estilo, escala y legibilidad.
## godot --headless --path . --script res://tools/art/preview_v02.gd

const T := 16
const W := 40
const H := 22

var img: Image
var terrain: Image
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 2026
	img = Image.create_empty(W * T, H * T, false, Image.FORMAT_RGBA8)
	terrain = _load("tilesets/terrain.png")
	# Capa de materiales por celda (después se resuelven las piezas de borde)
	var mat := []
	for y in H:
		var row := []
		for x in W:
			row.append("grass")
		mat.append(row)
	var paint := func(cells: Array, m: String) -> void:
		for cl: Vector2i in cells:
			if cl.x >= 0 and cl.y >= 0 and cl.x < W and cl.y < H:
				mat[cl.y][cl.x] = m
	var rect_cells := func(x0: int, y0: int, w: int, h: int) -> Array:
		var out := []
		for y in range(y0, y0 + h):
			for x in range(x0, x0 + w):
				out.append(Vector2i(x, y))
		return out
	var blob := func(cx: float, cy: float, rx: float, ry: float) -> Array:
		var out := []
		for y in H:
			for x in W:
				if Vector2((x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry).length() <= 1.0:
					out.append(Vector2i(x, y))
		return out
	# Borde de cerco (2 tiles de grosor para que se vean las transiciones)
	for y in H:
		for x in W:
			if x < 2 or y < 2 or x >= W - 2 or y >= H - 2:
				mat[y][x] = "hedge"
	paint.call(blob.call(7.5, 6.5, 6.5, 4.5), "dark")
	paint.call(rect_cells.call(0, 10, 27, 2), "path")
	paint.call(rect_cells.call(25, 2, 2, 10), "path")
	paint.call(blob.call(33, 15.5, 4.3, 3.1), "water")
	paint.call(rect_cells.call(4, 14, 7, 5), "ruin")
	paint.call(blob.call(18, 15, 4.2, 3.0), "dirt")
	const SETS := {"path": Vector2i(0, 2), "dirt": Vector2i(5, 2), "water": Vector2i(10, 2),
		"dark": Vector2i(0, 5), "hedge": Vector2i(5, 5), "ruin": Vector2i(10, 5)}
	const BASES := {"path": [Vector2i(3, 0), Vector2i(3, 0), Vector2i(3, 0), Vector2i(12, 0), Vector2i(6, 1)],
		"dirt": [Vector2i(4, 0), Vector2i(4, 0), Vector2i(13, 0)],
		"water": [Vector2i(6, 0), Vector2i(6, 0), Vector2i(2, 1)],
		"dark": [Vector2i(5, 0), Vector2i(5, 0), Vector2i(15, 0)],
		"hedge": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
		"ruin": [Vector2i(7, 0), Vector2i(3, 1), Vector2i(4, 1)],
		"grass": [Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(5, 1), Vector2i(5, 1),
			Vector2i(8, 0), Vector2i(9, 0), Vector2i(10, 0), Vector2i(11, 0)]}
	const PIECE := {"otl": Vector2i(0, 0), "t": Vector2i(1, 0), "otr": Vector2i(2, 0), "itl": Vector2i(3, 0), "itr": Vector2i(4, 0),
		"l": Vector2i(0, 1), "c": Vector2i(1, 1), "r": Vector2i(2, 1), "ibl": Vector2i(3, 1), "ibr": Vector2i(4, 1),
		"obl": Vector2i(0, 2), "b": Vector2i(1, 2), "obr": Vector2i(2, 2)}
	for y in H:
		for x in W:
			var m: String = mat[y][x]
			var same := func(dx: int, dy: int) -> bool:
				var nx := x + dx
				var ny := y + dy
				if nx < 0 or ny < 0 or nx >= W or ny >= H:
					return true
				return mat[ny][nx] == m
			var t := Vector2i.ZERO
			var piece := "c"
			if m != "grass":
				var u: bool = same.call(0, -1)
				var d: bool = same.call(0, 1)
				var l: bool = same.call(-1, 0)
				var r: bool = same.call(1, 0)
				if not u and not l: piece = "otl"
				elif not u and not r: piece = "otr"
				elif not d and not l: piece = "obl"
				elif not d and not r: piece = "obr"
				elif not u: piece = "t"
				elif not d: piece = "b"
				elif not l: piece = "l"
				elif not r: piece = "r"
				elif not same.call(-1, -1): piece = "itl"
				elif not same.call(1, -1): piece = "itr"
				elif not same.call(-1, 1): piece = "ibl"
				elif not same.call(1, 1): piece = "ibr"
			if piece == "c":
				var opts: Array = BASES[m]
				t = opts[rng.randi_range(0, opts.size() - 1)] if m != "grass" or rng.randf() < 0.35 else Vector2i(0, 0)
			else:
				t = SETS[m] + PIECE[piece]
			img.blit_rect(terrain, Rect2i(t * T, Vector2i(T, T)), Vector2i(x, y) * T)
	var map := mat

	# Objetos (orden por y para que se tapen bien)
	var objs := []
	objs.append(["world/tree.png", 0, 3, 32, Vector2(2, 2)])
	objs.append(["world/tree.png", 1, 3, 32, Vector2(6, 1)])
	objs.append(["world/tree.png", 2, 3, 32, Vector2(4, 5)])
	objs.append(["world/tree.png", 0, 3, 32, Vector2(13, 3)])
	objs.append(["world/tree.png", 2, 3, 32, Vector2(33, 3)])
	objs.append(["world/tree.png", 1, 3, 32, Vector2(36, 8)])
	objs.append(["world/ancient_tree.png", 0, 1, 48, Vector2(18, 2)])
	objs.append(["world/rock.png", 0, 3, 16, Vector2(12, 8)])
	objs.append(["world/rock.png", 1, 3, 16, Vector2(28, 8)])
	objs.append(["world/rock.png", 2, 3, 16, Vector2(21, 18)])
	objs.append(["world/iron_vein.png", 0, 1, 16, Vector2(31, 6)])
	objs.append(["world/shiny_vein.png", 0, 4, 16, Vector2(14, 12)])
	objs.append(["world/bush.png", 0, 3, 16, Vector2(10, 7)])
	objs.append(["world/bush.png", 1, 3, 16, Vector2(27, 4)])
	objs.append(["world/bush.png", 2, 3, 16, Vector2(22, 13)])
	objs.append(["world/deco_boulder.png", 0, 1, 32, Vector2(36, 18)])
	objs.append(["world/deco_ruin_pillar.png", 0, 1, 16, Vector2(5, 13)])
	objs.append(["world/deco_ruin_pillar.png", 0, 1, 16, Vector2(9, 13)])
	objs.append(["world/deco_ruin_wall.png", 0, 1, 32, Vector2(6, 18)])
	objs.append(["world/lost_chest.png", 1, 2, 16, Vector2(7, 15)])
	objs.append(["world/deco_stump.png", 0, 1, 16, Vector2(16, 8)])
	objs.append(["world/deco_log.png", 0, 1, 32, Vector2(27, 19)])
	objs.append(["world/camp_tent.png", 0, 1, 32, Vector2(16, 13)])
	objs.append(["world/campfire.png", 1, 4, 16, Vector2(19, 15)])
	objs.append(["world/deco_lilypad.png", 0, 2, 16, Vector2(31, 14.5)])
	objs.append(["world/deco_lilypad.png", 1, 2, 16, Vector2(34, 15.5)])
	for i in 18:
		var p := Vector2(rng.randi_range(2, 37), rng.randi_range(2, 19))
		if map[int(p.y)][int(p.x)] == "grass":
			var which := rng.randi_range(0, 2)
			if which == 0: objs.append(["world/deco_flowers.png", rng.randi_range(0, 3), 4, 16, p])
			elif which == 1: objs.append(["world/deco_tall_grass.png", 0, 2, 16, p])
			else: objs.append(["world/deco_mushrooms.png", rng.randi_range(0, 1), 2, 16, p])
	objs.append(["enemies/enemy_basic.png", 1, 2, 16, Vector2(30, 10)])
	objs.sort_custom(func(a: Array, b: Array) -> bool: return a[4].y * T + a[3] < b[4].y * T + b[3])
	for o: Array in objs:
		var tex := _load(o[0])
		var fw: int = tex.get_width() / int(o[2])
		var fh: int = tex.get_height() if o[0] != "player/player.png" else 32
		var src := Rect2i(int(o[1]) * fw, 0, fw, fh)
		img.blend_rect(tex, src, Vector2i(o[4] * T))
	img.save_png(ProjectSettings.globalize_path("res://docs/PREVIEW_ARTE_V02.png"))
	var big := img.duplicate() as Image
	big.resize(W * T * 2, H * T * 2, Image.INTERPOLATE_NEAREST)
	# El jugador está dibujado al doble (32×32) y en el juego se escala ×0.5: en la vista ×2 se ve
	# con su detalle real, del tamaño de un tile. En la vista ×1 no entra sin perder píxeles.
	var pl := _load("player/player.png")
	big.blend_rect(pl, Rect2i(0, 0, 32, 32), Vector2i(Vector2(22.5, 9.6) * T * 2) - Vector2i(16, 16))
	big.save_png(ProjectSettings.globalize_path("res://docs/PREVIEW_ARTE_V02_2X.png"))
	_contact()
	print("ok preview")
	quit()


## Hoja de contacto: cada PNG nuevo ampliado ×4 sobre pasto.
func _contact() -> void:
	var files := ["tilesets/terrain.png", "world/tree.png", "world/rock.png", "world/bush.png",
		"world/deco_flowers.png", "world/deco_tall_grass.png", "world/deco_mushrooms.png", "world/deco_stump.png",
		"world/deco_log.png", "world/deco_boulder.png", "world/deco_ruin_pillar.png", "world/deco_ruin_wall.png",
		"world/deco_lilypad.png", "world/ancient_tree.png", "world/lost_chest.png", "world/shiny_vein.png",
		"world/campfire.png", "world/camp_tent.png"]
	var scale := 4
	var pad := 8
	var sheet := Image.create_empty(1200, 900, false, Image.FORMAT_RGBA8)
	sheet.fill(Color.html("3B2D45"))
	var x := pad
	var y := pad
	var row_h := 0
	for f: String in files:
		var tex := _load(f)
		var bg := Image.create_empty(tex.get_width(), tex.get_height(), false, Image.FORMAT_RGBA8)
		bg.fill(Color.html("84AB78") if not f.begins_with("tilesets") else Color.html("3B2D45"))
		bg.blend_rect(tex, Rect2i(Vector2i.ZERO, tex.get_size()), Vector2i.ZERO)
		bg.resize(tex.get_width() * scale, tex.get_height() * scale, Image.INTERPOLATE_NEAREST)
		if x + bg.get_width() > sheet.get_width() - pad:
			x = pad
			y += row_h + pad
			row_h = 0
		sheet.blit_rect(bg, Rect2i(Vector2i.ZERO, bg.get_size()), Vector2i(x, y))
		x += bg.get_width() + pad
		row_h = maxi(row_h, bg.get_height())
	sheet.crop(1200, mini(900, y + row_h + pad))
	sheet.save_png(ProjectSettings.globalize_path("res://docs/CONTACTO_ARTE_V02.png"))


func _load(rel: String) -> Image:
	var i := Image.load_from_file(ProjectSettings.globalize_path("res://assets/" + (rel if rel.begins_with("tilesets") else "sprites/" + rel)))
	i.convert(Image.FORMAT_RGBA8)
	return i
