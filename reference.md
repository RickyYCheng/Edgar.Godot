# Edgar.Godot Reference

## Layers
"col": The main brick layer of the map. 
"markers": The marker layer for defining special objects for later use.
"lnk": The layer defining the topology of room connections.

### lnk
> [!IMPORTANT]
> `lnk` is used to define the topology of the room connections, which is a object layer.  
> Only the first object in the layer is considered.  

A valid `lnk` layer should be:
1. name = "lnk"

#### Boundary
A valid `Boundary` should be:
1. class = "polygon" (built-in in `YATI`, not `Edgar.Godot`)
2. properties:
    - `lnk` = "boundary"

#### Door
A valid `Door` should be:
1. class = "line" (built-in in `YATI`, not `Edgar.Godot`)
2. properties:
    - `lnk` = "door"

> [!NOTE]
> The `Door` objects is a polyline with multiple segments.  
> Each segment is considered as the length of the door.  
> Example: The total height of the opening is 6, the usable height of a single door is 2. The default segments are [0,2], [2,4], [4,6], so the cooperative movement step between the two rooms is 2.  
> If an additional independent `Door` is added with overlapping segments [1,3], [3,5], then the full set of usable segments becomes [0,2], [1,3], [2,4], [3,5], [4,6], and the minimal alignment step decreases to 1. This makes the movement unit along that edge smaller, increases the number of alignment positions, and enriches possible generation combinations.  
> Summary: Adding overlapping segments reduces the minimal step size, enabling finer control and more generation possibilities.

#### Anchor
A valid `Anchor` should be:
1. name = "anchor"

> [!NOTE]
> An `Anchor` marks the pivot point of a room.
> During rendering, the position of each `TileMapLayer` is offset by the anchor of the **pivot room**.

## Filters
A filter is a function to determine which tiles or rooms should be rendered in the final map. This is especially useful when you have multiple layers in Tiled but only want to render specific parts in Godot, e.g., multi-layered tilemaps.  

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
