extends SceneTree
## Genera los PNG placeholder con las medidas EXACTAS que espera el código.
## NUNCA pisa un archivo existente: si ya reemplazaste un sprite con tu arte, se respeta.
##
## Correr con:
##   godot --headless --path . --script res://tools/generate_placeholders.gd
## y después (para que Godot cree los .import):
##   godot --headless --path . --import
##
## Para agregar un sprite nuevo: sumalo a SPRITES y documentalo en assets/README.md.

const T := 16  # tamaño de tile

## path, tamaño total, frames (horizontal), color, estilo, color de acento
## estilos: "tile" (lleno con borde), "body" (figura con margen), "player" (4 direcciones)
var SPRITES := [
	# --- Tileset del terreno: el ORDEN de las columnas importa (ver TerrainTiles) ---
	{"path": "assets/tilesets/terrain.png", "size": Vector2i(T * 4, T), "frames": 4, "style": "tile",
		"colors": [Color("3b7d3a"), Color("1d3320"), Color("8a7356"), Color("7d8f4e")]},

	# --- Personaje ---
	# Hoja 8x8 (de BarrenRoots): filas = direcciones S, SW, W, NW, N, NE, E, SE;
	# columnas 0-3 idle, 4-7 caminar.
	{"path": "assets/sprites/player/player.png", "size": Vector2i(T * 8, T * 8), "frames": 8,
		"rows": 8, "style": "player", "colors": [Color("e8d29a")]},
	{"path": "assets/sprites/player/sword.png", "size": Vector2i(T, T), "style": "body",
		"colors": [Color("c8ccd4")]},

	# --- Enemigos (hito 3) ---
	{"path": "assets/sprites/enemies/enemy_basic.png", "size": Vector2i(T * 2, T), "frames": 2,
		"style": "body", "colors": [Color("d9a03a")]},

	# --- Mundo ---
	{"path": "assets/sprites/world/chest.png", "size": Vector2i(T, T), "style": "body",
		"colors": [Color("6b4423")], "accent": Color("d4a640")},
	{"path": "assets/sprites/world/tree.png", "size": Vector2i(T * 2, T * 2), "style": "body",
		"colors": [Color("21672b")], "accent": Color("8c5c2e")},
	{"path": "assets/sprites/world/rock.png", "size": Vector2i(T, T), "style": "body",
		"colors": [Color("80808a")], "accent": Color("9a9a9e")},
	{"path": "assets/sprites/world/iron_vein.png", "size": Vector2i(T, T), "style": "body",
		"colors": [Color("5e4a44")], "accent": Color("b8735a")},
	{"path": "assets/sprites/world/bush.png", "size": Vector2i(T, T), "style": "body",
		"colors": [Color("33501f")]},
	# Hito 2
	{"path": "assets/sprites/world/bed.png", "size": Vector2i(T, T * 2), "style": "body",
		"colors": [Color("7a4a3a")], "accent": Color("e8e2d0")},

	# --- UI / HUD (hito 2) ---
	{"path": "assets/sprites/ui/icon_clock.png", "size": Vector2i(8, 8), "style": "body",
		"colors": [Color("e8e2d0")]},
	{"path": "assets/sprites/ui/icon_energy.png", "size": Vector2i(8, 8), "style": "body",
		"colors": [Color("f2c94c")]},
	{"path": "assets/sprites/ui/hearts/heart_full.png", "size": Vector2i(T, T), "style": "body",
		"colors": [Color("d83a3a")]},
	{"path": "assets/sprites/ui/hearts/heart_half.png", "size": Vector2i(T, T), "style": "body",
		"colors": [Color("8a2a2a")]},
	{"path": "assets/sprites/ui/hearts/heart_empty.png", "size": Vector2i(T, T), "style": "body",
		"colors": [Color("3a2a2a")]},
	# Hito 4: inventario
	{"path": "assets/sprites/ui/slot.png", "size": Vector2i(18, 18), "style": "tile",
		"colors": [Color("2b2b33")]},
	{"path": "assets/sprites/ui/icon_weight.png", "size": Vector2i(8, 8), "style": "body",
		"colors": [Color("9aa4b8")]},
	{"path": "assets/sprites/ui/energy_bar_under.png", "size": Vector2i(64, 8), "style": "tile",
		"colors": [Color("2a2a2a")]},
	{"path": "assets/sprites/ui/energy_bar_fill.png", "size": Vector2i(64, 8), "style": "tile",
		"colors": [Color("e6e6e6")]},  # claro: el HUD lo tiñe

	# --- Íconos de ítems (inventario/almacén) ---
	# El ícono mide grid_size * 16 px (madera ocupa 1x2 celdas en la mochila)
	{"path": "assets/sprites/items/wood.png", "size": Vector2i(T, T * 2), "style": "body",
		"colors": [Color("8c5c2e")]},
	{"path": "assets/sprites/items/stone.png", "size": Vector2i(T, T), "style": "body",
		"colors": [Color("9a9a9e")]},
	{"path": "assets/sprites/items/iron.png", "size": Vector2i(T, T), "style": "body",
		"colors": [Color("b8735a")]},
]


