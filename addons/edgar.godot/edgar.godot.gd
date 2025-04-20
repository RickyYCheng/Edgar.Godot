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

func _edit(object: Object) -> void:
	edgar_graphedit.graph_resource = object
	var is_object_edgar_graph_resource : bool = object is Resource and object.has_meta("is_edgar_graph")
	edgar_graphedit_button.visible = is_object_edgar_graph_resource
	if not is_object_edgar_graph_resource:
		if edgar_graphedit_button.button_pressed:
			hide_bottom_panel()
	else:
		make_bottom_panel_item_visible(edgar_graphedit)

func _enter_tree() -> void:
	
	for i in range(20):
		_set_edgar_layer_project_setting(i + 1)
	
	importer = preload("res://addons/edgar.godot/edgar_graph_importer.gd").new()
	add_import_plugin(importer)
	
	edgar_graphedit = preload("res://addons/edgar.godot/graph_edit/EdgarGraphEdit.tscn").instantiate()
	edgar_graphedit_button = add_control_to_bottom_panel(edgar_graphedit, "Edgar Graph")
	edgar_graphedit_button.visible = false

func _exit_tree() -> void:
	remove_import_plugin(importer)
	importer = null
	
	remove_control_from_bottom_panel(edgar_graphedit)
	edgar_graphedit.graph_resource = null # use this to save
	edgar_graphedit.queue_free()

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
