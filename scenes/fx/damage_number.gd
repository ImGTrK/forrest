extends Node2D
## Número de daño: sube con un saltito, se queda un instante y se desvanece. Lo crea Fx.number().

const LIFE := 0.7
const RISE := 14.0

var _label: Label
var _t := 0.0
var _start := Vector2.ZERO
var _drift := 0.0


func setup(text: String, color: Color) -> void:
	_label = Label.new()
	_label.text = text
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_color", color)
	_label.add_theme_color_override("font_outline_color", Color("211C2B"))
	_label.add_theme_constant_override("outline_size", 3)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(24, 10)
	_label.position = Vector2(-12, -5)
	add_child(_label)
	z_index = 60
	_drift = randf_range(-6.0, 6.0)


func _ready() -> void:
	_start = position


func _process(delta: float) -> void:
	_t += delta
	var k := minf(_t / LIFE, 1.0)
	# Sube rápido al principio (ease-out) y se desliza un poco de costado
	var rise := 1.0 - pow(1.0 - k, 3.0)
	position = _start + Vector2(_drift * rise, -RISE * rise)
	position = position.round()
	modulate.a = 1.0 if k < 0.6 else 1.0 - (k - 0.6) / 0.4
	scale = Vector2.ONE * (1.3 if _t < 0.06 else 1.0)  # "pop" al aparecer
	if _t >= LIFE:
		queue_free()
