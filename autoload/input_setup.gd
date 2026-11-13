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
	"interact": [KEY_E],
	"toggle_inventory": [KEY_TAB, KEY_I],
	"attack": [KEY_J],
	"dash": [KEY_SPACE, KEY_SHIFT],
	"toggle_light": [KEY_L],
	# Inventario
	"rotate_item": [KEY_R],
	"discard_item": [KEY_DELETE, KEY_X],
}

const MOUSE_ACTIONS := {
	"attack": [MOUSE_BUTTON_LEFT],
}


func _enter_tree() -> void:
	for action: String in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: Key in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
	for action: String in MOUSE_ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for button: MouseButton in MOUSE_ACTIONS[action]:
			var ev := InputEventMouseButton.new()
			ev.button_index = button
			InputMap.action_add_event(action, ev)
