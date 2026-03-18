@tool
extends Node2D

@export var camera: Camera2D
@export var edgar_renderer: EdgarRenderer2D
@export var network_manager: NetworkManager
@export var status_label: Label

func _ready() -> void:
	if Engine.is_editor_hint():
		return

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	# Handle one-time key presses (toggle operations)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_G:
				edgar_renderer.generate_layout()
				edgar_renderer.render()
			KEY_H:
				network_manager.start_server(12345)
			KEY_J:
				network_manager.start_client("localhost", 12345)
			KEY_C:
				network_manager.close()

func _update_status() -> void:
	var status_text := "Status: "
	match network_manager.connection_status:
		MultiplayerPeer.CONNECTION_CONNECTED:
			if multiplayer.is_server():
				status_text += "Hosting (Port 12345)"
			else:
				status_text += "Connected to localhost:12345"
		MultiplayerPeer.CONNECTION_CONNECTING:
			status_text += "Connecting..."
		MultiplayerPeer.CONNECTION_DISCONNECTED:
			status_text += "Disconnected"
	status_label.text = status_text

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	_update_status()
	
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
