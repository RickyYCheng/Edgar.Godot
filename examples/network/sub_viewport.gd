extends SubViewport

@export var camera: Camera2D
@export var target: Node2D

var offset: Vector2

func _ready() -> void:
	world_2d = get_tree().root.world_2d
	get_tree().root.set_canvas_cull_mask_bit(1, false)

func _process(delta: float) -> void:
	var scale := camera.zoom
	if Input.is_key_pressed(KEY_EQUAL):
		scale += 2. * delta * Vector2.ONE
	if Input.is_key_pressed(KEY_MINUS):
		scale -= 2. * delta * Vector2.ONE
	
	camera.zoom = scale.clampf(.1, 4)
	
	if Input.is_key_pressed(KEY_LEFT):
		offset += 200 * delta * Vector2.LEFT / camera.zoom
	if Input.is_key_pressed(KEY_RIGHT):
		offset += 200 * delta * Vector2.RIGHT / camera.zoom
	if Input.is_key_pressed(KEY_UP):
		offset += 200 * delta * Vector2.UP / camera.zoom
	if Input.is_key_pressed(KEY_DOWN):
		offset += 200 * delta * Vector2.DOWN / camera.zoom
	
	if Input.is_key_pressed(KEY_PAGEUP) \
	or Input.is_key_pressed(KEY_HOME) \
	or Input.is_key_pressed(KEY_HOMEPAGE):
		offset = Vector2.ZERO
	
	camera.global_position = target.global_position + offset
