class_name Harvestable
extends Interactable
## Árbol / roca / veta, o decoración (arbusto, flores, ruinas…) si no tiene ítem.
## Se construye por código a partir de un SpawnEntry: es el "prefab" de todas las entidades
## del bosque que no son enemigos. El sprite sale de SpawnEntry.texture (cada frame mide
## size * 16 px, con el origen en la esquina superior izquierda).
##
## Texturas con varios frames en tira:
##   - anim_fps = 0: son VARIANTES (ej. 3 árboles) y se elige una por posición
##   - anim_fps > 0: es una ANIMACIÓN (fogata, veta brillante, pasto meciéndose)

## Poder de golpe a mano (sin herramienta). Árbol (dureza 6) = 4 golpes a mano.
const HAND_POWER := 1.5
const TOOL_NAMES := {&"axe": "un hacha", &"pickaxe": "un pico"}

var entry: SpawnEntry
var entity: Dictionary  # referencia al dict dentro de ZoneData (para marcar alive = false)
var depth: int = 0

var _hp: float = 1.0
var _flash: HitFlash
var _frames := 1
var _anim_t := 0.0


func setup(p_entry: SpawnEntry, p_entity: Dictionary, p_depth: int) -> void:
	entry = p_entry
	entity = p_entity
	depth = p_depth
	size = Vector2(entry.size * TerrainTiles.TILE)
	texture = entry.texture


func _ready() -> void:
	super._ready()
	_hp = entry.hardness
	if _sprite and texture.get_width() > int(size.x):
		_frames = int(texture.get_width() / size.x)
		_sprite.hframes = _frames
		# La elección sale de la posición: la misma zona se ve igual al volver.
		_sprite.frame = posmod(hash(entity.get("tile", Vector2i.ZERO)), _frames)
		_anim_t = randf() * 10.0  # que no se animen todos sincronizados
	_flash = HitFlash.new(_sprite)
	add_child(_flash)
	set_process(entry.anim_fps > 0.0 and _frames > 1)


func _process(delta: float) -> void:
	_anim_t += delta
	_sprite.frame = int(_anim_t * entry.anim_fps) % _frames


## La decoración blanda (flores, pasto alto, nenúfares) se pisa: sin colisión.
func _collision_rect() -> Rect2:
	if not entry.solid:
		return Rect2()
	return Rect2(Vector2(2, 2), size - Vector2(4, 4))


## La decoración (sin ítem) no se puede golpear.
func is_interactive() -> bool:
	return entry.item != null


## Golpes que faltan con la herramienta actual (para tests y feedback).
func hits_left() -> int:
	var tool := GameState.best_tool(entry.tool_type)
	return ceili(_hp / (tool.power() if tool else HAND_POWER))


func _on_interact(_by: Node) -> void:
	# Sin lugar en la mochila no se golpea (y no se gasta energía).
	if not GameState.can_carry(entry.item):
		GameState.notify("La mochila está llena: no entra %s" % entry.item.display_name)
		return
	# Herramienta: la mejor del tipo que haya en la mochila (no rota)
	var tool := GameState.best_tool(entry.tool_type)
	var level := tool.data.tool_level if tool else 0
	if level < entry.min_tool_level:
		GameState.notify("Necesito %s de nivel %d o más" % [
			TOOL_NAMES.get(entry.tool_type, "una herramienta"), entry.min_tool_level])
		return
	Energy.spend_action()
	_hp -= tool.power() if tool else HAND_POWER
	GameState.wear(tool)
	_flash.flash(Color(1.8, 1.8, 1.8), 0.2, 1.0)  # destello + sacudida al golpear
	var chips := chip_colors()
	var at := Vector2(size.x / 2.0, size.y * 0.6)
	if _hp > 0.0:
		Fx.burst(self, chips, 5, 55.0, at, 0.5)
		AudioManager.play(&"mine" if entry.tool_type == &"pickaxe" else &"chop", -2.0)
		return
	Fx.burst(self, chips, 14, 75.0, at, 0.3)
	Fx.shake(0.15)
	AudioManager.play(&"break")
	# Eventos raros: más de un ejemplar y mejor ADN (loot_bonus suma profundidad)
	for i in maxi(entry.drop_count, 1):
		var item := DNA.generar_recurso(entry.item, depth + entry.loot_bonus, ForestSession.rng,
			true, entry.guaranteed_trait and i == 0)
		if not GameState.pick_up(item):
			break
	entity.alive = false
	queue_free()


## Astillas al golpear: madera para lo que se tala, piedra (y destellos de mineral) para lo que
## se pica, hojas para el resto.
func chip_colors() -> PackedColorArray:
	match entry.tool_type:
		&"axe":
			return PackedColorArray([Color("D1996D"), Color("9A6550"), Color("F6E3BE")])
		&"pickaxe":
			var c := PackedColorArray([Color("939DA6"), Color("D0D2D1"), Color("596574")])
			if entry.item and entry.item.id != &"stone":
				c.append(Color("80C9E8"))
			return c
	return PackedColorArray([Color("84AB78"), Color("B8D18E"), Color("F8A9BC")])


func _draw_overlay() -> void:
	if _sprite:
		return
	# Sin textura: rectángulo de color
	var k := _flash.amount() if _flash else 0.0
	draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), entry.color.lerp(Color.WHITE, k * 0.6))
