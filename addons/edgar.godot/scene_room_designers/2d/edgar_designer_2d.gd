@tool
class_name EdgarDesigner2D
extends Node2D

## Tile size used to convert pixel coordinates to tile coordinates,
## matching edgar_post_processor.gd which reads from TileMapLayer.
@export var tile_size := Vector2i(16, 16):
	get:
		var tile_set = %col.tile_set
		return tile_set.tile_size if tile_set else Vector2i(16, 16)

## Transformation flags passed to the generated room, stored in lnk metadata.
@export var transformations := PackedInt32Array([0])


func _ready() -> void:
	if Engine.is_editor_hint():
		_update_metadata()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_update_metadata()
		_refresh_child_warnings()


func _refresh_child_warnings() -> void:
	for child in get_children():
		if child is EdgarBoundary2D or child is EdgarDoor2D:
			child.update_configuration_warnings()


## Computes boundary, doors, anchor and transformations from child geometry
## and writes them as metadata on the scene owner — mirroring the format
## produced by edgar_post_processor.gd.
## Children are auto-collected by type, so adding/removing nodes
## automatically updates the metadata.
func _update_metadata() -> void:
	var owner_node := get_owner() as Node2D
	if owner_node == null:
		return

	var tile_size_v2 := Vector2(tile_size)

	# --- Boundary ---
	var boundary_points: PackedVector2Array
	for child in get_children():
		if child is EdgarBoundary2D:
			boundary_points = child.polygon.duplicate()
			for i in range(boundary_points.size()):
				boundary_points[i] += child.position
				boundary_points[i] /= tile_size_v2
			break

	# --- Doors ---
	var door_list: Array[PackedVector2Array] = []
	for child in get_children():
		if child is EdgarDoor2D:
			var pts: PackedVector2Array = child.points.duplicate()
			for j in range(pts.size()):
				pts[j] += child.position
				pts[j] /= tile_size_v2
			door_list.append(pts)

	# --- Anchor ---
	var anchor_pos := Vector2.ZERO
	for child in get_children():
		if child is EdgarAnchor2D:
			anchor_pos = child.global_position / tile_size_v2
			break

	# --- Assemble lnk dict matching post-processor output ---
	var lnk_dict := {
		"boundary": boundary_points,
		"doors": door_list,
		"transformations": transformations,
	}

	owner_node.set_meta("lnk", lnk_dict)
	owner_node.set_meta("anchor", anchor_pos)
	owner_node.set_meta("tile_size", tile_size_v2)
