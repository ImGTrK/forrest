class_name Player
extends CharacterBody2D
## Movimiento top-down en 8 direcciones + interacción con lo más cercano.
## CharacterBody2D ≈ un Rigidbody kinematic + CharacterController de Unity:
## seteás `velocity` y llamás move_and_slide(), que resuelve colisiones.

const INTERACT_RANGE := 14.0

@export var speed: float = 95.0

var facing := Vector2.DOWN
## Interactuable enfocado. Sin tipo a propósito: cualquier nodo del grupo "interactable"
## que implemente get_interact_rect(), set_focused(bool) e interact(by) sirve (duck typing,
## como una interfaz de C# pero sin declararla).
var _focus: Variant = null

@onready var camera: Camera2D = $Camera2D


func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir != Vector2.ZERO and not dir.is_equal_approx(facing):
		facing = dir
		queue_redraw()
	velocity = dir * speed
	move_and_slide()
	_update_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and is_instance_valid(_focus):
		_focus.interact(self)
		get_viewport().set_input_as_handled()


## Busca el interactuable (grupo "interactable") más cercano dentro del rango.
## Los grupos de Godot ≈ tags de Unity, pero un nodo puede tener varios.
func _update_focus() -> void:
	var best: Variant = null
	var best_dist := INTERACT_RANGE
	for node: Variant in get_tree().get_nodes_in_group("interactable"):
		var rect: Rect2 = node.get_interact_rect()
		var closest := global_position.clamp(rect.position, rect.end)
		var d := closest.distance_to(global_position)
		if d < best_dist:
			best_dist = d
			best = node
	if best != _focus:
		if is_instance_valid(_focus):
			_focus.set_focused(false)
		_focus = best
		if best != null:
			_focus.set_focused(true)


func set_camera_limits(bounds: Rect2) -> void:
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)


func teleport(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	_focus = null
	camera.reset_smoothing()


func _draw() -> void:
	# Placeholder: cuerpo + "ojo" que indica hacia dónde mira.
	draw_rect(Rect2(-5, -9, 10, 14), Color("e8d29a"))
	draw_rect(Rect2(-5, -9, 10, 14), Color("3a2a1a"), false, 1.0)
	draw_circle(facing.normalized() * 4.0 + Vector2(0, -3), 1.5, Color("3a2a1a"))
