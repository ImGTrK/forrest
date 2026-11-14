class_name TraitData
extends Resource
## Rasgo raro de un recurso (hito 11). Un .tres por rasgo en data/traits/.
## Sale a veces al recolectar (ver Traits.roll) y pasa a la herramienta que se fabrique con ese
## material (Traits.inherit). Sus efectos multiplican stats: en el recurso, los que tenga (peso);
## en la herramienta, poder / durabilidad / peso.

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
## Recurso en el que puede aparecer.
@export var material: ItemData
## Rasgo malo: también se hereda, y antes que los buenos (no se "tapa" sumando rasgos buenos).
@export var negative: bool = false
## Chance relativa frente a los otros rasgos del mismo material.
@export var weight: float = 1.0
## stat -> multiplicador. Ej. {"durabilidad": 1.25} = +25 % de durabilidad.
@export var effects: Dictionary = {}


## Qué tanto cambia las cosas (para ordenar cuáles se quedan al heredar).
func strength() -> float:
	var s := 0.0
	for stat: String in effects:
		s += absf(float(effects[stat]) - 1.0)
	return s


## "+25% durabilidad · −30% peso"
func effects_text() -> String:
	var parts: PackedStringArray = []
	for stat: String in effects:
		var pct := roundi((float(effects[stat]) - 1.0) * 100.0)
		parts.append("%s%d%% %s" % ["+" if pct >= 0 else "−", absi(pct), stat])
	return " · ".join(parts)


## Dorado para los buenos, rojo apagado para los malos.
func color() -> Color:
	return Color("E390A8") if negative else Color("E5BA6B")
