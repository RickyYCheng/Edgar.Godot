@tool
class_name LayerFileRow
extends PanelContainer

signal browse_pressed(layer_index: int, file_index: int)
signal remove_pressed(layer_index: int, file_index: int)

@onready var file_icon: TextureRect = $"RowHBox/FileIcon"
@onready var path_label: Label = $"RowHBox/PathLabel"
@onready var browse_button: Button = $"RowHBox/BrowseButton"
@onready var remove_button: Button = $"RowHBox/RemoveButton"

var layer_index: int = -1
var file_index: int = -1


func _ready() -> void:
	file_icon.texture = get_theme_icon("File", "EditorIcons")
	browse_button.icon = get_theme_icon("Folder", "EditorIcons")
	browse_button.tooltip_text = "Browse"
	remove_button.icon = get_theme_icon("Remove", "EditorIcons")
	remove_button.tooltip_text = "Remove"
	browse_button.pressed.connect(_on_browse)
	remove_button.pressed.connect(_on_remove)


func setup(p_layer_index: int, p_file_index: int, path: String, file_exists: bool) -> void:
	layer_index = p_layer_index
	file_index = p_file_index
	path_label.text = path.get_file()
	path_label.tooltip_text = path
	if not file_exists:
		path_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		file_icon.texture = get_theme_icon("FileBroken", "EditorIcons")
	else:
		file_icon.texture = _get_file_icon(path)


func _get_file_icon(path: String) -> Texture2D:
	var ext := path.get_extension().to_lower()
	match ext:
		"tscn", "scn":
			return get_theme_icon("PackedScene", "EditorIcons")
		"tmj", "tmx":
			return get_theme_icon("File", "EditorIcons")
		_:
			return get_theme_icon("File", "EditorIcons")


func _on_browse() -> void:
	browse_pressed.emit(layer_index, file_index)


func _on_remove() -> void:
	remove_pressed.emit(layer_index, file_index)
