# MIT License
#
# Copyright (c) 2023-2025 RickyYC
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

@export var edgar_graph_node_scene : PackedScene 
@export var graph_resource : Resource:
	set(value):
		if (graph_resource == value): return 
		
		_unload_graph_resource()
		graph_resource = value
		_load_graph_resource()

var graph_nodes : Dictionary[String, GraphNode] = {}

func _save_graph_resource() -> bool:
	if graph_resource == null: return true
	
	var file := FileAccess.open(graph_resource.resource_path, FileAccess.WRITE)
	if file == null: return false
	return file.store_string(JSON.stringify({
		"nodes": graph_resource.get_meta("nodes"),
		"edges": graph_resource.get_meta("edges"),
		"layers": graph_resource.get_meta("layers"),
	}))

func _unload_graph_resource() -> void:
	if graph_resource == null: return
	
	var nodes_data := {}
	for node_name in graph_nodes:
		nodes_data[node_name] = graph_nodes[node_name].get_data()
	graph_resource.set_meta("nodes", nodes_data)
	graph_resource.set_meta("edges", graph_edit.connections.map(func (conn): return {"from_node": conn.from_node, "to_node": conn.to_node}))
	
	_save_graph_resource()
	
	# unload
	_remove_all_nodes(graph_nodes.keys())

func _load_graph_resource() -> void:
	if graph_resource == null: return
	
	var nodes = graph_resource.get_meta("nodes")
	var edges = graph_resource.get_meta("edges")
	
	for node_name in nodes:
		var node := _add_new_node(node_name)
		node.set_data(graph_resource.get_meta("nodes")[node_name])
	for connection in edges:
		_on_graph_edit_connection_request(connection.from_node, 0, connection.to_node, 0)

func _on_menu_button_id_pressed(id: int) -> void:
	if id == 0: _add_new_node()

func _on_graph_edit_popup_request(at_position: Vector2) -> void:
	menu_button.position = at_position + Vector2(0, -menu_button.size.y)
	menu_button.show_popup()

func _on_graph_edit_delete_nodes_request(nodes: Array[StringName]) -> void:
	_remove_all_nodes(nodes)

func _add_new_node(node_name:String="") -> GraphNode:
	var node : GraphNode = edgar_graph_node_scene.instantiate()
	graph_edit.add_child(node)
	
	node.name = node.name if node_name == "" else node_name
	
	node.position_offset = (menu_button.position + graph_edit.scroll_offset) / graph_edit.zoom
	if graph_edit.snapping_enabled:
		node.position_offset = Vector2i(node.position_offset / graph_edit.snapping_distance) * graph_edit.snapping_distance
	graph_nodes[node.name] = node;
	return node

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
