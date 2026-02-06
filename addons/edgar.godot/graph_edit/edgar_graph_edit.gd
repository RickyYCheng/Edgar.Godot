# MIT License
#
# Copyright (c) 2025 RickyYC
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
class_name EdgarGraphEdit
extends Control

@onready var graph_edit: GraphEdit = $GraphEdit
@onready var menu_button: MenuButton = $MenuButton
@onready var filename_button: Button = $HBoxContainer/FilenameButton
@onready var add_button: Button = $HBoxContainer/AddButton

@export var edgar_graph_node_scene : PackedScene
var _graph_resource : Resource
@export var graph_resource : Resource:
	get:
		return _graph_resource
	set(value):
		if _graph_resource == value: return

		_unload_graph_resource()
		_graph_resource = value
		_load_graph_resource()
		_update_visibility()

var graph_nodes : Dictionary[String, GraphNode] = {}
var _skip_save := false
var _original_file_path := ""  # Store the original .edgar-graph file path

func _ready() -> void:
	_update_visibility()
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(_on_filesystem_changed)

func _save_graph_resource() -> bool:
	if graph_resource == null: return true

	var file := FileAccess.open(graph_resource.resource_path, FileAccess.WRITE)
	if file == null: return false
	return file.store_string(JSON.stringify({
		"nodes": graph_resource.get_meta("nodes"),
		"edges": graph_resource.get_meta("edges"),
		"layers": graph_resource.get_meta("layers"),
	}))

func save_current_graph() -> void:
	# Explicit save method called by plugin
	if graph_resource == null: return

	var nodes_data := {}
	for node_name in graph_nodes:
		nodes_data[node_name] = graph_nodes[node_name].get_data()
	graph_resource.set_meta("nodes", nodes_data)

	# Safely get connections - use get_connection_list() to avoid internal errors
	var edges_data := []
	var all_conns := graph_edit.get_connection_list()
	for conn in all_conns:
		edges_data.append({"from_node": conn.from_node, "to_node": conn.to_node})

	graph_resource.set_meta("edges", edges_data)
	_save_graph_resource()

func _unload_graph_resource() -> void:
	if graph_resource == null: return

	# Skip saving if the file was deleted
	if not _skip_save:
		var nodes_data := {}
		for node_name in graph_nodes:
			nodes_data[node_name] = graph_nodes[node_name].get_data()
		graph_resource.set_meta("nodes", nodes_data)

		# Safely get connections - use get_connection_list() to avoid internal errors
		var edges_data := []
		var all_conns := graph_edit.get_connection_list()
		for conn in all_conns:
			edges_data.append({"from_node": conn.from_node, "to_node": conn.to_node})

		graph_resource.set_meta("edges", edges_data)
		_save_graph_resource()

	# unload
	_remove_all_nodes(graph_nodes.keys())

func _load_graph_resource() -> void:
	if graph_resource == null: return

	# Try to get the original source file path from metadata
	if graph_resource.has_meta("source_file"):
		_original_file_path = graph_resource.get_meta("source_file")
	else:
		# Fallback: use resource_path directly if it's already an .edgar-graph file
		var resource_path := graph_resource.resource_path
		if resource_path.ends_with(".edgar-graph"):
			_original_file_path = resource_path
		else:
			# Try to parse from .import path
			var original_path := _get_original_source_path(resource_path)
			_original_file_path = original_path if original_path != "" else resource_path

	# Update filename button text immediately
	if _original_file_path != "":
		filename_button.text = _original_file_path
	else:
		filename_button.text = "Unknown File"

	var nodes = graph_resource.get_meta("nodes")
	var edges = graph_resource.get_meta("edges")

	# First, create all nodes
	for node_name in nodes:
		var node := _add_new_node(node_name)
		node.set_data(graph_resource.get_meta("nodes")[node_name])

	# Then, create connections - defer to next frame to ensure nodes are ready
	_connect_edges_deferred.call_deferred(edges)

