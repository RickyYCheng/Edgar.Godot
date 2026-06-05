@tool
extends Control


const OPEN_OPEN = 100
const OPEN_QUICK = 101
const OPEN_CLEAR = 102

const EdgarIcon = preload("res://addons/edgar.godot/icons/edgar_graph.svg")


# Banner (splash screen)
@onready var banner: Control = %Banner
@onready var banner_new_button: Button = %BannerNewButton
@onready var banner_open_button: Button = %BannerOpenButton

# Title bar
@onready var create_button: Button = %CreateButton
@onready var open_button: MenuButton = %OpenButton
@onready var save_all_button: Button = %SaveAllButton
@onready var version_label: Label = %VersionLabel

# Content
@onready var content: HSplitContainer = %Content
@onready var filter_edit: LineEdit = %FilterEdit
@onready var item_list: ItemList = %ItemList
@onready var edgar_graph_edit: EdgarGraphEdit = %EdgarGraphEdit
@onready var layers_panel: LayersPanel = $"Margin/MainVBox/Content/SidePanel/LayersSplit/LayersPanel"
@onready var minimum_room_distance_spinbox: SpinBox = %MinimumRoomDistanceSpinBox
@onready var repeat_default_option: OptionButton = %RepeatDefaultOption
@onready var repeat_override_option: OptionButton = %RepeatOverrideOption
@onready var property_collapse_button: Button = %PropertyCollapseButton
@onready var property_content: MarginContainer = %PropertyContent
@onready var property_header: PanelContainer = %PropertyHeader

# Context menu
@onready var files_popup_menu: PopupMenu = %FilesPopupMenu

# Dialogs
@onready var new_dialog: FileDialog = $NewDialog
@onready var open_dialog: FileDialog = $OpenDialog
@onready var quick_open_dialog: ConfirmationDialog = $QuickOpenDialog
@onready var quick_open_filter: LineEdit = $QuickOpenDialog/VBox/FilterEdit
@onready var quick_open_list: ItemList = $QuickOpenDialog/VBox/QuickOpenList

# Open files tracking
var open_files: Array[String] = []
var file_map: Dictionary = {}


func _ready() -> void:
	var config := ConfigFile.new()
	config.load("res://addons/edgar.godot/plugin.cfg")
	version_label.text = "v" + config.get_value("plugin", "version")
	_apply_theme()
	_update_visibility()
	open_button.get_popup().id_pressed.connect(_on_open_menu_id_pressed)
	layers_panel.layers_changed.connect(_on_layers_changed)
	layers_panel.layer_deleted.connect(_on_layer_deleted)
	layers_panel.layer_structure_changed.connect(_on_layer_structure_changed)
	minimum_room_distance_spinbox.value_changed.connect(_on_room_distance_changed)
	repeat_default_option.item_selected.connect(_on_repeat_default_changed)
	repeat_override_option.item_selected.connect(_on_repeat_override_changed)
	property_collapse_button.pressed.connect(_on_property_collapse_toggle)
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(_on_filesystem_changed)


func _apply_theme() -> void:
	create_button.icon = get_theme_icon("New", "EditorIcons")
	create_button.tooltip_text = "Create a new file"

	open_button.icon = get_theme_icon("Load", "EditorIcons")
	open_button.tooltip_text = "Open a file"

	save_all_button.icon = get_theme_icon("Save", "EditorIcons")
	save_all_button.text = "All"
	save_all_button.tooltip_text = "Save all files"

	banner_new_button.icon = get_theme_icon("New", "EditorIcons")
	banner_open_button.icon = get_theme_icon("Load", "EditorIcons")

	if is_instance_valid(filter_edit):
		filter_edit.right_icon = get_theme_icon("Search", "EditorIcons")
	if is_instance_valid(item_list):
		item_list.add_theme_stylebox_override("panel", get_theme_stylebox("panel", "Panel"))

	if is_instance_valid(property_collapse_button):
		property_collapse_button.icon = get_theme_icon("GuiTreeArrowRight", "EditorIcons")

	if is_instance_valid(property_header):
		var base := get_theme_color("base_color", "Editor")
		var contrast := get_theme_color("contrast_color", "Editor")
		var header_style := StyleBoxFlat.new()
		header_style.content_margin_left = 6
		header_style.content_margin_top = 2
		header_style.content_margin_right = 6
		header_style.content_margin_bottom = 2
		header_style.bg_color = base.lerp(contrast, 0.2)
		header_style.set_corner_radius_all(3)
		property_header.add_theme_stylebox_override("panel", header_style)


