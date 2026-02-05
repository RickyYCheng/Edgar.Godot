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
extends EditorPlugin

var importer = null
var edgar_graphedit : EdgarGraphEdit
var edgar_graphedit_button : Button

func _handles(object: Object) -> bool:
	return object is Resource and object.has_meta("is_edgar_graph")

func _apply_changes() -> void:
	# Called when user presses Ctrl+S to save
	if edgar_graphedit.graph_resource != null:
		edgar_graphedit.save_current_graph()

func _edit(object: Object) -> void:
	# If user switches to edit a different type of resource, save current graph
	if edgar_graphedit.graph_resource != null and not (object is Resource and object.has_meta("is_edgar_graph")):
		edgar_graphedit.save_current_graph()

	if object is Resource and object.has_meta("is_edgar_graph"):
		edgar_graphedit.graph_resource = object
		make_bottom_panel_item_visible(edgar_graphedit)

func _enter_tree() -> void:
	
	var i := 0
	while i < 20:
		_set_edgar_layer_project_setting(i + 1)
		i += 1
	
	importer = preload("res://addons/edgar.godot/edgar_graph_importer.gd").new()
	add_import_plugin(importer)

	add_tool_menu_item("Create Edgar Graph", _create_edgar_graph)

	edgar_graphedit = preload("res://addons/edgar.godot/graph_edit/EdgarGraphEdit.tscn").instantiate()
	edgar_graphedit_button = add_control_to_bottom_panel(edgar_graphedit, "Edgar Graph")

func _exit_tree() -> void:
	# Explicitly save before plugin unloads
	if edgar_graphedit.graph_resource != null:
		edgar_graphedit.save_current_graph()

	remove_import_plugin(importer)
	importer = null

	remove_control_from_bottom_panel(edgar_graphedit)
	edgar_graphedit.queue_free()

func _create_edgar_graph() -> void:
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dialog.title = "Create Edgar Graph"
	dialog.add_filter("*.edgar-graph", "Edgar Graph")
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS

	dialog.file_selected.connect(func(path: String):
		dialog.queue_free()
		_create_empty_edgar_graph(path)
	)

	dialog.canceled.connect(func(): dialog.queue_free())

	add_child(dialog)
	dialog.popup_centered_ratio()

func _create_empty_edgar_graph(path: String) -> void:
	var empty_graph := {
		"nodes": [],
		"edges": [],
		"layers": []
	}
	var json_str := JSON.stringify(empty_graph, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(json_str)
	file.close()

	EditorInterface.get_resource_filesystem().scan()

func _set_edgar_layer_project_setting(layer_id:int):
	var layer := "layer_"+str(layer_id)
	var layer_setting_path := "layer_names/edgar/"+layer
	if ProjectSettings.has_setting(layer_setting_path): 
		var value : String = ProjectSettings.get(layer_setting_path)
		if value != null: return
	
	ProjectSettings.set(layer_setting_path, "")
	
	#var property_info = {
		#"name": layer_setting_path,
		#"type": TYPE_STRING,
		#"hint": PROPERTY_HINT_NONE,
		#"hint_string": ""
	#}
	#ProjectSettings.add_property_info(property_info)
