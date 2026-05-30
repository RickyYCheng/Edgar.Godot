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

@tool @icon("res://addons/edgar.godot/icons/edgar_renderer_2d.svg")
class_name EdgarRenderer2D
extends Node2D

const KERNEL_PROXY_PATH := "Edgar/kernel/edgar_kernel_proxy"
const EDGAR_YATI_PROXY_PATH := "res://addons/edgar.godot/proxy/yati/edgar_yati_proxy.gd"

enum AnchorOffsetMode {
	OFFSET_CELL_COORD,
	OFFSET_TILEMAP,
}

signal post_process(renderer: EdgarRenderer2D, tile_map_layer: TileMapLayer, tiled_layer: String)
## data stores coordinates relative to the tile_map_layer instead of world position.
signal marker_post_process(renderer: EdgarRenderer2D, tile_map_layer: TileMapLayer, marker: Node, data: Variant)
signal custom_post_process(renderer: EdgarRenderer2D, tile_map_layer: TileMapLayer, layer: Node)
signal clear_tiles(renderer: EdgarRenderer2D, tile_map_layer: TileMapLayer)

var generator: EdgarGodotGenerator

var _cached_proxy_path: String = ""
var _proxy: GDScript
func get_proxy() -> GDScript:
	var path := ProjectSettings.get_setting(KERNEL_PROXY_PATH, EDGAR_YATI_PROXY_PATH) as String
	if _cached_proxy_path != path:
		_cached_proxy_path = path
		_proxy = (load(path) as GDScript) if ResourceLoader.exists(path) else null
	return _proxy

@export_tool_button("Generate Layout") var _generate_layout_btn : Callable = generate_layout
@export_tool_button("Rerender Layout") var _renderer_layout_btn : Callable = render
@export var anchor_offset_mode: AnchorOffsetMode = AnchorOffsetMode.OFFSET_CELL_COORD
@export var tile_map_layers: Array[TileMapLayer] = []
@export var level: EdgarGraphResource:
	get: return level
	set(v):
		# Disconnect from old resource
		if level and level.changed.is_connected(_on_level_changed):
			level.changed.disconnect(_on_level_changed)
		
		if not v:
			level = null
			generator = null
			return
		
		if EdgarGodotGenerator.resource_valid(v):
			level = v
			generator = EdgarGodotGenerator.from_resource(level)
			if generator:
				generator.inject_seed(seed)
			# Connect to new resource's changed signal
			level.changed.connect(_on_level_changed)
		else:
			level = null
			generator = null
			push_error("[EdgarGodot] Invalid level resource provided.")
@export var layout: Dictionary
@export var seed: int:
	set(sd):
		seed = sd
		if generator:
			generator.inject_seed(seed)
@export var anchor_offset: Vector2

func _init() -> void:
	post_process.connect(func(renderer, tml, tiled_layer): _post_process(tml, tiled_layer))
	marker_post_process.connect(func(renderer, tml, marker, data): _marker_post_process(tml, marker, data))
	custom_post_process.connect(func(renderer, tml, layer): _custom_post_process(tml, layer))
	clear_tiles.connect(func(renderer, tml): _clear_tiles(tml))

func _on_level_changed() -> void:
	generator = EdgarGodotGenerator.from_resource(level)

