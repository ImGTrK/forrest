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
## Plantilla de la zona (ZoneTemplates): claro, arboleda, estanque, ruinas, pedregal o bosque.
var template: StringName = &"bosque"
## Material del suelo de cada celda (TerrainTiles.Mat), índice x + y * ZONE_TILES.
var ground := PackedByteArray()
## Evento raro de la zona (&"" = ninguno): ancient_tree, lost_chest, shiny_vein, camp.
var event: StringName = &""
## Semilla para elegir las variantes de los tiles (la zona se ve igual al volver).
var paint_seed: int = 0


## Profundidad "efectiva" para la rareza: distancia + hora del día.
func loot_depth() -> int:
	return depth + rarity


func has_door(dir: Vector2i) -> bool:
	return doors.get(dir, false)


func ground_at(c: Vector2i) -> int:
	var n := ZoneGenerator.ZONE_TILES
	if c.x < 0 or c.y < 0 or c.x >= n or c.y >= n or ground.is_empty():
		return TerrainTiles.Mat.HEDGE
	return ground[c.x + c.y * n]
