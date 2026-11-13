extends Node
## Estado EFÍMERO del bosque: la cache de zonas del run actual.
## GDD §3: cada zona se genera la primera vez que se entra, se guarda en memoria
## ({Vector2i: ZoneData}) y se borra entera al volver al hub.

signal zone_entered(coord: Vector2i)
signal run_reset

## El hub ocupa esta celda del grid; la zona (0,0) tiene su puerta oeste hacia acá.
const HUB_COORD := Vector2i(-1, 0)

var zones: Dictionary = {}  # Vector2i -> ZoneData
var current: Vector2i = Vector2i.ZERO
var in_forest: bool = false
var run_seed: int = 0
## Un solo RNG por run, sembrado: con la misma semilla y las mismas decisiones
## se reproduce el mismo bosque (útil para depurar).
var rng := RandomNumberGenerator.new()


func start_run(seed_override: int = -1) -> void:
	zones.clear()
	run_seed = seed_override if seed_override >= 0 else randi()
	rng.seed = run_seed
	in_forest = true
	print("[ForestSession] nuevo run, semilla = ", run_seed)


## Al pisar el hub: el bosque deja de existir.
func reset() -> void:
	zones.clear()
	in_forest = false
	current = Vector2i.ZERO
	run_reset.emit()


## Entra a `coord` por su puerta `entry_dir` (lado de la zona NUEVA por el que se entra).
## Si la zona no existe en la cache, se genera ahora.
func enter(coord: Vector2i, entry_dir: Vector2i) -> ZoneData:
	if not zones.has(coord):
		zones[coord] = ZoneGenerator.generate(coord, entry_dir, zones, rng, HUB_COORD)
	current = coord
	zone_entered.emit(coord)
	return zones[coord]
