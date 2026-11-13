extends Node
## Reloj continuo (GDD §4.1).
## - Corre en el hub y en el bosque; se detiene solo cuando el árbol está pausado (menús).
## - No hay "días" como unidad de juego: el día es solo una etiqueta del HUD.
## - También define la CURVA POR HORA: multiplicador de dificultad, bonus de rareza y
##   color ambiente. Todo sale de las mismas tablas de keyframes, así se balancea en un lugar.

signal time_advanced(minutes: float)
signal slept(hours: int)

# --- Balance -------------------------------------------------------------------
## Segundos reales por hora de juego. 30 s => 18 h despierto ≈ 9 min de juego.
const REAL_SECONDS_PER_HOUR := 30.0
const START_HOUR := 6.0
## Dormir hace pasar una cantidad ALEATORIA de horas en este rango (inclusive).
const SLEEP_HOURS := Vector2i(5, 9)

## Curva de dificultad. `t` = horas desde las 6:00 (0 = 6am, 12 = 18h, 20 = 2am).
## mult: multiplica el presupuesto de la zona · rarity: se suma a la profundidad para
## la tabla ponderada, min_depth y las tiradas de ADN.
const DIFFICULTY_KEYS := [
	{"t": 0.0, "mult": 1.0, "rarity": 0.0},    # 06:00 mañana
	{"t": 6.0, "mult": 1.0, "rarity": 0.0},    # 12:00
	{"t": 12.0, "mult": 1.25, "rarity": 1.0},  # 18:00 tarde -> noche
	{"t": 16.0, "mult": 1.5, "rarity": 2.0},   # 22:00 noche
	{"t": 20.0, "mult": 1.8, "rarity": 3.0},   # 02:00 madrugada
	{"t": 24.0, "mult": 2.0, "rarity": 3.0},   # 06:00 (pico justo antes del amanecer)
]

## Tinte del mundo. La niebla/visibilidad real llega en el hito 6.
const COLOR_KEYS := [
	{"t": 0.0, "color": Color(0.95, 0.9, 0.85)},   # 06:00 amanecer
	{"t": 2.0, "color": Color(1, 1, 1)},           # 08:00
	{"t": 10.0, "color": Color(1, 1, 1)},          # 16:00
	{"t": 12.0, "color": Color(1.0, 0.82, 0.68)},  # 18:00 atardecer
	{"t": 14.0, "color": Color(0.5, 0.52, 0.78)},  # 20:00
	{"t": 20.0, "color": Color(0.32, 0.34, 0.55)}, # 02:00
	{"t": 23.0, "color": Color(0.38, 0.38, 0.58)}, # 05:00
	{"t": 24.0, "color": Color(0.95, 0.9, 0.85)},  # 06:00
]
# -------------------------------------------------------------------------------

## Minutos desde el día 1 a las 00:00.
var total_minutes: float = START_HOUR * 60.0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()


func _process(delta: float) -> void:
	var minutes := delta / REAL_SECONDS_PER_HOUR * 60.0
	total_minutes += minutes
	time_advanced.emit(minutes)


## Duerme una cantidad aleatoria de horas. Devuelve cuántas.
func sleep() -> int:
	var hours := rng.randi_range(SLEEP_HOURS.x, SLEEP_HOURS.y)
	total_minutes += hours * 60.0
	slept.emit(hours)
	return hours


func hour() -> float:
	return fmod(total_minutes / 60.0, 24.0)


func day() -> int:
	return floori(total_minutes / 1440.0) + 1


func time_string() -> String:
	var m := floori(total_minutes) % 1440
	return "%02d:%02d" % [m / 60, m % 60]


func period_name() -> String:
	var h := hour()
	if h >= 6.0 and h < 12.0:
		return "Mañana"
	if h >= 12.0 and h < 18.0:
		return "Tarde"
	if h >= 18.0 or h < 2.0:
		return "Noche"
	return "Madrugada"


## Horas desde las 6:00 (0..24), el eje de las curvas.
func _t() -> float:
	return fmod(hour() - 6.0 + 24.0, 24.0)


func difficulty_multiplier() -> float:
	return _sample(DIFFICULTY_KEYS, "mult")


func rarity_bonus() -> int:
	return roundi(_sample(DIFFICULTY_KEYS, "rarity"))


## Qué tan de noche es para la VISIÓN (GDD §4.1: de ~18:00 a ~04:00), 0..1.
## 18:00 → 21:00 se cierra · 21:00 → 03:00 noche cerrada · 03:00 → 05:00 se abre.
func night_factor() -> float:
	var t := fmod(hour() - 18.0 + 24.0, 24.0)  # 0 = 18:00
	if t < 3.0:
		return t / 3.0
	if t < 9.0:
		return 1.0
	if t < 11.0:
		return 1.0 - (t - 9.0) / 2.0
	return 0.0


func ambient_color() -> Color:
	var t := _t()
	for i in range(1, COLOR_KEYS.size()):
		var a: Dictionary = COLOR_KEYS[i - 1]
		var b: Dictionary = COLOR_KEYS[i]
		if t <= b.t:
			return (a.color as Color).lerp(b.color, inverse_lerp(a.t, b.t, t))
	return COLOR_KEYS.back().color


func _sample(keys: Array, field: String) -> float:
	var t := _t()
	for i in range(1, keys.size()):
		var a: Dictionary = keys[i - 1]
		var b: Dictionary = keys[i]
		if t <= b.t:
			return lerpf(a[field], b[field], inverse_lerp(a.t, b.t, t))
	return keys.back()[field]
