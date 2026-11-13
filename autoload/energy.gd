extends Node
## Energía (GDD §4.1). Regla para el jugador: "la barra baja, y baja más rápido si golpeás".
## - Drenaje base por cada minuto de reloj que pasa.
## - Costo extra pequeño por acción (golpear/recolectar).
## - Rampa: 50% aviso · 20% debuffs · 0% colapso.
## - Dormir recarga proporcional a las horas dormidas.
## Persiste entre runs (no se resetea con el bosque).

signal changed(value: float, max_value: float)
signal state_changed(state: int)
signal collapsed

enum State { NORMAL, TIRED, EXHAUSTED, COLLAPSED }

# --- Balance -------------------------------------------------------------------
const MAX := 100.0
## 5/h => ~20 h despierto sin hacer nada (≈ 10 min reales).
const DRAIN_PER_HOUR := 5.0
## Por golpe. Un árbol (3 golpes) ≈ 1.2 de energía.
const ACTION_COST := 0.4
## Dormir 5-9 h recarga 60-108 (tope 100).
const RECHARGE_PER_SLEEP_HOUR := 12.0
const TIRED_RATIO := 0.5
const EXHAUSTED_RATIO := 0.2
## Debuffs con energía baja
const EXHAUSTED_SPEED_MULT := 0.7
const EXHAUSTED_COOLDOWN_MULT := 2.0
# -------------------------------------------------------------------------------

var value: float = MAX
var state: State = State.NORMAL


func _ready() -> void:
	Clock.time_advanced.connect(_on_time_advanced)
	Clock.slept.connect(_on_slept)


func spend_action() -> void:
	spend(ACTION_COST)


func spend(amount: float) -> void:
	_change(-amount)


func ratio() -> float:
	return value / MAX


func is_exhausted() -> bool:
	return state >= State.EXHAUSTED


func speed_multiplier() -> float:
	return EXHAUSTED_SPEED_MULT if is_exhausted() else 1.0


func cooldown_multiplier() -> float:
	return EXHAUSTED_COOLDOWN_MULT if is_exhausted() else 1.0


## Para tests y para debug.
func set_value(v: float) -> void:
	_change(v - value)


func _on_time_advanced(minutes: float) -> void:
	if state == State.COLLAPSED:
		return
	_change(-DRAIN_PER_HOUR * minutes / 60.0)


func _on_slept(hours: int) -> void:
	_change(RECHARGE_PER_SLEEP_HOUR * hours)


func _change(delta: float) -> void:
	value = clampf(value + delta, 0.0, MAX)
	changed.emit(value, MAX)
	_update_state()


func _update_state() -> void:
	var new_state := State.NORMAL
	if value <= 0.0:
		new_state = State.COLLAPSED
	elif ratio() <= EXHAUSTED_RATIO:
		new_state = State.EXHAUSTED
	elif ratio() <= TIRED_RATIO:
		new_state = State.TIRED
	if new_state == state:
		return
	var getting_worse := new_state > state
	state = new_state
	state_changed.emit(state)
	if not getting_worse:
		return
	match state:
		State.TIRED:
			GameState.notify("Empiezo a sentirme cansado...")
		State.EXHAUSTED:
			GameState.notify("Estoy agotado. Me cuesta moverme y golpear.")
		State.COLLAPSED:
			collapsed.emit()