func open_resource(resource: Resource) -> void:
	var path: String = resource.resource_path
	if not path in open_files:
		open_files.append(path)
		file_map[path] = path.get_file()
	edgar_graph_edit.graph_resource = resource
	layers_panel.refresh(resource)
	minimum_room_distance_spinbox.set_value_no_signal(edgar_graph_edit.get_minimum_room_distance())
	repeat_default_option.select(_meta_to_option(edgar_graph_edit.get_repeat_mode_default()))
	repeat_override_option.select(_meta_to_option(edgar_graph_edit.get_repeat_mode_override()))
	_refresh_files_list()
	_update_visibility()


func _update_visibility() -> void:
	var has_resource: bool = edgar_graph_edit.graph_resource != null
	banner.visible = not has_resource
	content.visible = has_resource
	save_all_button.disabled = not has_resource


func _refresh_files_list() -> void:
	item_list.clear()
	for path: String in open_files:
		var name: String = file_map.get(path, path.get_file())
		var idx: int = item_list.add_item(name)
		item_list.set_item_icon(idx, EdgarIcon)

	if edgar_graph_edit.graph_resource != null:
		var current_path: String = edgar_graph_edit.graph_resource.resource_path
		var idx: int = open_files.find(current_path)
		if idx >= 0:
			item_list.select(idx)


func _on_layers_changed(_layers: Array) -> void:
	# Trigger save when layers are modified in the sidebar
	if edgar_graph_edit.graph_resource != null:
		edgar_graph_edit.save_current_graph()


func _on_layer_deleted(deleted_index: int) -> void:
	# Reassign nodes that referenced the deleted layer
	if edgar_graph_edit.graph_resource != null:
		edgar_graph_edit.handle_layer_deleted(deleted_index)
		edgar_graph_edit.save_current_graph()
		edgar_graph_edit.refresh_node_layer_options()


func _on_layer_structure_changed() -> void:
	# Refresh node layer dropdowns and save
	if edgar_graph_edit.graph_resource != null:
		edgar_graph_edit.refresh_node_layer_options()
		edgar_graph_edit.save_current_graph()

func _on_room_distance_changed(value: float) -> void:
	if edgar_graph_edit.graph_resource != null:
		edgar_graph_edit.set_minimum_room_distance(int(value))
		edgar_graph_edit.save_current_graph()

func _on_repeat_default_changed(index: int) -> void:
	if edgar_graph_edit.graph_resource != null:
		edgar_graph_edit.set_repeat_mode_default(_option_to_meta(index))
		edgar_graph_edit.save_current_graph()

func _on_repeat_override_changed(index: int) -> void:
	if edgar_graph_edit.graph_resource != null:
		edgar_graph_edit.set_repeat_mode_override(_option_to_meta(index))
		edgar_graph_edit.save_current_graph()

## OptionButton selected index → metadata value
## selected 0="Default"→-1(null), 1="AllowRepeat"→0, 2="NoImmediate"→1, 3="NoRepeat"→2
func _option_to_meta(index: int) -> int:
	return index - 1

## Metadata value → OptionButton selected index
func _meta_to_option(value: int) -> int:
	return value + 1

func _on_property_collapse_toggle() -> void:
	property_content.visible = not property_content.visible
	if property_content.visible:
		property_collapse_button.icon = get_theme_icon("GuiTreeArrowDown", "EditorIcons")
	else:
		property_collapse_button.icon = get_theme_icon("GuiTreeArrowRight", "EditorIcons")

func save_all() -> void:
	# Save all open files
	for path: String in open_files:
		if path == edgar_graph_edit.graph_resource.resource_path:
			edgar_graph_edit.save_current_graph()
	# After saving all, refresh
	_refresh_files_list()


