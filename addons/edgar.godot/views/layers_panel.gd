@tool
class_name LayersPanel
extends VBoxContainer

signal layers_changed(layers: Array)
signal layer_deleted(deleted_index: int)
signal layer_structure_changed()

const SectionScene = preload("res://addons/edgar.godot/views/layer_section.tscn")

@onready var layers_vbox: VBoxContainer = $"LayersScroll/LayersVBox"
@onready var layer_file_dialog: FileDialog = $"LayerFileDialog"
@onready var add_layer_button: Button = $"AddLayerButton"

var _graph_resource: Resource = null
var _current_layer_index: int = -1


func _ready() -> void:
	layer_file_dialog.file_selected.connect(_on_layer_file_selected)
	layers_vbox.add_theme_constant_override("separation", 6)
	add_layer_button.icon = get_theme_icon("Add", "EditorIcons")
	add_layer_button.tooltip_text = "Add layer"
	add_layer_button.pressed.connect(_on_add_layer)


func refresh(graph_resource: Resource) -> void:
	_graph_resource = graph_resource
	for child in layers_vbox.get_children():
		child.queue_free()

	if graph_resource == null:
		return

	var layers: Array = graph_resource.get_meta("layers", [])
	var layer_names := _get_layer_names()

	for i in range(layer_names.size()):
		var section: LayerSection = SectionScene.instantiate()
		layers_vbox.add_child(section)
		section.setup(i, layer_names[i], layers[i] if i < layers.size() else [])
		section.add_pressed.connect(_on_add_pressed)
		section.browse_pressed.connect(_on_browse_pressed)
		section.remove_pressed.connect(_on_remove_pressed)
		section.rename_pressed.connect(_on_rename_pressed)
		section.delete_pressed.connect(_on_delete_pressed)


func _on_add_pressed(layer_index: int) -> void:
	_current_layer_index = layer_index
	layer_file_dialog.remove_meta("replace_index")
	layer_file_dialog.popup_centered()


func _on_browse_pressed(layer_index: int, file_index: int) -> void:
	_current_layer_index = layer_index
	layer_file_dialog.set_meta("replace_index", file_index)
	layer_file_dialog.popup_centered()


func _on_remove_pressed(layer_index: int, file_index: int) -> void:
	var layers := _get_layers_from_resource()
	if layer_index >= layers.size():
		return
	var files: Array = layers[layer_index]
	if file_index >= files.size():
		return
	files.remove_at(file_index)
	layers[layer_index] = files
	_set_layers_to_resource(layers)
	refresh(_graph_resource)


func _on_layer_file_selected(path: String) -> void:
	var layers := _get_layers_from_resource()
	if _current_layer_index < 0:
		return
	while layers.size() <= _current_layer_index:
		layers.append([])
	var replace_index: int = layer_file_dialog.get_meta("replace_index", -1)
	layer_file_dialog.remove_meta("replace_index")
	if replace_index >= 0:
		if replace_index < layers[_current_layer_index].size():
			layers[_current_layer_index][replace_index] = path
	else:
		var files: Array = layers[_current_layer_index]
		if not path in files:
			files.append(path)
		layers[_current_layer_index] = files
	_set_layers_to_resource(layers)
	refresh(_graph_resource)


func _on_add_layer() -> void:
	if _graph_resource == null:
		return
	var layer_names := _get_layer_names()
	layer_names.append("Layer " + str(layer_names.size() + 1))
	_set_layer_names(layer_names)
	var layers := _get_layers_from_resource()
	layers.append([])
	_set_layers_to_resource(layers)
	refresh(_graph_resource)
	layer_structure_changed.emit()


func _on_delete_pressed(layer_index: int) -> void:
	if _graph_resource == null:
		return
	var layer_names := _get_layer_names()
	if layer_names.size() <= 1:
		return
	layer_names.remove_at(layer_index)
	_set_layer_names(layer_names)
	var layers := _get_layers_from_resource()
	if layer_index < layers.size():
		layers.remove_at(layer_index)
	_set_layers_to_resource(layers)
	layer_deleted.emit(layer_index)
	refresh(_graph_resource)
	layer_structure_changed.emit()


func _on_rename_pressed(layer_index: int, new_name: String) -> void:
	if _graph_resource == null:
		return
	var layer_names := _get_layer_names()
	if layer_index < layer_names.size():
		layer_names[layer_index] = new_name
	_set_layer_names(layer_names)
	layer_structure_changed.emit()


func _get_layer_names() -> Array[String]:
	if _graph_resource == null:
		return []
	var names: Array = _graph_resource.get_meta("layer_names", [])
	if names.is_empty():
		var layers: Array = _graph_resource.get_meta("layers", [])
		for i in range(layers.size()):
			names.append("Layer " + str(i + 1))
		if names.is_empty():
			names.append("Layer 1")
		_graph_resource.set_meta("layer_names", names)
	var result: Array[String] = []
	for layer_name in names:
		result.append(str(layer_name))
	return result


func _set_layer_names(names: Array[String]) -> void:
	if _graph_resource == null:
		return
	_graph_resource.set_meta("layer_names", names)


func _get_layers_from_resource() -> Array:
	if _graph_resource == null:
		return []
	var layers: Array = _graph_resource.get_meta("layers", [])
	while layers.size() < _get_layer_names().size():
		layers.append([])
	return layers


func _set_layers_to_resource(layers: Array) -> void:
	if _graph_resource == null:
		return
	_graph_resource.set_meta("layers", layers)
	layers_changed.emit(layers)