func generate_layout() -> void:
	if not level:
		push_error("[EdgarGodot] Cannot generate layout: level is null.")
		return
	
	if not generator:
		push_error("[EdgarGodot] Cannot generate layout: generator is null. Make sure level resource is valid.")
		return

	layout = generator.generate_layout()
	for room in layout.rooms:
		room["edgar_layer"] = level.get_meta("nodes")[room.room].edgar_layer
		room["is_pivot"] = level.get_meta("nodes")[room.room].is_pivot
	
	var pivot_idx := layout.rooms.find_custom(func(r): return r.is_pivot) as int
	if pivot_idx >= 0:
		var pivot_room := layout.rooms[pivot_idx] as Dictionary
		var anchor := _get_anchor(pivot_room.template)
		var transformation := int(pivot_room.transformation)
		
		var proxy := get_proxy()
		var lnk := _get_lnk(pivot_room.template, proxy)
		var boundary := lnk.get("boundary", PackedVector2Array()) as PackedVector2Array
		if not boundary.is_empty():
			var origin_rect := _rect_from_boundary(boundary)
			var target_rect := _rect_from_boundary(pivot_room.outline, pivot_room.position)
			anchor = _transform_anchor(anchor, transformation, origin_rect, target_rect)
		else:
			anchor = pivot_room.position + anchor
		
		var coord_offset: Vector2 = anchor
		anchor_offset = -coord_offset if anchor_offset_mode == AnchorOffsetMode.OFFSET_CELL_COORD else Vector2i.ZERO

func render() -> void:
	if not layout:
		printerr("[EdgarGodot] Cannot render: layout is null or empty.")
		return

	var proxy := get_proxy()
	for tile_map_layer in tile_map_layers:
		clear(tile_map_layer)
		
		var room_exceptions := tile_map_layer.get_meta("room_exceptions", {})
		var room_inclusions := tile_map_layer.get_meta("room_inclusions", {})
		
		var edgar_layer_exceptions := tile_map_layer.get_meta("edgar_layer_exceptions", {})
		var edgar_layer_inclusions := tile_map_layer.get_meta("edgar_layer_inclusions", {})
		
		var tile_exceptions := tile_map_layer.get_meta("tile_exceptions", {}) as Dictionary
		var tile_inclusions := tile_map_layer.get_meta("tile_inclusions", {}) as Dictionary
		
		var tiled_layer := tile_map_layer.get_meta("tiled_layer", tile_map_layer.name)
		var tile_size := Vector2(tile_map_layer.tile_set.tile_size) if tile_map_layer.tile_set else Vector2.ONE
		
		match anchor_offset_mode:
			AnchorOffsetMode.OFFSET_TILEMAP:
				tile_map_layer.position = anchor_offset * tile_size
			AnchorOffsetMode.OFFSET_CELL_COORD:
				pass

		for room in layout.rooms:
			# Filter rooms before instantiation to avoid unnecessary load+free
			if not room_inclusions.is_empty():
				if room_inclusions.get(room.room, false) == false:
					continue
			else:
				if room_exceptions.get(room.room, false) == true:
					continue
			
			var room_edgar_layer := int(room.edgar_layer)
			if not edgar_layer_inclusions.is_empty():
				if edgar_layer_inclusions.get(room_edgar_layer, false) == false:
					continue
			else:
				if edgar_layer_exceptions.get(room_edgar_layer, false) == true:
					continue
			
			var room_node := _load_room(room.template, proxy)
			var lnk := room_node.get_meta("lnk") as Dictionary

			var origin_outline := lnk["boundary"] as PackedVector2Array
			var origin_used_rect := _rect_from_boundary(origin_outline)
			var target_used_rect := _rect_from_boundary(room.outline, room.position)
			
			var origin_tile_size := Vector2(room_node.get_meta("origin_tile_size", Vector2i.ONE))
			var target_tile_size := Vector2(tile_map_layer.tile_set.tile_size) if tile_map_layer.tile_set else Vector2.ONE
			for child in room_node.get_children():
				if child is TileMapLayer and child.name == tiled_layer:
					var origin_tml := child as TileMapLayer
					var cells := origin_tml.get_used_cells()

					for cell in cells:
						var source_id := origin_tml.get_cell_source_id(cell)
						var atlas_coord := origin_tml.get_cell_atlas_coords(cell)
						var alternative_tile := origin_tml.get_cell_alternative_tile(cell)

						var target_tile := Vector4i(source_id, atlas_coord.x, atlas_coord.y, alternative_tile)
						if not tile_inclusions.is_empty():
							if tile_inclusions.get(target_tile, false) == false:
								continue
						else:
							if tile_exceptions.get(target_tile, false) == true:
								continue

						var tile_data := origin_tml.get_cell_tile_data(cell)
						var _str := "tileswap%d" % int(room.transformation)
						if tile_data.has_meta(_str):
							var swap_data := tile_data.get_meta(_str) as Color
							source_id = swap_data.r8
							atlas_coord = Vector2i(swap_data.g8, swap_data.b8)
							alternative_tile = swap_data.a8

						tile_map_layer.set_cell(
							_transform_cell(cell, origin_used_rect, target_used_rect, room.transformation, anchor_offset), 
							source_id, 
							atlas_coord, 
							alternative_tile
						)
				elif child.name == "markers":
					for marker in child.get_children():
						var marker_data : Variant = null
						if marker is Marker2D:
							var spot_position := _transform_point(marker.position / origin_tile_size, origin_used_rect, target_used_rect, room.transformation, anchor_offset)
							marker_data = spot_position
						elif marker is Line2D:
							var src_points : PackedVector2Array = marker.points
							var count := src_points.size()
							var points := PackedVector2Array()
							points.resize(count)
							var j := 0
							while j < count:
								points[j] = _transform_point(src_points[j] / origin_tile_size, origin_used_rect, target_used_rect, room.transformation, anchor_offset)
								j += 1
							
							marker_data = points
						elif marker is Polygon2D:
							var src_polygon : PackedVector2Array = marker.polygon
							var count := src_polygon.size()
							var points := PackedVector2Array()
							points.resize(count)
							var j := 0
							while j < count:
								points[j] = _transform_point(src_polygon[j] / origin_tile_size, origin_used_rect, target_used_rect, room.transformation, anchor_offset)
								j += 1
							
							marker_data = points
						marker_post_process.emit(self, tile_map_layer, marker, marker_data)
				else:
					custom_post_process.emit(self, tile_map_layer, child)
			
			room_node.queue_free()
		
		post_process.emit(self, tile_map_layer, tiled_layer)