func close_file(path: String) -> void:
	if not path in open_files:
		return
	var index := open_files.find(path)
	open_files.erase(path)
	file_map.erase(path)

	var file_deleted := not FileAccess.file_exists(path)

	# Godot may clear resource_path when a file is deleted externally,
	# so we also treat a resource with an empty path as "current" during deletion.
	var is_current := false
	if edgar_graph_edit.graph_resource != null:
		var current_path := edgar_graph_edit.graph_resource.resource_path
		if current_path == path:
			is_current = true
		elif current_path.is_empty() and file_deleted:
			is_current = true

	if file_deleted:
		edgar_graph_edit.set_skip_save(true)

	# Switch if this was the current file, or if the file was deleted externally
	# and graph_resource is already null (Godot may clear it before filesystem_changed)
	if is_current or (file_deleted and edgar_graph_edit.graph_resource == null):
		if open_files.size() > 0:
			var next_index := mini(index, open_files.size() - 1)
			var next_path: String = open_files[next_index]
			var resource := load(next_path)
			if resource and resource.has_meta("is_edgar_graph"):
				edgar_graph_edit.graph_resource = resource
				layers_panel.refresh(resource)
		else:
			edgar_graph_edit.graph_resource = null
			layers_panel.refresh(null)

	if file_deleted:
		edgar_graph_edit.set_skip_save(false)

	_refresh_files_list()
	_update_visibility()


func _on_filesystem_changed() -> void:
	var paths_to_close: Array[String] = []
	for path: String in open_files:
		if not FileAccess.file_exists(path):
			paths_to_close.append(path)

	for path: String in paths_to_close:
		close_file(path)

	# Fallback: if current resource was invalidated and we still have open files, open the first one
	if edgar_graph_edit.graph_resource == null and open_files.size() > 0:
		var next_path: String = open_files[0]
		var resource := load(next_path)
		if resource and resource.has_meta("is_edgar_graph"):
			edgar_graph_edit.graph_resource = resource
			layers_panel.refresh(resource)
			_refresh_files_list()
			_update_visibility()


func _create_empty_file(path: String) -> void:
	var empty_graph := {
		"nodes": {},
		"edges": [],
		"layers": [],
		"layer_names": ["Layer 1"]
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(empty_graph, "\t"))
	file.close()
	EditorInterface.get_resource_filesystem().scan()
	await EditorInterface.get_resource_filesystem().filesystem_changed
	var resource := load(path)
	if resource and resource.has_meta("is_edgar_graph"):
		EditorInterface.edit_resource(resource)


#region Title bar


func _on_create_button_pressed() -> void:
	new_dialog.current_file = "untitled"
	new_dialog.popup_centered()


func _on_save_all_button_pressed() -> void:
	save_all()


func _on_open_button_about_to_popup() -> void:
	_build_open_menu()


func _on_open_menu_id_pressed(id: int) -> void:
	match id:
		OPEN_OPEN:
			open_dialog.popup_centered()
		OPEN_QUICK:
			_build_quick_open()
			quick_open_dialog.popup_centered()
		OPEN_CLEAR:
			pass


func _build_open_menu() -> void:
	var menu := open_button.get_popup()
	menu.clear()
	menu.add_icon_item(get_theme_icon("Load", "EditorIcons"), "Open...", OPEN_OPEN)
	menu.add_icon_item(get_theme_icon("Load", "EditorIcons"), "Quick Open...", OPEN_QUICK)
	menu.add_separator()
	menu.add_item("Clear recent files", OPEN_CLEAR)
	menu.set_item_disabled(menu.item_count - 1, true)


func _build_quick_open() -> void:
	quick_open_filter.text = ""
	quick_open_filter.right_icon = get_theme_icon("Search", "EditorIcons")
	quick_open_list.add_theme_stylebox_override("panel", get_theme_stylebox("panel", "Panel"))
	quick_open_list.clear()
	var dir := DirAccess.open("res://")
	if dir:
		_scan_dir_for_graphs(dir, "res://")


func _scan_dir_for_graphs(dir: DirAccess, base: String) -> void:
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		var full_path := base.path_join(file_name)
		if dir.current_is_dir():
			var sub_dir := DirAccess.open(full_path)
			if sub_dir:
				_scan_dir_for_graphs(sub_dir, full_path)
		elif file_name.ends_with(".edgar-graph"):
			var nice := full_path.replace("res://", "").replace(".edgar-graph", "")
			quick_open_list.add_item(nice, EdgarIcon)
			quick_open_list.set_item_metadata(quick_open_list.item_count - 1, full_path)
		file_name = dir.get_next()
	dir.list_dir_end()


func _on_quick_open_filter_changed(new_text: String) -> void:
	quick_open_list.clear()
	var dir := DirAccess.open("res://")
	if dir:
		_scan_dir_for_graphs_filtered(dir, "res://", new_text)


