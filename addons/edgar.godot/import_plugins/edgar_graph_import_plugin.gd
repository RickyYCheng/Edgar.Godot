@tool
extends EditorImportPlugin

func _get_importer_name() -> String:
	return "edgar.graph.importer"

func _get_visible_name() -> String:
	return "Edgar Graph Json Importer"

func _get_recognized_extensions() -> PackedStringArray:
	return ["egr"]

func _get_save_extension() -> String:
	return "tres"

func _get_resource_type() -> String:
	return "EdgarGraphResource"

func _get_preset_count() -> int:
	return 1

func _get_priority() -> float:
	return 1.0

func _get_import_order() -> int:
	return 1

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return false

func _get_preset_name(preset_index: int) -> String:
	return "Default"

func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	return [{"name": "my_option", "default_value": false}]

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var file := FileAccess.open(source_file, FileAccess.READ_WRITE)
	
	if file == null:
		return FAILED
	
	var res := EdgarGraphResource.new()
	res.set_data(JSON.parse_string(file.get_as_text()))
	
	var filename := save_path + "." + _get_save_extension() as String
	return ResourceSaver.save(res, filename)
