class_name NetworkManager
extends Node

#region Network Connections
var _peer : ENetMultiplayerPeer

func start_server(port: int, timeout: float = 60) -> Error:
	match connection_status:
		MultiplayerPeer.CONNECTION_CONNECTED:
			return Error.ERR_ALREADY_IN_USE
		MultiplayerPeer.CONNECTION_CONNECTING:
			close()
		MultiplayerPeer.CONNECTION_DISCONNECTED:
			pass
	
	_peer = ENetMultiplayerPeer.new()
	var err = _peer.create_server(port)
	if err != OK:
		return err
	
	multiplayer.multiplayer_peer = _peer
	
	timeout = Time.get_ticks_msec() + timeout * 1000
	while connection_status == MultiplayerPeer.CONNECTION_CONNECTING:
		await get_tree().process_frame
		if Time.get_ticks_msec() > timeout:
			break
	
	if connection_status != MultiplayerPeer.CONNECTION_CONNECTED:
		close()
		return ERR_CANT_OPEN

	return OK

func start_client(addr: String, port: int, timeout: float = 60) -> Error:
	match connection_status:
		MultiplayerPeer.CONNECTION_CONNECTED:
			return Error.ERR_ALREADY_IN_USE
		MultiplayerPeer.CONNECTION_CONNECTING:
			close()
		MultiplayerPeer.CONNECTION_DISCONNECTED:
			pass
	
	_peer = ENetMultiplayerPeer.new()
	var err = _peer.create_client(addr, port)
	if err != OK:
		return err
	
	multiplayer.multiplayer_peer = _peer
	
	timeout = Time.get_ticks_msec() + timeout * 1000
	while connection_status == MultiplayerPeer.CONNECTION_CONNECTING:
		await get_tree().process_frame
		if Time.get_ticks_msec() > timeout:
			break
	
	if connection_status != MultiplayerPeer.CONNECTION_CONNECTED:
		close()
		return ERR_CANT_CONNECT

	return OK

var peer : MultiplayerPeer:
	get: return _peer

var connection_status: MultiplayerPeer.ConnectionStatus:
	get: 
		if _peer == null:
			return MultiplayerPeer.CONNECTION_DISCONNECTED
		return MultiplayerPeer.CONNECTION_DISCONNECTED if multiplayer.multiplayer_peer != _peer else _peer.get_connection_status()

func close() -> void: 
	if _peer:
		_peer.close()
	_peer = null
	multiplayer.multiplayer_peer = null

func until_status(status: MultiplayerPeer.ConnectionStatus) -> void:
	while connection_status != status:
		await get_tree().process_frame

func check_status(status: MultiplayerPeer.ConnectionStatus) -> bool:
	return connection_status == status

#endregion

#region Task Broadcasting

signal task_timeout(task_id: int, timed_out_peers: PackedInt32Array)

enum BroadcastOption { 
	PEERS, ## [code]PackedInt32Array[/code]
	HOST_EXECUTES, ## [code]bool[/code]
	TIMEOUT, ## [code]float[/code]
	ARGS, ## [code]Array[/code]
}

var _pending_tasks: Dictionary = {}
var _next_task_id: int = 0

func broadcast_task(task: Callable, options: Dictionary = {}) -> int:
	if _peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return -1
	if not multiplayer.is_server():
		return -1
	
	var task_object := task.get_object() as Node
	if not task_object:
		return -1
	
	var peers: PackedInt32Array = options.get(BroadcastOption.PEERS, multiplayer.get_peers())
	var host_executes: bool = options.get(BroadcastOption.HOST_EXECUTES, true)
	var timeout: float = options.get(BroadcastOption.TIMEOUT, 10.0)
	var args_array: Array = options.get(BroadcastOption.ARGS, [])
	
	var task_id: int = _next_task_id
	_next_task_id += 1
	
	var expected: int = peers.size() + int(host_executes)
	_pending_tasks[task_id] = {
		"expected": expected,
		"received": 0,
		"confirmed_peers": [],
		"target_peers": peers,
		"start_time": Time.get_ticks_msec(),
		"timeout_ms": int(timeout * 1000),
	}
	
	var object_path: NodePath = task_object.get_path()
	var method_name: StringName = task.get_method()
	
	for peer_id: int in peers:
		_execute_task.rpc_id(peer_id, task_id, object_path, method_name, args_array)
	
	if host_executes:
		_execute_host_task(task_id, task, args_array)
	
	return task_id

func _execute_host_task(task_id: int, task: Callable, args: Array) -> void:
	await task.callv(args)
	_on_task_completed(task_id, 1)

func is_task_completed(task_id: int) -> bool:
	return not _pending_tasks.has(task_id)

func until_task_completion(task_id: int) -> void:
	while true:
		if is_task_completed(task_id):
			break
		await get_tree().process_frame

@rpc("authority", "reliable")
func _execute_task(task_id: int, object_path: NodePath, method_name: StringName, args: Array) -> void:
	var target: Node = get_node_or_null(object_path)
	if target:
		await target.callv(method_name, args)
	_confirm_completion.rpc_id(1, task_id)

@rpc("any_peer", "reliable")
func _confirm_completion(task_id: int) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	_on_task_completed(task_id, sender_id)

func _on_task_completed(task_id: int, from_peer: int) -> void:
	if not multiplayer.is_server():
		return
	
	if not _pending_tasks.has(task_id):
		return
	
	var task: Dictionary = _pending_tasks[task_id]
	
	if from_peer in task["confirmed_peers"]:
		return
	
	task["confirmed_peers"].append(from_peer)
	task["received"] += 1
	
	if task["received"] >= task["expected"]:
		_pending_tasks.erase(task_id)

func _on_peer_disconnected(peer_id: int) -> void:
	for task_id: int in _pending_tasks.keys():
		var task: Dictionary = _pending_tasks[task_id]
		if peer_id in task["confirmed_peers"]:
			continue
		task["expected"] -= 1
		if task["received"] >= task["expected"]:
			_pending_tasks.erase(task_id)

func _process(_delta: float) -> void:
	if connection_status == MultiplayerPeer.CONNECTION_CONNECTED and multiplayer.is_server():
		return
	
	_check_task_timeouts()

func _check_task_timeouts() -> void:
	var now := Time.get_ticks_msec()
	for task_id: int in _pending_tasks.keys():
		var task: Dictionary = _pending_tasks[task_id]
		if now - task["start_time"] > task["timeout_ms"]:
			_handle_task_timeout(task_id)

func _handle_task_timeout(task_id: int) -> void:
	if not _pending_tasks.has(task_id):
		return
	
	var task: Dictionary = _pending_tasks[task_id]
	var timed_out_peers: PackedInt32Array = []
	
	for peer_id: int in task["target_peers"]:
		if peer_id not in task["confirmed_peers"]:
			timed_out_peers.append(peer_id)
			_peer.disconnect_peer(peer_id)
	
	task_timeout.emit(task_id, timed_out_peers)
	_pending_tasks.erase(task_id)

#endregion
