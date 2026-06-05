@tool
class_name LayerSection
extends PanelContainer

signal add_pressed(layer_index: int)
signal browse_pressed(layer_index: int, file_index: int)
signal remove_pressed(layer_index: int, file_index: int)
signal rename_pressed(layer_index: int, new_name: String)
signal delete_pressed(layer_index: int)

const FileRowScene = preload("res://addons/edgar.godot/views/layer_file_row.tscn")

@onready var name_label: Label = $"SectionVBox/Header/HeaderHBox/NameLabel"
@onready var rename_edit: LineEdit = $"SectionVBox/Header/HeaderHBox/RenameEdit"
@onready var warn_label: Label = $"SectionVBox/Header/HeaderHBox/WarnLabel"
@onready var count_label: Label = $"SectionVBox/Header/HeaderHBox/CountLabel"
@onready var rename_button: Button = $"SectionVBox/Header/HeaderHBox/RenameButton"
@onready var delete_button: Button = $"SectionVBox/Header/HeaderHBox/DeleteButton"
@onready var files_vbox: VBoxContainer = $"SectionVBox/ContentMargin/ContentVBox/FilesVBox"
@onready var add_button: Button = $"SectionVBox/ContentMargin/ContentVBox/AddButton"
@onready var collapse_button: Button = $"SectionVBox/Header/HeaderHBox/CollapseButton"
@onready var content_margin: MarginContainer = $"SectionVBox/ContentMargin"
@onready var header_panel: PanelContainer = $"SectionVBox/Header"

var layer_index: int = -1
var _collapsed: bool = false
var _renaming: bool = false


func _ready() -> void:
	_apply_theme()
	add_button.icon = get_theme_icon("Add", "EditorIcons")
	add_button.pressed.connect(_on_add)
	collapse_button.pressed.connect(_on_collapse_toggle)
	rename_button.icon = get_theme_icon("Edit", "EditorIcons")
	rename_button.tooltip_text = "Rename layer"
	rename_button.pressed.connect(_on_rename_start)
	delete_button.icon = get_theme_icon("Close", "EditorIcons")
	delete_button.tooltip_text = "Delete layer"
	delete_button.pressed.connect(_on_delete)
	rename_edit.text_submitted.connect(_on_rename_submitted)
	rename_edit.focus_exited.connect(_on_rename_focus_exited)
	_update_collapse_icon()


func setup(p_layer_index: int, layer_name: String, files: Array) -> void:
	layer_index = p_layer_index
	name_label.text = layer_name
	rename_edit.text = layer_name

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


func _on_rename_start() -> void:
	_renaming = true
	name_label.visible = false
	rename_button.visible = false
	rename_edit.visible = true
	rename_edit.text = name_label.text
	rename_edit.grab_focus()
	rename_edit.select_all()


func _on_rename_submitted(new_text: String) -> void:
	if not _renaming:
		return
	_renaming = false
	rename_edit.visible = false
	rename_button.visible = true
	name_label.visible = true
	var text := new_text.strip_edges()
	if text != "" and text != name_label.text:
		name_label.text = text
		rename_pressed.emit(layer_index, text)


func _on_rename_focus_exited() -> void:
	if _renaming:
		_on_rename_submitted(rename_edit.text)


func _on_delete() -> void:
	delete_pressed.emit(layer_index)


func _apply_theme() -> void:
	var base := get_theme_color("base_color", "Editor")
	var contrast := get_theme_color("contrast_color", "Editor")

	# Section outer panel
	var section_style := StyleBoxFlat.new()
	section_style.content_margin_left = 6
	section_style.content_margin_top = 6
	section_style.content_margin_right = 6
	section_style.content_margin_bottom = 6
	section_style.bg_color = base
	section_style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", section_style)

	# Header background
	var header_style := StyleBoxFlat.new()
	header_style.content_margin_left = 8
	header_style.content_margin_top = 4
	header_style.content_margin_right = 8
	header_style.content_margin_bottom = 4
	header_style.bg_color = base.lerp(contrast, 0.1)
	header_style.set_corner_radius_all(3)
	header_panel.add_theme_stylebox_override("panel", header_style)
