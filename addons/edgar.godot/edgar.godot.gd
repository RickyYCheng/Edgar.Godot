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
var main_view: Control
var _room_template_2d_file_dialog: EditorFileDialog


const EdgarGraphImporter := preload("res://addons/edgar.godot/edgar_graph_importer.gd")
const KERNEL_PROXY_SETTING := "Edgar/kernel/edgar_kernel_proxy"
const EDGAR_YATI_PROXY_PATH := "res://addons/edgar.godot/proxy/yati/edgar_yati_proxy.gd"


func _enter_tree() -> void:
	importer = EdgarGraphImporter.new()
	add_import_plugin(importer)

	main_view = preload("res://addons/edgar.godot/views/main_view.tscn").instantiate()
	EditorInterface.get_editor_main_screen().add_child(main_view)
	_make_visible(false)

	if not ProjectSettings.has_setting(KERNEL_PROXY_SETTING):
		ProjectSettings.set_setting(KERNEL_PROXY_SETTING, EDGAR_YATI_PROXY_PATH)

	ProjectSettings.add_property_info({
		"name": KERNEL_PROXY_SETTING,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.gd"
	})
	ProjectSettings.set_initial_value(KERNEL_PROXY_SETTING, EDGAR_YATI_PROXY_PATH)

	add_tool_menu_item("Create Edgar Room Template Scene 2D", _on_create_room_template_2d)


func _exit_tree() -> void:
	if is_instance_valid(main_view):
		main_view.save_all()

	remove_import_plugin(importer)
	importer = null

	remove_tool_menu_item("Create Edgar Room Template Scene 2D")

	if is_instance_valid(_room_template_2d_file_dialog):
		_room_template_2d_file_dialog.queue_free()

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


func _on_create_room_template_2d() -> void:
	if not is_instance_valid(_room_template_2d_file_dialog):
		_room_template_2d_file_dialog = EditorFileDialog.new()
		_room_template_2d_file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
		_room_template_2d_file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
		_room_template_2d_file_dialog.filters = PackedStringArray(["*.tscn ; Scene Files"])
		_room_template_2d_file_dialog.title = "Save Room Template Scene 2D As"
		_room_template_2d_file_dialog.current_file = "new_room_scene_2d.tscn"
		_room_template_2d_file_dialog.file_selected.connect(_on_room_template_2d_path_selected)
		EditorInterface.get_base_control().add_child(_room_template_2d_file_dialog)
	_room_template_2d_file_dialog.popup_centered_ratio(0.5)


func _on_room_template_2d_path_selected(target_path: String) -> void:
	var template_path := "res://addons/edgar.godot/scene_room_designers/2d/room_scene_2d.tscn"

	var source := FileAccess.open(template_path, FileAccess.READ)
	if source == null:
		push_error("Edgar: Failed to open room template: " + template_path)
		return
	var content := source.get_as_text()
	source.close()

	# Strip uid to avoid resource UID conflicts — Godot regenerates on import
	var regex := RegEx.new()
	regex.compile(' uid="[^"]*"')
	content = regex.sub(content, "", true)

	var target := FileAccess.open(target_path, FileAccess.WRITE)
	if target == null:
		push_error("Edgar: Failed to write to: " + target_path)
		return
	target.store_string(content)
	target.close()

	EditorInterface.get_resource_filesystem().scan_sources()
