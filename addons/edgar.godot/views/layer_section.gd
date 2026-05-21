@tool
class_name LayerSection
extends PanelContainer

signal add_pressed(layer_index: int)
signal browse_pressed(layer_index: int, file_index: int)
signal remove_pressed(layer_index: int, file_index: int)

const FileRowScene = preload("res://addons/edgar.godot/views/layer_file_row.tscn")

@onready var name_label: Label = $"SectionVBox/Header/HeaderHBox/NameLabel"
@onready var warn_label: Label = $"SectionVBox/Header/HeaderHBox/WarnLabel"
@onready var count_label: Label = $"SectionVBox/Header/HeaderHBox/CountLabel"
@onready var files_vbox: VBoxContainer = $"SectionVBox/ContentMargin/ContentVBox/FilesVBox"
@onready var add_button: Button = $"SectionVBox/ContentMargin/ContentVBox/AddButton"
@onready var collapse_button: Button = $"SectionVBox/Header/HeaderHBox/CollapseButton"
@onready var content_margin: MarginContainer = $"SectionVBox/ContentMargin"

var layer_index: int = -1
var _collapsed: bool = false


func _ready() -> void:
	add_button.icon = get_theme_icon("Add", "EditorIcons")
	add_button.pressed.connect(_on_add)
	collapse_button.pressed.connect(_on_collapse_toggle)
	_update_collapse_icon()


func setup(p_layer_index: int, layer_name: String, files: Array) -> void:
	layer_index = p_layer_index
	name_label.text = layer_name

	var invalid_count := 0
	for path in files:
		if not FileAccess.file_exists(path):
			invalid_count += 1

	warn_label.visible = invalid_count > 0
	count_label.text = str(files.size())

	# Clear existing file rows
	for child in files_vbox.get_children():
		child.queue_free()

	# Create file rows
	for j in range(files.size()):
		var path: String = files[j]
		var row: LayerFileRow = FileRowScene.instantiate()
		files_vbox.add_child(row)
		row.setup(layer_index, j, path, FileAccess.file_exists(path))
		row.browse_pressed.connect(_on_row_browse)
		row.remove_pressed.connect(_on_row_remove)


func _on_add() -> void:
	add_pressed.emit(layer_index)


func _on_row_browse(layer_idx: int, file_idx: int) -> void:
	browse_pressed.emit(layer_idx, file_idx)


func _on_row_remove(layer_idx: int, file_idx: int) -> void:
	remove_pressed.emit(layer_idx, file_idx)


func _on_collapse_toggle() -> void:
	_collapsed = not _collapsed
	content_margin.visible = not _collapsed
	_update_collapse_icon()


func _update_collapse_icon() -> void:
	if _collapsed:
		collapse_button.icon = get_theme_icon("GuiTreeArrowRight", "EditorIcons")
	else:
		collapse_button.icon = get_theme_icon("GuiTreeArrowDown", "EditorIcons")
