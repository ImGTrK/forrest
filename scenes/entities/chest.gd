class_name Chest
extends Interactable
## Almacén del pueblo. Al interactuar emite `used`; Main abre la UI del almacén.


func _init() -> void:
	size = Vector2(16, 16)
	texture = preload("res://assets/sprites/world/chest.png")  # 16x16
	label_text = "Almacén  [E]"
	label_offset = Vector2(-16, -14)
