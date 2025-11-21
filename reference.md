# Edgar.Godot Reference

## Lnk
> [!IMPORTANT]
> `Lnk` is used to define the topology of the room connections, which is a object layer.  
> Only the first object in the layer is considered.  

A valid `Lnk` layer should have:
1. class = "Lnk"
2. properties:
    - `lnk` = "lnk"

### Boundary
A valid `Boundary` should have:
1. class = "polygon" (built-in in `YATI`, not `Edgar.Godot`)
2. properties:
    - `lnk` = "boundary"

### Door
A valid `Door` should have:
1. class = "line" (built-in in `YATI`, not `Edgar.Godot`)
2. properties:
    - `lnk` = "door"

> [!NOTE]
> The `Door` objects is a polyline with multiple segments.  
> Each segment is considered as the length of the door.  
> Example: The total height of the opening is 6, the usable height of a single door is 2. The default segments are [0,2], [2,4], [4,6], so the cooperative movement step between the two rooms is 2.  
> If an additional independent `Door` is added with overlapping segments [1,3], [3,5], then the full set of usable segments becomes [0,2], [1,3], [2,4], [3,5], [4,6], and the minimal alignment step decreases to 1. This makes the movement unit along that edge smaller, increases the number of alignment positions, and enriches possible generation combinations.  
> Summary: Adding overlapping segments reduces the minimal step size, enabling finer control and more generation possibilities.

## Filters
A filter is a function to determine which tiles or rooms should be rendered in the final map. This is especially useful when you have multiple layers in Tiled but only want to render specific parts in Godot, e.g., multi-layered tilemaps.  

### Tile Filters
To enable a tile filter, add the following meta-data to the target `TileMapLayer` node of a renderer:  
1. `tile_exceptions`: An array or a dictionary of int to filter the tiles that you do not want to render.  
2. `tile_inclusions`: An array or a dictionary of int to filter the tiles that you do **only** want to render.  

> [!IMPORTANT]
> You can only use either `tile_exceptions` or `tile_inclusions` at a time.  
> If both are provided, only `tile_inclusions` will be considered.  

### Room Filters
To enable a room filter, add the following meta-data to the target `TileMapLayer` node of a renderer:  
1. `room_exceptions`: An array or a dictionary of string to filter the rooms that you do not want to render.  
2. `room_inclusions`: An array or a dictionary of string to filter the rooms that you do **only** want to render.

> [!IMPORTANT]
> You can only use either `room_exceptions` or `room_inclusions` at a time.  
> If both are provided, only `room_inclusions` will be considered.  
