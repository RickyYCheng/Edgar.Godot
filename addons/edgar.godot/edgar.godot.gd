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
var main_view : Control


func _enter_tree() -> void:

	var i := 0
	while i < 20:
		_set_edgar_layer_project_setting(i + 1)
		i += 1

	importer = preload("res://addons/edgar.godot/edgar_graph_importer.gd").new()
	add_import_plugin(importer)

	main_view = preload("res://addons/edgar.godot/views/main_view.tscn").instantiate()
	EditorInterface.get_editor_main_screen().add_child(main_view)
	_make_visible(false)


func _exit_tree() -> void:
	if is_instance_valid(main_view):
		main_view.save_all()

	remove_import_plugin(importer)
	importer = null

	if is_instance_valid(main_view):
		main_view.queue_free()


func _has_main_screen() -> bool:
	return true


func _make_visible(next_visible: bool) -> void:
	if is_instance_valid(main_view):
		main_view.visible = next_visible


func _get_plugin_name() -> String:
	return "Edgar"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("RandomNumberGenerator", "EditorIcons")


func _handles(object: Object) -> bool:
	if not (object is Resource and object.has_meta("is_edgar_graph")):
		return false

	var path: String = object.resource_path
	return path.ends_with(".edgar-graph")


func _apply_changes() -> void:
	if is_instance_valid(main_view):
		main_view.save_all()


func _edit(object: Object) -> void:
	if object is Resource and object.has_meta("is_edgar_graph"):
		if is_instance_valid(main_view):
			main_view.open_resource(object)


func _set_edgar_layer_project_setting(layer_id: int):
	var layer := "layer_" + str(layer_id)
	var layer_setting_path := "layer_names/edgar/" + layer
	if ProjectSettings.has_setting(layer_setting_path):
		var value: String = ProjectSettings.get(layer_setting_path)
		if value != null: return

	ProjectSettings.set(layer_setting_path, "")
