class_name Bench
extends Interactable
## Mesa de crafting del pueblo. Al interactuar emite `used`; Main abre la CraftingUI.


func _init() -> void:
	size = Vector2(32, 16)  # 2x1 tiles
	texture = preload("res://assets/sprites/world/bench.png")  # 32x16
	label_text = "Mesa  [E]"
	label_offset = Vector2(2, -12)