## Do not call [code]super()[/code] here. [br]
## [code]super()[/code] will execute [code]tile_map_layer._post_process(self)[/code]. [br]
func _post_process(tile_map_layer: TileMapLayer, tiled_layer: String) -> void:
	if tile_map_layer.has_method("_post_process"):
		tile_map_layer._post_process(self, tiled_layer)

## data stores coordinates relative to the tile_map_layer instead of world position.
func _marker_post_process(tile_map_layer: TileMapLayer, marker: Node, data: Variant) -> void:
	pass

func _custom_post_process(tile_map_layer: TileMapLayer, layer: Node) -> void:
	pass

func _clear_tiles(tile_map_layer: TileMapLayer) -> void:
	tile_map_layer.clear()

func _rect_from_boundary(boundary: PackedVector2Array, offset := Vector2.ZERO) -> Rect2i:
	if boundary.is_empty():
		return Rect2i()
	var rect := Rect2i(Vector2i(boundary[0] + offset), Vector2i.ZERO)
	for pt in boundary:
		rect = rect.expand(Vector2i(pt + offset))
	return rect

# NOTE: origin_used_rect is not transformed, target_used_rect is transformed.
func _transform_cell(cell: Vector2i, origin_used_rect: Rect2i, target_used_rect: Rect2i, transformation: int, cell_offset: Vector2i = Vector2i.ZERO) -> Vector2i:
	var diff := target_used_rect.position - origin_used_rect.position
	match transformation:
		0: # Identity
			return cell + diff + cell_offset
		1: # Rotate 90
			return Vector2i(origin_used_rect.size.y - 1 - cell.y, cell.x) + diff + cell_offset
		2: # Rotate 180
			return Vector2i(origin_used_rect.size.x - 1 - cell.x, origin_used_rect.size.y - 1 - cell.y) + diff + cell_offset
		3: # Rotate 270
			return Vector2i(cell.y, origin_used_rect.size.x - 1 - cell.x) + diff + cell_offset
		4: # Mirror X
			return Vector2i(origin_used_rect.size.x - 1 - cell.x, cell.y) + diff + cell_offset
		5: # Mirror Y
			return Vector2i(cell.x, origin_used_rect.size.y - 1 - cell.y) + diff + cell_offset
		6: # Diagnal 13
			return Vector2i(cell.y, cell.x) + diff + cell_offset
		7: # Diagonal 24
			return Vector2i(origin_used_rect.size.y - 1 - cell.y, origin_used_rect.size.x - 1 - cell.x) + diff + cell_offset
	return cell + diff + cell_offset

