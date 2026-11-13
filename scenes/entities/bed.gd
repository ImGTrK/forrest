class_name Bed
extends Interactable
## Cama del pueblo: el único lugar donde se puede dormir (GDD §4.1).
## Al interactuar emite `used`; Main se encarga del fundido y de Clock.sleep().


func _init() -> void:
	size = Vector2(16, 32)  # 1x2 tiles
	texture = preload("res://assets/sprites/world/bed.png")  # 16x32
	label_text = "Cama  [E]"
	label_offset = Vector2(-8, -12)