func _connect_edges_deferred(edges: Array) -> void:
	for connection in edges:
		if graph_nodes.has(connection.from_node) and graph_nodes.has(connection.to_node):
			graph_edit.connect_node(connection.from_node, 0, connection.to_node, 0)

func _on_menu_button_id_pressed(id: int) -> void:
	match id:
		0:  # Add Room Node
			_add_new_node()
		1:  # Delete Node
			# Delete selected nodes
			var nodes_to_delete : Array[StringName] = []
			for node_name in graph_nodes:
				if graph_nodes[node_name].is_selected():
					nodes_to_delete.append(node_name)
			if nodes_to_delete.size() > 0:
				_remove_all_nodes(nodes_to_delete)

func _on_graph_edit_popup_request(at_position: Vector2) -> void:
	# Check if any node is selected
	var has_selection := false
	for node in graph_nodes.values():
		if node.is_selected():
			has_selection = true
			break

	# Update menu item visibility based on selection
	var popup := menu_button.get_popup()
	popup.set_item_disabled(0, false)  # "Add Room Node" is always available
	popup.set_item_disabled(1, not has_selection)  # "Delete Node" only when has selection

	# Show menu at clicked position
	menu_button.position = at_position + Vector2(0, -menu_button.size.y)
	menu_button.show_popup()

func _on_graph_edit_delete_nodes_request(nodes: Array[StringName]) -> void:
	_remove_all_nodes(nodes)

func _add_new_node(node_name:String="") -> GraphNode:
	var node : GraphNode = edgar_graph_node_scene.instantiate()
	node.change_name.connect(
		func(old, new):
			# Defer to avoid accessing GraphEdit during node operations
			_rename_node_deferred.call_deferred(old, new, node)
	)
	graph_edit.add_child(node, true)

	# Use provided name or let Godot generate a unique name
	if not node_name.is_empty():
		node.room_name = node_name
	else:
		# Godot already assigned a unique name like @GraphNode@123
		# Just use it as the room name
		node.room_name = node.name

	node.position_offset = (menu_button.position + graph_edit.scroll_offset) / graph_edit.zoom
	if graph_edit.snapping_enabled:
		node.position_offset = Vector2i(node.position_offset / graph_edit.snapping_distance) * graph_edit.snapping_distance
	graph_nodes[node.name] = node;
	return node

func _rename_node_deferred(old: String, new: String, node: GraphNode) -> void:
	# Safely update connections when node name changes
	# Get all connections and filter for those involving the old node name
	var all_conns := graph_edit.get_connection_list()
	var relevant_conns := []
	for conn in all_conns:
		if conn.from_node == old or conn.to_node == old:
			relevant_conns.append(conn)

	# Disconnect all relevant connections
	for conn in relevant_conns:
		graph_edit.disconnect_node(conn.from_node, conn.from_port, conn.to_node, conn.to_port)

	# Update graph_nodes mapping
	graph_nodes.erase(old)
	graph_nodes[new] = node

	# Reconnect with new node name
	for conn in relevant_conns:
		var new_from : StringName = conn.from_node if conn.from_node != old else new
		var new_to : StringName = conn.to_node if conn.to_node != old else new
		graph_edit.connect_node(new_from, conn.from_port, new_to, conn.to_port)

func _remove_node(node_name:String) -> void:
	if not graph_nodes.has(node_name): return
	var node : Node = graph_nodes[node_name]
	graph_nodes.erase(node_name)
	node.queue_free()

func _remove_all_nodes(nodes:Array) -> void:
	for node_name in nodes: _remove_node(node_name)

func _on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph_edit.connect_node(from_node, from_port, to_node, to_port)

func _on_graph_edit_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)

func _update_visibility() -> void:
	var has_resource := graph_resource != null and graph_resource is Resource and graph_resource.has_meta("is_edgar_graph")

	graph_edit.visible = has_resource
	menu_button.visible = has_resource

	# FilenameButton and AddButton are always visible
	if has_resource:
		filename_button.text = _original_file_path if _original_file_path != "" else "Unknown File"
	else:
		filename_button.text = "Open File"

