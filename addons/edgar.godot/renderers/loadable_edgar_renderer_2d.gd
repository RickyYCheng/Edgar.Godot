@tool
class_name LoadableEdgarRenderer2D
extends EdgarRenderer2D

@export var payload_scene: PackedScene
@export var payload_name: String = "__loadable_edgar_renderer_2d_payload_node___unique_8f3a9b2c__"

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			tile_map_layers = tile_map_layers.filter(is_instance_valid)
		NOTIFICATION_EXIT_TREE:
			unload_content()

var _loaded := false

func is_loaded() -> bool:
	return _loaded

func load_content() -> void:
	if _loaded:
		return

	if not payload_scene:
		return

	var payload := payload_scene.instantiate()
	add_child(payload)
	payload.name = payload_name

	var tml_paths := payload.get_meta("tile_map_layers", []) as Array
	var tmls := tml_paths.map(payload.get_node)
	tile_map_layers.append_array(tmls)
	
	_loaded = true

func unload_content() -> void:
	if not _loaded:
		return

	var payload := get_node(payload_name)
	if payload:
		remove_child(payload)
		payload.queue_free()
	
	_loaded = false

func render() -> void:
	if not _loaded:
		load_content()
	
	super()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := []

	if payload_scene:
		var scene_state := payload_scene.get_state()
		var tmls = null
		for i in scene_state.get_node_property_count(0):
			var prop_name := scene_state.get_node_property_name(0, i)
			if prop_name == "metadata/tile_map_layers":
				tmls = scene_state.get_node_property_value(0, i)
				break

		# do not use `not tmls` here since tmls could be []. 
		if tmls == null \
		or not (
			tmls is Array[NodePath] 
			or (tmls is Array and tmls.all(func (elem): return elem is NodePath))
		):
			warnings.append("The provided payload scene does not contain a valid TileMap node with 'tile_map_layers' property.")

	return warnings
