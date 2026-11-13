class_name ResourceType
extends Resource
## Definición de un tipo de recurso (Madera, Piedra, Hierro...).
## Es el equivalente a un ScriptableObject de Unity: los datos viven en archivos .tres
## (data/resources/*.tres) que se editan desde el Inspector.

@export var id: StringName
@export var display_name: String = ""
@export var color: Color = Color.WHITE
## nombre_del_stat -> Vector2(min, max). Todos los stats son "más alto = mejor".
@export var stats: Dictionary = {}
