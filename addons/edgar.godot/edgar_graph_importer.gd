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
extends EditorImportPlugin

func _get_importer_name() -> String:
	return "Edgar Graph Importer"

func _get_visible_name() -> String:
	return "Edgar Graph Importer"

func _get_recognized_extensions() -> PackedStringArray:
	return ["edgar-graph"]

func _get_save_extension() -> String:
	return "tres"

func _get_resource_type() -> String:
	return "EdgarGraphResource"

func _get_priority() -> float:
	return 0.11

func _get_preset_count() -> int:
	return 0

func _get_preset_name(preset_index: int) -> String:
	return ""

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return true

func _get_import_options(path: String, preset_index: int) -> Array:
	var options := [
		{ "name": "reimport_layers", "default_value": false, "property_hint": PROPERTY_HINT_NONE, "hint_string": "" }
	]
	var i := 0
	while i < 20:
		var setting := ProjectSettings.get_setting("layer_names/edgar/layer_"+str(i+1))
		if setting != "" and setting != null:
			options.push_back({ "name": "layer_"+str(i+1), "default_value": EdgarLayersResource.new(), "property_hint": PROPERTY_HINT_RESOURCE_TYPE, "hint_string": "EdgarLayersResource" })
		i += 1
	
	return options

func _get_import_order() -> int:
	return 98

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array, gen_files: Array) -> Error:
	var json := _read_json(source_file, options)
	if json.is_empty():
		return FAILED

	if options.get("reimport_layers", false):
		var write_file := FileAccess.open(source_file, FileAccess.WRITE)
		if write_file != null:
			write_file.store_string(JSON.stringify(json, "  "))

	var res := _create_resource(source_file, json)
	var ret := ResourceSaver.save(res, save_path + "." + _get_save_extension())
	return ret

# -----------------------------------------------------------------------------------------------------------------------------

static func load_from_src(source_file: String) -> EdgarGraphResource:
	var json := _read_json(source_file, {})
	if json.is_empty():
		return null
	return _create_resource(source_file, json)

static func _read_json(source_file: String, options: Dictionary) -> Dictionary:
	if !FileAccess.file_exists(source_file):
		printerr("Import file '" + source_file + "' not found!")
		return {}

	var file := FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return {}

	var text := file.get_as_text()
	var json_obj := JSON.new()
	var err := json_obj.parse(text)
	if err != Error.OK:
		return {"edges": [], "layers": [], "nodes": []}

	var json: Dictionary = json_obj.data

	var reimport_layers := options.get("reimport_layers", false)
	var layers := []
	for key in options:
		if not options[key] is EdgarLayersResource: continue
		var files = options[key].files.map(func(uid): return ResourceUID.get_id_path(ResourceUID.text_to_id(uid)))
		layers.push_back(files)

	if reimport_layers and not layers.is_empty():
		json["layers"] = layers

	return json

static func _create_resource(source_file: String, json: Dictionary) -> EdgarGraphResource:
	var res := EdgarGraphResource.new()
	res.set_meta("source_file", source_file)
	res.set_meta("is_edgar_graph", true)
	res.set_meta("nodes", json["nodes"])
	res.set_meta("edges", json["edges"])
	res.set_meta("layers", json["layers"])
	return res
