extends Node
## Estado PERSISTENTE entre runs (vive en el hub).
## Autoload = singleton global: accesible desde cualquier script como `GameState`.
##
## Los ítems son Dictionaries simples generados por DNA.generar_recurso():
## { "type": &"wood", "name": "Madera", "stats": {...}, "quality": 0-100, "depth": int }

signal run_inventory_changed
signal storage_changed
signal message(text: String)

## % de lo cargado que se pierde según cómo termina el run (GDD §4).
const COLLAPSE_LOSS := 0.25
const DEATH_LOSS := 0.5  # se usa en el hito 3 (combate)

## Lo que el jugador carga durante el run actual (se puede perder al morir/colapsar).
var run_inventory: Array[Dictionary] = []
## Almacén del hub (persistente).
var storage: Array[Dictionary] = []
var runs_completed: int = 0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()


func add_to_run(item: Dictionary) -> void:
	run_inventory.append(item)
	run_inventory_changed.emit()
	notify("+ %s  (calidad %d%%)" % [item.name, item.quality])


## Pasa todo lo cargado al almacén. Devuelve cuántos ítems se depositaron.
func deposit_run() -> int:
	var count := run_inventory.size()
	storage.append_array(run_inventory)
	run_inventory.clear()
	runs_completed += 1
	run_inventory_changed.emit()
	storage_changed.emit()
	return count


## Para colapso por energía / muerte (siguientes hitos): pierde una fracción al azar.
func lose_run_fraction(fraction: float, rng: RandomNumberGenerator) -> int:
	var to_lose := floori(run_inventory.size() * clampf(fraction, 0.0, 1.0))
	for i in to_lose:
		run_inventory.remove_at(rng.randi_range(0, run_inventory.size() - 1))
	run_inventory_changed.emit()
	return to_lose


func notify(text: String) -> void:
	message.emit(text)
