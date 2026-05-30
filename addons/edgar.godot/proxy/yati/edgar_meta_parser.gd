# MIT License
#
# Copyright (c) 2025 RickyYC
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

extends RefCounted

const DATA_LOADER_PATH := "./runtime/DataLoader.gd"
const DICT_BUILDER_PATH := "./runtime/DictionaryBuilder.gd"


## Parse a Tiled map file and return Edgar room metadata directly from the dictionary.
## Returns: { "anchor": Vector2, "lnk": Dictionary, "tile_size": Vector2 }
## The "lnk" dict contains: "boundary" (PackedVector2Array), "doors" (Array[PackedVector2Array]), "transformations" (PackedInt32Array).
## Returns empty dict if no lnk layer found or file cannot be loaded.
static func parse(template_path: String) -> Dictionary:
	var base_path := template_path.get_base_dir()

	var map_content = preload(DATA_LOADER_PATH).get_tiled_file_content(template_path, base_path)
	if map_content == null:
		printerr("EdgarMetaParser: Tiled map file '" + template_path + "' not found.")
		return {}

	var dict = preload(DICT_BUILDER_PATH).new().get_dictionary(map_content, template_path)
	if dict == null:
		printerr("EdgarMetaParser: Failed to parse Tiled map '" + template_path + "'.")
		return {}

	# Map metadata
	var orientation: String = dict.get("orientation", "orthogonal")
	var tile_width: int = dict.get("tilewidth", 0)
	var tile_height: int = dict.get("tileheight", 0)
	var tile_size := Vector2(tile_width, tile_height)
	var map_width: int = dict.get("width", 0)
	var map_height: int = dict.get("height", 0)

	# Find the lnk layer
	var lnk_layer: Dictionary
	if dict.has("layers"):
		for layer: Dictionary in dict["layers"]:
			if layer.get("name", "") == "lnk":
				lnk_layer = layer
				break

	if lnk_layer.is_empty():
		printerr("EdgarMetaParser: No 'lnk' layer found in '" + template_path + "'.")
		return {}

	# Layer position (matching YATI's layer node position)
	var layer_x: float = lnk_layer.get("x", 0.0)
	var layer_y: float = lnk_layer.get("y", 0.0)
	var layer_offset_x: int = lnk_layer.get("offsetx", 0)
	var layer_offset_y: int = lnk_layer.get("offsety", 0)
	var layer_pos := Vector2(layer_x + layer_offset_x, layer_y + layer_offset_y)
	if orientation == "isometric":
		layer_pos.x += tile_width * (map_height / 2.0 - 0.5)

	var objects: Array = lnk_layer.get("objects", [])

	# Classify objects by lnk role
	var anchor_obj: Dictionary
	var boundary_obj: Dictionary
	var door_objs: Array[Dictionary] = []

	for obj: Dictionary in objects:
		var lnk_val := _get_property(obj, "lnk")
		var obj_name: String = obj.get("name", "")

		if obj_name == "Anchor" or lnk_val == "anchor":
			anchor_obj = obj
		elif obj_name == "Boundary" or lnk_val == "boundary":
			boundary_obj = obj
		elif lnk_val == "door":
			door_objs.append(obj)

	# --- Compute anchor ---
	# Post-processor uses: anchor_node.global_position / tile_size
	# Which equals: (layer_pos + transpose_coords(obj.x, obj.y)) / tile_size
	var anchor := Vector2.ZERO
	if not anchor_obj.is_empty():
		var ax: float = anchor_obj.get("x", 0.0)
		var ay: float = anchor_obj.get("y", 0.0)
		var obj_pos := _transpose_coords(orientation, ax, ay, tile_width, tile_height, map_height)
		anchor = (layer_pos + obj_pos) / tile_size

	# --- Compute boundary ---
	# Post-processor uses: polygon[i] + bound_node.position, then / tile_size
	# bound_node.position is layer-relative = transpose_coords(obj.x, obj.y)
	# polygon points are transposed by polygon_from_array (no_offset_x=true)
	var boundary := PackedVector2Array()
	if not boundary_obj.is_empty():
		var bx: float = boundary_obj.get("x", 0.0)
		var by: float = boundary_obj.get("y", 0.0)
		var bpos := _transpose_coords(orientation, bx, by, tile_width, tile_height, map_height)
		if boundary_obj.has("polygon"):
			for pt: Dictionary in boundary_obj["polygon"]:
				var ppt := _transpose_coords(orientation, pt["x"], pt["y"], tile_width, tile_height, map_height, true)
				var world_point := bpos + ppt
				boundary.append(world_point / tile_size)

	# --- Compute doors ---
	# Post-processor uses: door.points[i] + door.position, then / tile_size
	# Same logic as boundary
	var doors: Array[PackedVector2Array] = []
	for door_obj: Dictionary in door_objs:
		var dx: float = door_obj.get("x", 0.0)
		var dy: float = door_obj.get("y", 0.0)
		var dpos := _transpose_coords(orientation, dx, dy, tile_width, tile_height, map_height)
		var door_points := PackedVector2Array()
		if door_obj.has("polyline"):
			for pt: Dictionary in door_obj["polyline"]:
				var ppt := _transpose_coords(orientation, pt["x"], pt["y"], tile_width, tile_height, map_height, true)
				var world_point := dpos + ppt
				door_points.append(world_point / tile_size)
		doors.append(door_points)

	# --- Compute transformations ---
	var transformations := PackedInt32Array([0])
	var trans_str := _get_property(lnk_layer, "transformations")
	if trans_str != "":
		var parsed = JSON.parse_string(trans_str)
		if parsed is Array:
			transformations = PackedInt32Array(parsed)

	var lnk_dict := {
		"boundary": boundary,
		"doors": doors,
		"transformations": transformations,
	}

	return {
		"anchor": anchor,
		"lnk": lnk_dict,
		"tile_size": tile_size,
	}


## Extract a custom property value from a Tiled object/layer dictionary.
static func _get_property(dict: Dictionary, prop_name: String) -> String:
	if not dict.has("properties"):
		return ""
	for prop: Dictionary in dict["properties"]:
		if prop.get("name", "") == prop_name:
			return str(prop.get("value", ""))
	return ""


## YATI-compatible isometric coordinate transformation.
## For orthogonal maps, returns Vector2(x, y) directly.
static func _transpose_coords(orientation: String, x: float, y: float,
		tile_width: int, tile_height: int, map_height: int,
		no_offset_x: bool = false) -> Vector2:
	if orientation == "isometric":
		var trans_x := (x - y) * tile_width / tile_height / 2.0
		if not no_offset_x:
			trans_x += map_height * tile_width / 2.0
		var trans_y := (x + y) * 0.5
		return Vector2(trans_x, trans_y)
	return Vector2(x, y)
