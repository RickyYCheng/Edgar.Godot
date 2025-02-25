@tool
class_name EdgarGraphEdit
extends Control

@onready var graph_edit: GraphEdit = $GraphEdit
@onready var menu_button: MenuButton = $MenuButton

@export var edgar_graph_node_scene : PackedScene 
@export var graph_resource : EdgarGraphResource:
	get: 
		return graph_resource
	set(value):
		if (graph_resource == value): return 
		
		_unload_graph_resource()
		graph_resource = value
		_load_graph_resource()

var graph_nodes : Dictionary[String, GraphNode] = {}

func _unload_graph_resource() -> void:
	if graph_resource == null: return
	
	var nodes_data := {}
	for node_name in graph_nodes:
		nodes_data[node_name] = graph_nodes[node_name].get_data()
	graph_resource.nodes = nodes_data
	graph_resource.edges = graph_edit.connections.map(func (conn): return {"from_node": conn.from_node, "to_node": conn.to_node})
	
	graph_resource.save()
	
	# unload
	_remove_all_nodes(graph_nodes.keys())

func _load_graph_resource() -> void:
	if graph_resource == null: return
	
	for node_name in graph_resource.nodes:
		var node := _add_new_node(node_name)
		node.set_data(graph_resource.nodes[node_name])
	for connection in graph_resource.edges:
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
