# Edgar.Godot Reference

## Layers
"col": The main brick layer of the map.  
"markers": The marker layer for defining special objects for later use.  
"lnk": The layer defining the topology of room connections.  
xxx: Custom layers defined by the user.

### lnk
> [!IMPORTANT]
> `lnk` is used to define the topology of the room connections, which is a object layer.  
> Only the first object in the layer is considered.  

A valid `lnk` layer should be:
1. name = "lnk"

#### Boundary
A valid `Boundary` should be:
1. class = "polygon" (built-in in `YATI`, not `Edgar.Godot`)
2. property `lnk` = "boundary" or name = "Boundary"

#### Door
A valid `Door` should be:
1. class = "line" (built-in in `YATI`, not `Edgar.Godot`)
2. property `lnk` = "door"

> [!NOTE]
> The `Door` objects is a polyline with multiple segments.  
> Each segment is considered as the length of the door.  
> Example: The total height of the opening is 6, the usable height of a single door is 2. The default segments are [0,2], [2,4], [4,6], so the cooperative movement step between the two rooms is 2.  
> If an additional independent `Door` is added with overlapping segments [1,3], [3,5], then the full set of usable segments becomes [0,2], [1,3], [2,4], [3,5], [4,6], and the minimal alignment step decreases to 1. This makes the movement unit along that edge smaller, increases the number of alignment positions, and enriches possible generation combinations.  
> Summary: Adding overlapping segments reduces the minimal step size, enabling finer control and more generation possibilities.

#### Anchor
A valid `Anchor` should be:
1. property `lnk` = "anchor" or name = "Anchor"

> [!NOTE]
> An `Anchor` marks the pivot point of a room.
> During rendering, the position of each `TileMapLayer` is offset by the anchor of the **pivot room**.

#### Transformations
To enable transformations, add the following meta-data to the `lnk` layer:
1. `transformations`: A string json containing the transformation parameters.
	- e.g. `[0, 4]`

> [!NOTE]
> 0: Identity  
> 1: Rotate90  
> 2: Rotate180  
> 3: Rotate270  
> 4: MirrorX  
> 5: MirrorY  
> 6: Diagnal13  
> 7: Diagnal24  

#### Tile Swapping
Most of the time, you would want to re-map / swap the tiles according to the transformation applied to the room.  
To achieve this, you can use tile meta-data to define the swapping rules.  

> [!IMPORTANT]
> These properties must be defined on the **Tileset** in the **Tiled Map Editor**, specifically on the individual tiles themselves.

For example, `tileswap4` = `Color(source_id, atlas_x, atlas_y, alternative_tile)` defines the swapping rule for MirrorX (4) transformation.  
When a tile is rendered in a room with MirrorX transformation, it will be swapped to the tile defined in the `tileswap4` meta-data.

### col
See "col" in Renderer section for details.

## Renderer

A renderer converts an Edgar.Godot layout into Godot nodes (typically `TileMapLayer`). It supports tile and room filtering via metadata and emits signals for post‑processing.

### col
The `col` layer is the brick layer of the map. Obviously, there should be multiple `col` layers if the map has multiple tilemaps.  

To achieve this, you need to set the meta-data `tiled_layer` on each `TileMapLayer` node of a renderer, specifying which Tiled layer it corresponds to.  

For example, if you have two tilemaps in Tiled named "Ground" and "Decorations", you would create two `TileMapLayer` nodes under the renderer, each with the `tiled_layer` meta-data set to "Ground" and "Decorations" respectively.

> [!NOTE]
> For simplicity, you can name the `TileMapLayer` nodes the same as their corresponding Tiled layers. For example, a `TileMapLayer` node named "col" would have the `tiled_layer` meta-data set to "col".

### Signals
- `post_process(renderer: EdgarRenderer2D, tile_map_layer: TileMapLayer, tiled_layer: String)`
- `marker_post_process(renderer: EdgarRenderer2D, tile_map_layer: TileMapLayer, marker: Node)`
- `custom_post_process(renderer: EdgarRenderer2D, tile_map_layer: TileMapLayer, layer: Node)`

You can connect to or await these signals to run custom logic after rendering.

#### Ways to integrate

1) Script-based (override methods)
- Extend `EdgarRenderer2D` and override:
```gdscript
extends EdgarRenderer2D

func _post_process(tile_map_layer: TileMapLayer, tiled_layer: String) -> void:
	# Custom per-layer post-processing
	pass

func _marker_post_process(tile_map_layer: TileMapLayer, marker: Node) -> void:
	# Custom marker post-processing
	pass

func _custom_post_process(tile_map_layer: TileMapLayer, layer: Node) -> void:
	pass
```
- Alternatively, implement hooks directly on a `TileMapLayer`. The renderer will detect and call them:
```gdscript
# On the TileMapLayer script
func _post_process(renderer: EdgarRenderer2D, tiled_layer: String) -> void:
	# Adjust this layer after rendering
	pass
```

> [!NOTE]
> Overrides are executed via signals under the hood, so you can still `await` them even when using the override approach.

2) Signal-based (connect handlers)


## Filters
A filter is a set of conditions to determine which tiles or rooms should be rendered in the final map. This is especially useful when you have multiple layers in Tiled but only want to render specific parts in Godot, e.g., multi-layered tilemaps.  

### Tile Filters
To enable a tile filter, add the following meta-data to the target `TileMapLayer` node of a renderer:  
1. `tile_exceptions`: An `Dictionary[Vector4i, bool]` to filter the tiles that you do not want to render.  
2. `tile_inclusions`: An `Dictionary[Vector4i, bool]` to filter the tiles that you do **only** want to render.  

> [!NOTE]
> You can only use either `tile_exceptions` or `tile_inclusions` at a time.  
> If both are provided, only `tile_inclusions` will be considered.  

> [!IMPORTANT]
> The key of the dictionaries should be a `Vector4i` representing the tile's source ID and alternative tile, formatted as `(source_id: int, atlas_coord: Vector2i, alternative_tile: int)`.  

### Room Filters
To enable a room filter, add the following meta-data to the target `TileMapLayer` node of a renderer:  
1. `room_exceptions`: An `Dictionary[String, bool]` to filter the rooms that you do not want to render.  
2. `room_inclusions`: An `Dictionary[String, bool]` to filter the rooms that you do **only** want to render.

> [!NOTE]
> You can only use either `room_exceptions` or `room_inclusions` at a time.  
> If both are provided, only `room_inclusions` will be considered.  

### Layer filter
See "col" in Renderer section for details.
