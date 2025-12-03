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

@tool
class_name EdgarRenderer2D
extends Node2D

signal post_process(renderer: EdgarRenderer2D, tile_map_lauer: TileMapLayer, tiled_layer: String)
## data stores coordinates relative to the tile_map_layer instead of world position.
signal marker_post_process(renderer: EdgarRenderer2D, tile_map_layer: TileMapLayer, marker: Node, data: Variant)
signal custom_post_process(renderer: EdgarRenderer2D, tile_map_layer: TileMapLayer, layer: Node)

var generator: EdgarGodotGenerator
@export_tool_button("Generate Layout") var generate_layout_btn : Callable = _generate_layout_and_render
@export_tool_button("Rerender Layout") var rerender_layout_btn : Callable = _render
@export var tile_map_layers: Array[TileMapLayer] = []
@export var level: Resource:
	get: return level
	set(v):
		if v == null:
			level = null
		if EdgarGodotGenerator.resource_valid(v):
			level = v
			generator = EdgarGodotGenerator.from_resource(level)
			generator.inject_seed(seed)
@export var layout: Dictionary
@export var seed: int:
	set(sd):
		seed = sd
		if generator != null:
			generator.inject_seed(seed)

func _generate_layout() -> void:
	layout = generator.generate_layout()
	for room in layout.rooms:
		room["edgar_layer"] = level.get_meta("nodes")[room.room].edgar_layer
		room["is_pivot"] = level.get_meta("nodes")[room.room].is_pivot
	
func _generate_layout_and_render() -> void:
	_generate_layout()
	_render()

func _init() -> void:
	post_process.connect(func(renderer, tml, tiled_layer): _post_process(tml, tiled_layer))
	marker_post_process.connect(func(renderer, tml, marker, data): _marker_post_process(tml, marker, data))
	custom_post_process.connect(func(renderer, tml, layer): _custom_post_process(tml, layer))

func _render() -> void:
	if layout == null:
		printerr("[EdgarGodot] Cannot render: layout is null.")
		return
	
	for tile_map_layer in tile_map_layers:
		tile_map_layer.clear()
		var position_offset := Vector2.ZERO
		for room in layout.rooms:
			if position_offset != Vector2.ZERO:
				break
			if room.is_pivot: 
				position_offset = room.position
		
		var room_exceptions := tile_map_layer.get_meta("room_exceptions", {})
		var room_inclusions := tile_map_layer.get_meta("room_inclusions", {})
		
		var tile_exceptions := tile_map_layer.get_meta("tile_exceptions", {}) as Dictionary
		var tile_inclusions := tile_map_layer.get_meta("tile_inclusions", {}) as Dictionary
		
		var tiled_layer := tile_map_layer.get_meta("tiled_layer", tile_map_layer.name)
		
		for room in layout.rooms:
			var room_template = load(room.template)
			var tmj: Node = room_template.instantiate()
			
			if room.is_pivot:
				var anchor = tmj.get_meta("anchor", Vector2.ZERO)
				position_offset += anchor
			
			tile_map_layer.position = -position_offset * (Vector2(tile_map_layer.tile_set.tile_size) if tile_map_layer.tile_set else Vector2.ONE)
			
			if not room_inclusions.is_empty():
				if room_inclusions.get(room.room, false) == false:
					tmj.queue_free()
					continue
			else:
				if room_exceptions.get(room.room, false) == true:
					tmj.queue_free()
					continue
			
			var lnk := tmj.get_meta("lnk") as Dictionary

			var origin_outline = lnk["boundary"]
			var origin_used_rect := Rect2i(origin_outline[0], Vector2i.ZERO)
			var target_used_rect := Rect2i(room.outline[0] + room.position, Vector2i.ZERO)
			
			var cnt : int = origin_outline.size()
			var i := 0
			while i < cnt:
				var _origin_pt := Vector2i(origin_outline[i])
				origin_used_rect = origin_used_rect.expand(_origin_pt)
				
				var _target_pt := Vector2i(room.outline[i] + room.position)
				target_used_rect = target_used_rect.expand(_target_pt)
				i += 1
			
			var origin_tile_size := Vector2(tmj.get_meta("origin_tile_size", Vector2i.ONE))
			var target_tile_size := Vector2(tile_map_layer.tile_set.tile_size) if tile_map_layer.tile_set else Vector2.ONE
			for child in tmj.get_children():
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
							_transform_cell(cell, origin_used_rect, target_used_rect, room.transformation), 
							source_id, 
							atlas_coord, 
							alternative_tile
						)
				elif child.name == "markers":
					for marker in child.get_children():
						var marker_data : Variant = null
						if marker is Marker2D:
							var spot_position := _transform_point(marker.position / origin_tile_size, origin_used_rect, target_used_rect, room.transformation)
							marker_data = spot_position
						elif marker is Line2D:
							var src_points : PackedVector2Array = marker.points
							var count := src_points.size()
							var points := PackedVector2Array()
							points.resize(count)
							var j := 0
							while j < count:
								points[j] = _transform_point(src_points[j] / origin_tile_size, origin_used_rect, target_used_rect, room.transformation)
								j += 1
							
							marker_data = points
						elif marker is Polygon2D:
							var src_polygon : PackedVector2Array = marker.polygon
							var count := src_polygon.size()
							var points := PackedVector2Array()
							points.resize(count)
							var j := 0
							while j < count:
								points[j] = _transform_point(src_polygon[j] / origin_tile_size, origin_used_rect, target_used_rect, room.transformation)
								j += 1
							
							marker_data = points
						marker_post_process.emit(self, tile_map_layer, marker, marker_data)
				else:
					custom_post_process.emit(self, tile_map_layer, child)
			
			tmj.queue_free()
		
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