func _on_add_button_pressed() -> void:
	# Open file dialog to create new .edgar-graph file
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dialog.title = "Create Edgar Graph"
	dialog.add_filter("*.edgar-graph", "Edgar Graph")

	dialog.file_selected.connect(func(path: String):
		dialog.queue_free()
		_create_empty_edgar_graph(path)
	)

	dialog.canceled.connect(func(): dialog.queue_free())

	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered_ratio()

func _create_empty_edgar_graph(path: String) -> void:
	var empty_graph := {
		"nodes": {},
		"edges": [],
		"layers": []
	}
	var json_str := JSON.stringify(empty_graph, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(json_str)
	file.close()

	EditorInterface.get_resource_filesystem().scan()
	# Wait for filesystem to scan the new file
	await EditorInterface.get_resource_filesystem().filesystem_changed

	# Wait for the importer to finish processing the file
	var max_wait_time := 5.0  # Maximum wait time in seconds
	var wait_time := 0.0
	while wait_time < max_wait_time:
		# Give the importer time to process
		await get_tree().process_frame
		wait_time += 0.016  # Approximate frame time

		# Try to load the resource
		var resource := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
		if resource and resource is Resource and resource.has_meta("is_edgar_graph"):
			EditorInterface.edit_resource(resource)
			return

	# If we reach here, the resource couldn't be loaded
	push_error("Failed to load newly created Edgar Graph: %s" % path)

func _on_filename_button_pressed() -> void:
	# Open file dialog to open or switch to another .edgar-graph file
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialog.title = "Open Edgar Graph" if graph_resource == null else "Switch Edgar Graph"
	dialog.add_filter("*.edgar-graph", "Edgar Graph")

	dialog.file_selected.connect(func(path: String):
		dialog.queue_free()
		# Load the new graph
		var resource := ResourceLoader.load(path)
		if resource and resource is Resource and resource.has_meta("is_edgar_graph"):
			graph_resource = resource
	)

	dialog.canceled.connect(func(): dialog.queue_free())

	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered_ratio()

func _on_filesystem_changed() -> void:
	# If _original_file_path is not set, try to get it from current resource
	if _original_file_path == "" and graph_resource != null and graph_resource.has_meta("source_file"):
		_original_file_path = graph_resource.get_meta("source_file")

	# Check if the current resource file still exists
	if _original_file_path != "":
		var file_exists := FileAccess.file_exists(_original_file_path)

		if not file_exists:
			# File was deleted, close the editor without saving
			_skip_save = true
			graph_resource = null
			_original_file_path = ""
			_skip_save = false
			_update_visibility()

func _get_original_source_path(import_path: String) -> String:
	# Convert imported .tres path back to original .edgar-graph path
	# Import path format: res://path/.import/file.edgar-graph-xxxxx.tres
	# Original path: res://path/file.edgar-graph

	if ".import/" not in import_path:
		return ""  # Not an imported file

	var parts := import_path.split("/")

	# Find the .import directory index
	var import_index := parts.find(".import")
	if import_index == -1 or import_index == 0:
		return ""

	# Extract the filename part (after .import/)
	if import_index + 1 >= parts.size():
		return ""

	var filename_part := parts[import_index + 1]  # file.edgar-graph-xxxxx.tres

	# Parse filename: file.edgar-graph-xxxxx.tres
	var dot_split := filename_part.split(".")
	if dot_split.size() < 3:
		return ""

	var original_filename := dot_split[0]  # file
	var extension_with_hash := dot_split[1]  # edgar-graph-xxxxx

	# Remove the hash part (everything after the last dash)
	var extension := extension_with_hash.split("-")[0]  # edgar-graph

	# Reconstruct directory path without .import/
	var dir_parts := parts.slice(0, import_index)
	var result_dir := "/".join(dir_parts)
	if not result_dir.ends_with("/"):
		result_dir += "/"

	return result_dir + original_filename + "." + extension