# NOTE: origin_used_rect is not transformed, target_used_rect is transformed.
func _transform_point(point: Vector2, origin_used_rect: Rect2i, target_used_rect: Rect2i, transformation: int, point_offset: Vector2i = Vector2i.ZERO) -> Vector2:
	var diff := Vector2(target_used_rect.position - origin_used_rect.position)
	var w := float(origin_used_rect.size.x)
	var h := float(origin_used_rect.size.y)
	match transformation:
		0: # Identity
			return point + diff + Vector2(point_offset)
		1: # Rotate 90
			return Vector2(h - point.y, point.x) + diff + Vector2(point_offset)
		2: # Rotate 180
			return Vector2(w - point.x, h - point.y) + diff + Vector2(point_offset)
		3: # Rotate 270
			return Vector2(point.y, w - point.x) + diff + Vector2(point_offset)
		4: # Mirror X
			return Vector2(w - point.x, point.y) + diff + Vector2(point_offset)
		5: # Mirror Y
			return Vector2(point.x, h - point.y) + diff + Vector2(point_offset)
		6: # Diagnal 13
			return Vector2(point.y, point.x) + diff + Vector2(point_offset)
		7: # Diagonal 24
			return Vector2(h - point.y, w - point.x) + diff + Vector2(point_offset)
	return point + diff + Vector2(point_offset)

func _transform_anchor(anchor: Vector2, transformation: int, origin_rect: Rect2i, target_rect: Rect2i) -> Vector2:
	var rel_anchor := anchor - Vector2(origin_rect.position)
	var zero_rect := Rect2i(Vector2i.ZERO, origin_rect.size)
	return _transform_point(rel_anchor, zero_rect, target_rect, transformation, Vector2i.ZERO)

func clear(tile_map_layer: TileMapLayer) -> void:
	clear_tiles.emit(self, tile_map_layer)

func _exit_tree() -> void:
	# Clean up signal connections
	if level and level.changed.is_connected(_on_level_changed):
		level.changed.disconnect(_on_level_changed)

func _load_room(template: String, proxy: GDScript = null) -> Node:
	if not proxy:
		proxy = get_proxy()

	if proxy:
		return proxy.call("load_room", template)
	
	return load(template).instantiate()

func _get_anchor(template: String, proxy: GDScript = null) -> Vector2:
	if not proxy:
		proxy = get_proxy()
	
	if proxy:
		return proxy.call("get_anchor", template)
	
	var anchor := Vector2.ZERO
	var pivot_room_template: PackedScene = load(template)
	var scene_state := pivot_room_template.get_state()
	for i in scene_state.get_node_property_count(0):
		var prop_name := scene_state.get_node_property_name(0, i)
		if prop_name == "metadata/anchor":
			anchor = scene_state.get_node_property_value(0, i)
			break
	
	return anchor

func _get_lnk(template: String, proxy: GDScript = null) -> Dictionary:
	if not proxy:
		proxy = get_proxy()
	
	if proxy:
		return proxy.call("get_lnk", template)
	
	var pivot_room_template: PackedScene = load(template)
	var scene_state := pivot_room_template.get_state()
	for i in scene_state.get_node_property_count(0):
		var prop_name := scene_state.get_node_property_name(0, i)
		if prop_name == "metadata/lnk":
			return scene_state.get_node_property_value(0, i)
	return {}