func _scan_dir_for_graphs_filtered(dir: DirAccess, base: String, filter: String) -> void:
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		var full_path := base.path_join(file_name)
		if dir.current_is_dir():
			var sub_dir := DirAccess.open(full_path)
			if sub_dir:
				_scan_dir_for_graphs_filtered(sub_dir, full_path, filter)
		elif file_name.ends_with(".edgar-graph"):
			var nice := full_path.replace("res://", "").replace(".edgar-graph", "")
			if filter.is_empty() or filter.to_lower() in nice.to_lower():
				quick_open_list.add_item(nice, EdgarIcon)
				quick_open_list.set_item_metadata(quick_open_list.item_count - 1, full_path)
		file_name = dir.get_next()
	dir.list_dir_end()


func _on_quick_open_confirmed() -> void:
	var selected := quick_open_list.get_selected_items()
	if selected.size() > 0:
		var path: String = quick_open_list.get_item_metadata(selected[0])
		var resource := load(path)
		if resource and resource.has_meta("is_edgar_graph"):
			EditorInterface.edit_resource(resource)


func _on_quick_open_item_activated(index: int) -> void:
	var path: String = quick_open_list.get_item_metadata(index)
	quick_open_dialog.hide()
	var resource := load(path)
	if resource and resource.has_meta("is_edgar_graph"):
		EditorInterface.edit_resource(resource)


#endregion


#region Banner buttons


func _on_banner_new_pressed() -> void:
	new_dialog.current_file = "untitled"
	new_dialog.popup_centered()


func _on_banner_open_pressed() -> void:
	_build_quick_open()
	quick_open_dialog.popup_centered()


#endregion


#region New dialog (Create)


func _on_new_dialog_confirmed() -> void:
	var path: String = new_dialog.current_path
	if path.get_extension() != "edgar-graph":
		path = path + ".edgar-graph" if not path.ends_with(".") else path + "edgar-graph"
	_create_empty_file(path)


func _on_new_dialog_file_selected(path: String) -> void:
	_create_empty_file(path)


#endregion


#region Open dialog


func _on_open_dialog_file_selected(path: String) -> void:
	var resource := load(path)
	if resource and resource.has_meta("is_edgar_graph"):
		EditorInterface.edit_resource(resource)


#endregion


#region Files list


func _on_files_list_item_clicked(index: int, _at_position: Vector2, mouse_button: int) -> void:
	if index < 0 or index >= open_files.size():
		return

	var path: String = open_files[index]

	if mouse_button == MOUSE_BUTTON_LEFT or mouse_button == MOUSE_BUTTON_RIGHT:
		var resource := load(path)
		if resource and resource.has_meta("is_edgar_graph"):
			EditorInterface.edit_resource(resource)

	if mouse_button == MOUSE_BUTTON_RIGHT:
		files_popup_menu.position = get_viewport().get_mouse_position()
		files_popup_menu.popup()

	if mouse_button == MOUSE_BUTTON_MIDDLE:
		close_file(path)


func _on_files_list_item_activated(index: int) -> void:
	if index >= 0 and index < open_files.size():
		var path: String = open_files[index]
		var resource := load(path)
		if resource and resource.has_meta("is_edgar_graph"):
			EditorInterface.edit_resource(resource)


func _on_filter_edit_text_changed(new_text: String) -> void:
	item_list.clear()
	for path: String in open_files:
		var name: String = file_map.get(path, path.get_file())
		if new_text.is_empty() or new_text.to_lower() in name.to_lower():
			var idx: int = item_list.add_item(name)
			item_list.set_item_icon(idx, EdgarIcon)


#endregion


#region Files context menu


func _on_files_popup_menu_id_pressed(id: int) -> void:
	if edgar_graph_edit.graph_resource == null:
		return
	var current_path: String = edgar_graph_edit.graph_resource.resource_path

	match id:
		0:  # Close
			close_file(current_path)
		1:  # Close All
			var paths := open_files.duplicate()
			for path: String in paths:
				close_file(path)
		2:  # Close Others
			var paths := open_files.duplicate()
			for path: String in paths:
				if path != current_path:
					close_file(path)
		3:  # Copy Path
			DisplayServer.clipboard_set(current_path)
		4:  # Show in FileSystem
			EditorInterface.get_file_system_dock().navigate_to_path(current_path)


func _on_files_popup_menu_about_to_popup() -> void:
	files_popup_menu.clear()
	files_popup_menu.add_item("Close", 0)
	files_popup_menu.add_item("Close All", 1)
	files_popup_menu.add_item("Close Others", 2)
	files_popup_menu.add_separator()
	files_popup_menu.add_item("Copy Path", 3)
	files_popup_menu.add_item("Show in FileSystem", 4)


#endregion
