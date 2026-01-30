extends Node2D

@export var camera: Camera2D
@export var fow: FogOfWarSprite2D
@export var radius: int = 1

var _last_unfog_coord: Vector2i = Vector2i.MAX
func _process(delta: float) -> void:
	# Move camera using ui_left, ui_right, ui_up, ui_down
	var move_dir := Vector2.ZERO
	if Input.is_action_pressed(&"ui_left"):
		move_dir.x -= 1
	if Input.is_action_pressed(&"ui_right"):
		move_dir.x += 1
	if Input.is_action_pressed(&"ui_up"):
		move_dir.y -= 1
	if Input.is_action_pressed(&"ui_down"):
		move_dir.y += 1

	if move_dir != Vector2.ZERO:
		camera.position += move_dir.normalized() * 200 * delta

	# Unfog area around camera position with radius
	if fow != null:
		var target_coord: Vector2i = fow.global_to_grid(camera.global_position)

		# Only unfog if grid position changed
		if target_coord != _last_unfog_coord:
			if _last_unfog_coord == Vector2i.MAX:
				fow.unfog(target_coord, radius)
			else:
				# Move toward target with step size 1, unfogging along the path
				var current := Vector2(_last_unfog_coord)
				var target := Vector2(target_coord)
				while current != target:
					current = current.move_toward(target, 1.0)
					fow.unfog(Vector2i(current), radius)
			_last_unfog_coord = target_coord
