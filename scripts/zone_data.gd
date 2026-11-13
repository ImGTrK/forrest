class_name ZoneData
extends RefCounted
## Resultado de generar una zona del bosque. Vive solo en la cache de ForestSession.

var coord: Vector2i
## Distancia Manhattan a la zona (0,0): alimenta el presupuesto de dificultad.
var depth: int = 0
var budget: int = 0
## Vector2i dirección -> bool (¿hay puerta de ese lado?)
var doors: Dictionary = {}
## Cada entidad: { "entry": SpawnEntry, "tile": Vector2i, "alive": bool }
## Se guarda "alive" para que lo recolectado no reaparezca si volvés a la zona.
var entities: Array[Dictionary] = []


func has_door(dir: Vector2i) -> bool:
	return doors.get(dir, false)