func _init() -> void:
	var created := 0
	for spec: Dictionary in SPRITES:
		var abs_path := ProjectSettings.globalize_path("res://" + spec.path)
		if FileAccess.file_exists(abs_path):
			print("  existe   ", spec.path)
			continue
		DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
		var img := _draw(spec)
		var err := img.save_png(abs_path)
		if err == OK:
			created += 1
			print("  creado   %s  (%dx%d)" % [spec.path, spec.size.x, spec.size.y])
		else:
			push_error("No se pudo guardar %s: %s" % [spec.path, error_string(err)])
	print("Placeholders creados: %d" % created)
	quit()


func _draw(spec: Dictionary) -> Image:
	var size: Vector2i = spec.size
	var frames: int = spec.get("frames", 1)
	var colors: Array = spec.colors
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rows: int = spec.get("rows", 1)
	var fw := size.x / frames
	var fh := size.y / rows
	for cell in frames * rows:
		var f := cell % frames
		var row := cell / frames
		var r := Rect2i(f * fw, row * fh, fw, fh)
		var color: Color = colors[mini(f, colors.size() - 1)]
		match spec.style:
			"tile":
				img.fill_rect(r, color)
				_border(img, r, color.darkened(0.15))
			"body":
				var body := r.grow(-1)
				img.fill_rect(body, color)
				_border(img, body, color.darkened(0.35))
				if spec.has("accent"):
					img.fill_rect(Rect2i(body.position + Vector2i(2, 2), Vector2i(3, 3)), spec.accent)
			"player":
				# Fila = dirección (S, SW, W, NW, N, NE, E, SE): el "ojo" mira hacia ahí
				var body := Rect2i(r.position + Vector2i(3, 1), Vector2i(10, 14))
				img.fill_rect(body, color)
				_border(img, body, Color("3a2a1a"))
				var look := Vector2.DOWN.rotated(row * PI / 4.0) * 3.0
				var eye: Vector2i = body.get_center() + Vector2i(roundi(look.x), roundi(look.y)) + Vector2i(0, -2)
				img.fill_rect(Rect2i(eye - Vector2i(1, 1), Vector2i(2, 2)), Color("3a2a1a"))
	return img


func _border(img: Image, r: Rect2i, c: Color) -> void:
	img.fill_rect(Rect2i(r.position.x, r.position.y, r.size.x, 1), c)
	img.fill_rect(Rect2i(r.position.x, r.end.y - 1, r.size.x, 1), c)
	img.fill_rect(Rect2i(r.position.x, r.position.y, 1, r.size.y), c)
	img.fill_rect(Rect2i(r.end.x - 1, r.position.y, 1, r.size.y), c)
