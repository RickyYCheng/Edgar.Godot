@tool
class_name FogOfWarSprite2D
extends Sprite2D

@export_range(1, 16384) var tile_size := 24:
	set(v):
		tile_size = v
		_update_tile_set()
		
@export_range(1, 16384) var width := 1152:
	set(v):
		width = v
		_update_dimensions()
@export_range(1, 16384) var height := 648:
	set(v):
		height = v
		_update_dimensions()
func _update_dimensions() -> void:
	if _viewport:
		_viewport.size.x = width
	if _sprite:
		_sprite.texture.width = width
	grid_cols = width / tile_size

	if _viewport:
		_viewport.size.y = height
	if _sprite:
		_sprite.texture.height = height
	grid_rows = height / tile_size
func _update_tile_set() -> void:
	if width != 0 and height != 0:
		grid_rows = height / tile_size
		grid_cols = width / tile_size
	if _sprite and _sprite.material:
		var brush := _sprite.material.get_shader_parameter("add_texture") as GradientTexture2D
		brush.width = tile_size
		brush.height = tile_size

@export_group("Resources")
@export var fog_show_shader: Shader:
	get():
		if not fog_show_shader:
			fog_show_shader = preload("res://addons/edgar.godot/fog_of_war/fow_show.gdshader")
		return fog_show_shader
@export var fog_blur_shader: Shader:
	get():
		if not fog_blur_shader:
			fog_blur_shader = preload("res://addons/edgar.godot/fog_of_war/fow_blur.gdshader")
		if not material:
			material = ShaderMaterial.new()
			material.shader = fog_blur_shader
		return fog_blur_shader

var _dirty: bool = false
var grid: PackedByteArray:
	set(v):
		grid = v
		_dirty = true
var grid_cols: int:
	set(v):
		grid_cols = v
		if _sprite and _sprite.material:
			_sprite.material.set_shader_parameter(&"cols", grid_cols)
var grid_rows: int:
	set(v):
		grid_rows = v
		if _sprite and _sprite.material:
			_sprite.material.set_shader_parameter(&"rows", grid_rows)

var _sprite: Sprite2D
var _viewport: SubViewport

func _setup() -> void:
	_update_tile_set()
	_create_viewport()
	texture = _viewport.get_texture()
	_create_sprite_content()
	if not Engine.is_editor_hint():
		_initialize_grid_data()

func _create_viewport() -> void:
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.handle_input_locally = false
	_viewport.size = Vector2i(width, height)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

func _create_sprite_content() -> void:
	# Create base gradient texture for Sprite2D
	var base_gradient := Gradient.new()
	base_gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	base_gradient.add_point(0, Color(1, 1, 1, 0))
	var base_texture := GradientTexture2D.new()
	base_texture.gradient = base_gradient
	base_texture.width = width
	base_texture.height = height

	# Create brush gradient texture
	var brush_gradient := Gradient.new()
	brush_gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	brush_gradient.add_point(0, Color(0, 0, 0, 1))
	var brush_texture := GradientTexture2D.new()
	brush_texture.gradient = brush_gradient
	brush_texture.width = tile_size * 1.1
	brush_texture.height = tile_size * 1.1
	brush_texture.fill_from = Vector2(0.5, 0.5)

	# Create shader material for Sprite2D
	var shader_material := ShaderMaterial.new()
	shader_material.shader = fog_show_shader
	shader_material.set_shader_parameter(&"add_texture", brush_texture)
	shader_material.set_shader_parameter(&"cols", grid_cols)
	shader_material.set_shader_parameter(&"rows", grid_rows)
	shader_material.set_shader_parameter(&"grid_data", PackedInt32Array())

	# Create Sprite2D
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.material = shader_material
	_sprite.texture = base_texture
	_sprite.centered = false
	_viewport.add_child(_sprite)

