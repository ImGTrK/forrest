class_name ZoneData
extends RefCounted
## Resultado de generar una zona del bosque. Vive solo en la cache de ForestSession.

var coord: Vector2i
## Distancia Manhattan a la zona (0,0): alimenta el presupuesto de dificultad.
var depth: int = 0
var budget: int = 0
## Multiplicador de presupuesto por la hora a la que se generó (GDD §4.1).
var difficulty: float = 1.0
## Bonus de rareza por la hora: se suma a depth para pesos, min_depth y ADN.
var rarity: int = 0
## Vector2i dirección -> bool (¿hay puerta de ese lado?)
var doors: Dictionary = {}
## Cada entidad: { "entry": SpawnEntry, "tile": Vector2i, "alive": bool }
## Se guarda "alive" para que lo recolectado no reaparezca si volvés a la zona.
var entities: Array[Dictionary] = []


## Profundidad "efectiva" para la rareza: distancia + hora del día.
func loot_depth() -> int:
	return depth + rarity


func has_door(dir: Vector2i) -> bool:
	return doors.get(dir, false)
