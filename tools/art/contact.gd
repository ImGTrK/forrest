extends SceneTree
## Hoja de contacto: varios PNG ampliados sobre un fondo, en filas.
## godot --headless --path . --script res://tools/art/contact.gd -- salida.png escala fondo_hex a.png b.png ...


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var out := a[0]
	var scale := int(a[1])
	var bg := Color.html(a[2])
	var pad := 6
	var sheet := Image.create_empty(1400, 1400, false, Image.FORMAT_RGBA8)
	sheet.fill(Color.html("3B2D45"))
	var x := pad
	var y := pad
	var row_h := 0
	for i in range(3, a.size()):
		var tex := Image.load_from_file(a[i])
		tex.convert(Image.FORMAT_RGBA8)
		var tile := Image.create_empty(tex.get_width(), tex.get_height(), false, Image.FORMAT_RGBA8)
		tile.fill(bg)
		tile.blend_rect(tex, Rect2i(Vector2i.ZERO, tex.get_size()), Vector2i.ZERO)
		tile.resize(tex.get_width() * scale, tex.get_height() * scale, Image.INTERPOLATE_NEAREST)
		if x + tile.get_width() > sheet.get_width() - pad:
			x = pad
			y += row_h + pad
			row_h = 0
		sheet.blit_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), Vector2i(x, y))
		x += tile.get_width() + pad
		row_h = maxi(row_h, tile.get_height())
	sheet.crop(sheet.get_width(), mini(sheet.get_height(), y + row_h + pad))
	sheet.save_png(out)
	quit()
