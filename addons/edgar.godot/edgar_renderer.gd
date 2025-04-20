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

signal markers_post_process(renderer: EdgarRenderer2D, id: int, tile_map_layer: TileMapLayer, markers: Node)
signal post_process(renderer: EdgarRenderer2D, id: int, tile_map_lauer: TileMapLayer)

var generator: EdgarGodotGenerator
@export_tool_button("Generate Layout") var generator_layout_btn : Callable = _generate_layout
@export var tile_map_layers: Dictionary[int, TileMapLayer] = {}
@export var level: Resource:
	get: return level
	set(v):
		if v == null:
			level = null
		if EdgarGodotGenerator.resource_valid(v):
			level = v
			generator = EdgarGodotGenerator.from_resource(level)
@export var layout: Dictionary
func _generate_layout() -> void:
	layout = generator.generate_layout()
	for room in layout.rooms:
		room["edgar_layer"] = level.get_meta("nodes")[room.room].edgar_layer
		room["is_pivot"] = level.get_meta("nodes")[room.room].is_pivot
	_render()

func _render() -> void:
	if layout == null:
		printerr("[EdgarGodot] Cannot render: layout is null.")
		return
	
	for id in tile_map_layers:
		var tile_map_layer := tile_map_layers[id]
		tile_map_layer.clear()
		var position_offset := Vector2.ZERO
		for room in layout.rooms:
			if position_offset != Vector2.ZERO:
				break
			if room.is_pivot: 
				position_offset = room.position
		for room in layout.rooms:
			var room_template = load(room.template)
			var tmj: Node = room_template.instantiate()
			for child in tmj.get_children():
				if child.name == "col" and child is TileMapLayer:
					if tile_map_layer.tile_set == null: 
						tile_map_layer.tile_set = child.tile_set
					var tml := child as TileMapLayer
					var cells := tml.get_used_cells()
					for cell in cells:
						tile_map_layer.set_cell(cell + Vector2i((room.position - position_offset) / Vector2(tml.tile_set.tile_size)), tml.get_cell_source_id(cell), tml.get_cell_atlas_coords(cell), tml.get_cell_alternative_tile(cell))
				elif child.name == "markers":
					_markers_post_process(id, tile_map_layer, child)
			
			tmj.queue_free()
		_post_process(id, tile_map_layer)

## Do not call `super()` here. [br]
## `super()` will execute `post_process.emit(self)`. [br]
func _post_process(id: int, tile_map_layer: TileMapLayer) -> void:
	post_process.emit(self, id, tile_map_layer)

## Do not call `super()` here. [br]
## `super()` will execute `markers_post_process.emit(self, markers)`. [br]
func _markers_post_process(id: int, tile_map_layer: TileMapLayer, markers: Node) -> void:
	markers_post_process.emit(self, id, tile_map_layer, markers)
