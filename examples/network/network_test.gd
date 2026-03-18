@tool
extends Node2D

@export var camera: Camera2D
@export var edgar_renderer: EdgarRenderer2D
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	await get_tree().process_frame
	edgar_renderer.generate_layout()
	edgar_renderer.render()

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	# Handle one-time key presses (toggle operations)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_G:
				edgar_renderer.generate_layout()
				edgar_renderer.render()

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