func _initialize_grid_data() -> void:
	var byte_size := ((grid_cols * grid_rows + 7) / 8 + 3) & ~3  # Align to 4 bytes
	grid.resize(byte_size)
	grid.fill(0)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			texture = null
		NOTIFICATION_EDITOR_POST_SAVE:
			texture = _viewport.get_texture()

func _ready() -> void:
	_setup()

func _process(delta: float) -> void:
	if _dirty:
		_dirty = false
		update_shader_grid_data()

func local_to_grid(local_pos: Vector2) -> Vector2i:
	var texture_rect_pos := Vector2(-width / 2., -height / 2.) if centered else Vector2.ZERO
	var img_x := int(local_pos.x - texture_rect_pos.x)
	var img_y := int(local_pos.y - texture_rect_pos.y)
	return Vector2i(img_x / tile_size, img_y / tile_size)

func global_to_grid(global_pos: Vector2) -> Vector2i:
	var local_pos := to_local(global_pos)
	return local_to_grid(local_pos)

## Remove fog at the given grid coordinate with optional radius
func unfog(coord: Vector2i, radius: int = 0) -> void:
	_fog_radius(coord, radius, true)

## Add fog at the given grid coordinate with optional radius
func refog(coord: Vector2i, radius: int = 0) -> void:
	_fog_radius(coord, radius, false)

## Remove fog in the given polygon area (in grid coordinates)
func unfog_area(polygon: PackedVector2Array) -> void:
	_fog_area(polygon, true)

## Add fog in the given polygon area (in grid coordinates)
func refog_area(polygon: PackedVector2Array) -> void:
	_fog_area(polygon, false)

## Update the shader parameter with current grid data
func update_shader_grid_data() -> void:
	if _sprite and _sprite.material:
		_sprite.material.set_shader_parameter(&"grid_data", grid.to_int32_array())

func _fog_radius(coord: Vector2i, radius: int, set_unfog: bool) -> void:
	if radius == 0:
		if coord.x < 0 or coord.x >= grid_cols or coord.y < 0 or coord.y >= grid_rows:
			return

		var idx := coord.y * grid_cols + coord.x
		var byte_idx := idx >> 3
		var bit_mask := 1 << (idx & 7)
		if set_unfog:
			grid[byte_idx] |= bit_mask
		else:
			grid[byte_idx] &= ~bit_mask
		return

	var radius_squared := radius * radius
	var dy := -radius
	while dy <= radius:
		var dx := -radius
		while dx <= radius:
			if dx * dx + dy * dy <= radius_squared:
				var cell_coord := coord + Vector2i(dx, dy)
				if cell_coord.x >= 0 and cell_coord.x < grid_cols and cell_coord.y >= 0 and cell_coord.y < grid_rows:
					var idx := cell_coord.y * grid_cols + cell_coord.x
					var byte_idx := idx >> 3
					var bit_mask := 1 << (idx & 7)
					if set_unfog:
						grid[byte_idx] |= bit_mask
					else:
						grid[byte_idx] &= ~bit_mask
			dx += 1
		dy += 1

func _fog_area(polygon: PackedVector2Array, set_unfog: bool) -> void:
	if polygon.is_empty():
		return

	# Find bounding box in grid coordinates
	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF

	for point in polygon:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)

	# Clamp to grid bounds
	var min_grid_x: int = max(0, int(min_x))
	var max_grid_x: int = min(grid_cols - 1, int(max_x))
	var min_grid_y: int = max(0, int(min_y))
	var max_grid_y: int = min(grid_rows - 1, int(max_y))

	# Iterate through all cells in bounding box
	var y: int = min_grid_y
	while y <= max_grid_y:
		var x: int = min_grid_x
		while x <= max_grid_x:
			# Test if cell center is inside or on edge of polygon
			var cell_center := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(cell_center, polygon):
				var idx: int = y * grid_cols + x
				var byte_idx: int = idx >> 3
				var bit_mask: int = 1 << (idx & 7)

				if set_unfog:
					grid[byte_idx] |= bit_mask
				else:
					grid[byte_idx] &= ~bit_mask
			x += 1
		y += 1
