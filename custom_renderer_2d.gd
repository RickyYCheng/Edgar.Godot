@tool
extends EdgarRenderer2D

func _post_process(id: int, tile_map_layer: TileMapLayer) -> void:
	match id:
		1:
			var blocks := tile_map_layer.get_used_cells_by_id(0, Vector2(0, 0))
			var platforms := tile_map_layer.get_used_cells_by_id(0, Vector2(1, 0))
			var ladders := tile_map_layer.get_used_cells_by_id(0, Vector2(2, 0))
			var slopes_l := tile_map_layer.get_used_cells_by_id(0, Vector2(3, 0))
			var slopes_r := tile_map_layer.get_used_cells_by_id(0, Vector2(4, 0))
			
			tile_map_layer.clear()

			tile_map_layer.set_cells_terrain_connect(blocks, 0, 0)
			tile_map_layer.set_cells_terrain_connect(platforms, 0, 1)
			tile_map_layer.set_cells_terrain_connect(ladders, 0, 2)
			tile_map_layer.set_cells_terrain_connect(slopes_l, 0, 3)
			tile_map_layer.set_cells_terrain_connect(slopes_r, 0, 4)
		_:
			pass
