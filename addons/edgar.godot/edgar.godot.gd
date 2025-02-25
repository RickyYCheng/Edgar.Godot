@tool
extends EditorPlugin

const tiled_import_plugin_path := "res://addons/edgar.godot/import_plugins/edgar_tiled_import_plugin.gd"
const graph_import_plugin_path := "res://addons/edgar.godot/import_plugins/edgar_graph_import_plugin.gd"

const edgra_graphedit_path := "res://addons/edgar.godot/graph_edit/EdgarGraphEdit.tscn"
var edgar_graphedit : EdgarGraphEdit
var edgar_graphedit_button : Button

var tiled_import_plugin : EditorImportPlugin
var graph_import_plugin : EditorImportPlugin

func load_tiled_plugin():
	tiled_import_plugin = preload(tiled_import_plugin_path).new()
	add_import_plugin(tiled_import_plugin)

func unload_tiled_plugin():
	remove_import_plugin(tiled_import_plugin)
	tiled_import_plugin = null

func load_graph_plugin():
	graph_import_plugin = preload(graph_import_plugin_path).new()
	add_import_plugin(graph_import_plugin)

func unload_graph_plugin():
	remove_import_plugin(graph_import_plugin)
	graph_import_plugin = null

func _handles(object: Object) -> bool:
	return object is EdgarGraphResource

func _edit(object: Object) -> void:
	edgar_graphedit.graph_resource = object
	var is_object_edgar_graph_resource := object is EdgarGraphResource
	edgar_graphedit_button.visible = is_object_edgar_graph_resource
	if not is_object_edgar_graph_resource:
		if edgar_graphedit_button.button_pressed:
			hide_bottom_panel()
	else:
		make_bottom_panel_item_visible(edgar_graphedit)

func _enter_tree() -> void:
	load_tiled_plugin()
	load_graph_plugin()
	
	edgar_graphedit = preload(edgra_graphedit_path).instantiate()
	edgar_graphedit_button = add_control_to_bottom_panel(edgar_graphedit, "Edgar Graph")
	edgar_graphedit_button.visible = false
	
	set_edgar_project_settings()

func _exit_tree() -> void:
	unload_tiled_plugin()
	unload_graph_plugin()
	
	remove_control_from_bottom_panel(edgar_graphedit)
	edgar_graphedit.graph_resource = null # use this to save
	edgar_graphedit.queue_free()

func set_edgar_project_settings():
	for i in range(20):
		_set_edgar_layer_project_setting(i+1)

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
