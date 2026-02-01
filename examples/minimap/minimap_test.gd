@tool
extends Node2D

@export var reveal_radius: int = 8
@export var camera: Camera2D
@export var edgar_renderer: EdgarRenderer2D
@export var fog_of_war: FogOfWarSprite2D

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	await get_tree().process_frame
	edgar_renderer.generate_layout()
	edgar_renderer.render()

var _last_coord: Vector2i = Vector2i.MAX
func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	# Handle one-time key presses (toggle operations)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_V:
				fog_of_war.visible = not fog_of_war.visible
			KEY_R:
				fog_of_war.refog_all()
				_last_coord = Vector2i.MAX
			KEY_U:
				fog_of_war.unfog_all()
			KEY_G:
				edgar_renderer.generate_layout()
				edgar_renderer.render()
				fog_of_war.refog_all()
				_last_coord = Vector2i.MAX

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	# Move camera using ui_left, ui_right, ui_up, ui_down
	var move_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		move_dir.x -= 1
	if Input.is_key_pressed(KEY_D):
		move_dir.x += 1
	if Input.is_key_pressed(KEY_W):
		move_dir.y -= 1
	if Input.is_key_pressed(KEY_S):
		move_dir.y += 1

	if move_dir != Vector2.ZERO:
		camera.position += move_dir.normalized() * 200 * delta

	if _last_coord == Vector2i.MAX:
		fog_of_war.unfog(fog_of_war.global_to_grid(camera.global_position), reveal_radius)
		_last_coord = Vector2(fog_of_war.global_to_grid(camera.global_position))
	else:
		var _from_coord := Vector2(_last_coord)
		var _curr_coord := Vector2(fog_of_war.global_to_grid(camera.global_position))
		while _from_coord != _curr_coord:
			_from_coord = _from_coord.move_toward(_curr_coord, 1)
			fog_of_war.unfog(_from_coord, reveal_radius)
		_last_coord = _curr_coord

func _on_edgar_renderer_2d_post_process(renderer: EdgarRenderer2D, tile_map_layer: TileMapLayer, tiled_layer: String) -> void:
	if Engine.is_editor_hint():
		return
	if tile_map_layer.tile_set.resource_name != "old_tile_set":
		return
	if not fog_of_war:
		return

	var tile_size := tile_map_layer.tile_set.tile_size

	# Calculate maximum AABB across all rooms
	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF

	for room in renderer.layout.rooms:
		var pos := room.position as Vector2
		var outline := room.outline as PackedVector2Array
		var tf := Transform2D(0, pos + tile_map_layer.global_position / Vector2(tile_size))
		var poly := tf * outline

		for point in poly:
			min_x = min(min_x, point.x)
			min_y = min(min_y, point.y)
			max_x = max(max_x, point.x)
			max_y = max(max_y, point.y)

	# Create AABB in tile coordinates
	var aabb_tile := Rect2(min_x, min_y, max_x - min_x, max_y - min_y)

	# Calculate pixel dimensions
	var fow_width := int(aabb_tile.size.x * tile_size.x)
	var fow_height := int(aabb_tile.size.y * tile_size.y)

	# Calculate target AABB in world space
	var target_world_min := Vector2(min_x, min_y) * Vector2(tile_size)
	var target_world_max := Vector2(max_x, max_y) * Vector2(tile_size)
	var target_rect := Rect2(target_world_min, target_world_max - target_world_min)

	# Update FogOfWar dimensions
	fog_of_war.tile_size = int(tile_size.x)
	fog_of_war.width = fow_width
	fog_of_war.height = fow_height

	# Align FogOfWar with target rect
	var fow_rect: Rect2 = fog_of_war.get_global_rect()
	var position_offset: Vector2 = target_rect.position - fow_rect.position
	fog_of_war.global_position += position_offset
