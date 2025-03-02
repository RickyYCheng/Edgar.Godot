@tool
class_name EdgarRenderer
extends Node

@export var graph_resource : EdgarGraphResource

func _draw(layout:Dictionary) -> void:
	var rooms = layout.rooms
	for room in rooms:
		var tiled_resource := load(room.template)
		var position = Vector2(room.position.x, room.position.y)
		var transformation = room.transformation
		_draw_room(tiled_resource, position, transformation)

func _draw_room(tiled_resource:EdgarTiledResource, position:Vector2, transformation:int) -> void:
	pass