# NOTE: origin_used_rect is not transformed, target_used_rect is transformed.
func _transform_cell(cell: Vector2i, origin_used_rect: Rect2i, target_used_rect: Rect2i, transformation: int) -> Vector2i:
	var diff := target_used_rect.position - origin_used_rect.position
	match transformation:
		0: # Identity
			return cell + diff
		1: # Rotate 90
			return Vector2i(origin_used_rect.size.y - 1 - cell.y, cell.x) + diff
		2: # Rotate 180
			return Vector2i(origin_used_rect.size.x - 1 - cell.x, origin_used_rect.size.y - 1 - cell.y) + diff
		3: # Rotate 270
			return Vector2i(cell.y, origin_used_rect.size.x - 1 - cell.x) + diff
		4: # Mirror X
			return Vector2i(origin_used_rect.size.x - 1 - cell.x, cell.y) + diff
		5: # Mirror Y
			return Vector2i(cell.x, origin_used_rect.size.y - 1 - cell.y) + diff
		6: # Diagnal 13
			return Vector2i(cell.y, cell.x) + diff
		7: # Diagonal 24
			return Vector2i(origin_used_rect.size.y - 1 - cell.y, origin_used_rect.size.x - 1 - cell.x) + diff
	return cell + diff

# NOTE: origin_used_rect is not transformed, target_used_rect is transformed.
func _transform_point(point: Vector2, origin_used_rect: Rect2i, target_used_rect: Rect2i, transformation: int) -> Vector2:
	var diff := Vector2(target_used_rect.position - origin_used_rect.position)
	var w := float(origin_used_rect.size.x)
	var h := float(origin_used_rect.size.y)
	match transformation:
		0: # Identity
			return point + diff
		1: # Rotate 90
			return Vector2(h - point.y, point.x) + diff
		2: # Rotate 180
			return Vector2(w - point.x, h - point.y) + diff
		3: # Rotate 270
			return Vector2(point.y, w - point.x) + diff
		4: # Mirror X
			return Vector2(w - point.x, point.y) + diff
		5: # Mirror Y
			return Vector2(point.x, h - point.y) + diff
		6: # Diagnal 13
			return Vector2(point.y, point.x) + diff
		7: # Diagonal 24
			return Vector2(h - point.y, w - point.x) + diff
	return point + diff
