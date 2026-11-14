extends SceneTree
## Vista ampliada de un PNG (Nearest) sobre un fondo, para revisar pixel art.
## godot --headless --path . --script res://tools/art/zoom.gd -- entrada.png salida.png [escala] [fondo_hex] [repetir]
## repetir = N: arma un mosaico NxN de la imagen (sirve para ver si un tile se repite sin costuras).


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var src := Image.load_from_file(a[0])
	src.convert(Image.FORMAT_RGBA8)
	var scale := int(a[2]) if a.size() > 2 else 6
	var bg := Color.html(a[3]) if a.size() > 3 else Color.html("3B2D45")
	var tile := int(a[4]) if a.size() > 4 else 1
	var base := Image.create_empty(src.get_width() * tile, src.get_height() * tile, false, Image.FORMAT_RGBA8)
	base.fill(bg)
	for ty in tile:
		for tx in tile:
			base.blend_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()),
				Vector2i(tx * src.get_width(), ty * src.get_height()))
	base.resize(base.get_width() * scale, base.get_height() * scale, Image.INTERPOLATE_NEAREST)
	base.save_png(a[1])
	quit()
