extends Node
## Registra las acciones de input por código al arrancar.
## Equivale a configurar el Input System en Unity. También se pueden crear a mano
## en Project > Project Settings > Input Map; acá van en código para que estén versionadas
## y sean fáciles de leer.

const ACTIONS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"interact": [KEY_E, KEY_SPACE],
	"toggle_inventory": [KEY_TAB, KEY_I],
}


func _enter_tree() -> void:
	for action: String in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: Key in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
