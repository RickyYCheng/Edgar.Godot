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

@export var graph_edit: GraphEdit
@export var menu_button: MenuButton

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

	var layers_data := graph_resource.get_meta("layers", [])
	# Strip empty trailing layers to keep JSON clean
	while not layers_data.is_empty() and layers_data[layers_data.size() - 1].is_empty():
		layers_data.pop_back()

	var layer_names: Array = graph_resource.get_meta("layer_names", [])

	var file := FileAccess.open(graph_resource.resource_path, FileAccess.WRITE)
	if file == null: return false
	return file.store_string(JSON.stringify({
		"nodes": graph_resource.get_meta("nodes"),
		"edges": graph_resource.get_meta("edges"),
		"layers": layers_data,
		"layer_names": layer_names,
	}))

func save_current_graph() -> void:
	# Explicit save method called by plugin
	if graph_resource == null: return

	var nodes_data := {}
	for node_name in graph_nodes:
		nodes_data[node_name] = graph_nodes[node_name].get_data()

	# Safely get connections - use get_connection_list() to avoid internal errors
	var edges_data := []
	var all_conns := graph_edit.get_connection_list()
	for conn in all_conns:
		edges_data.append({"from_node": conn.from_node, "to_node": conn.to_node})

	# Check if data actually changed
	var old_nodes = graph_resource.get_meta("nodes", {})
	var old_edges = graph_resource.get_meta("edges", [])
	var has_changes: bool = not (nodes_data.hash() == old_nodes.hash() and edges_data.hash() == old_edges.hash())

	graph_resource.set_meta("nodes", nodes_data)
	graph_resource.set_meta("edges", edges_data)
	_save_graph_resource()

	# Only emit changed if data actually changed
	if has_changes:
		graph_resource.emit_changed()

func get_layers() -> Array:
	if graph_resource == null:
		return []
	return graph_resource.get_meta("layers", [])

func set_layers(layers: Array) -> void:
	if graph_resource == null:
		return
	graph_resource.set_meta("layers", layers)

func get_layer_names() -> Array:
	if graph_resource == null:
		return []
	return graph_resource.get_meta("layer_names", [])

func set_layer_names(names: Array) -> void:
	if graph_resource == null:
		return
	graph_resource.set_meta("layer_names", names)

func handle_layer_deleted(deleted_index: int) -> void:
	"""Reassign node layer indices after a layer is deleted.
	Nodes on the deleted layer move to layer 0.
	Nodes above the deleted layer shift down by 1."""
	for node_name in graph_nodes:
		var node: EdgarGraphNode = graph_nodes[node_name]
		var current_layer: int = node.edgar_layer_button.selected
		if current_layer == deleted_index:
			node.edgar_layer_button.select(0)
		elif current_layer > deleted_index:
			node.edgar_layer_button.select(current_layer - 1)

func refresh_node_layer_options() -> void:
	"""Update all node layer dropdowns from current resource data."""
	var layer_names := get_layer_names()
	for node_name in graph_nodes:
		var node: EdgarGraphNode = graph_nodes[node_name]
		node.refresh_layer_options(layer_names)

func _unload_graph_resource() -> void:
	if graph_resource == null: return

	# Skip saving if the file was deleted
	if not _skip_save:
		var nodes_data := {}
		for node_name in graph_nodes:
			nodes_data[node_name] = graph_nodes[node_name].get_data()

		# Safely get connections - use get_connection_list() to avoid internal errors
		var edges_data := []
		var all_conns := graph_edit.get_connection_list()
		for conn in all_conns:
			edges_data.append({"from_node": conn.from_node, "to_node": conn.to_node})

		# Check if data actually changed
		var old_nodes = graph_resource.get_meta("nodes", {})
		var old_edges = graph_resource.get_meta("edges", [])
		var has_changes: bool = not (nodes_data.hash() == old_nodes.hash() and edges_data.hash() == old_edges.hash())

		graph_resource.set_meta("nodes", nodes_data)
		graph_resource.set_meta("edges", edges_data)
		_save_graph_resource()

		# Only emit changed if data actually changed
		if has_changes:
			graph_resource.emit_changed()

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

	var nodes = graph_resource.get_meta("nodes")
	var edges = graph_resource.get_meta("edges")
	var layer_names := get_layer_names()

	# First, create all nodes
	for node_name in nodes:
		var node := _add_new_node(node_name)
		node.set_data(graph_resource.get_meta("nodes")[node_name])
		node.refresh_layer_options(layer_names)

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

	# Set layer options for new node
	node.refresh_layer_options(get_layer_names())

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
