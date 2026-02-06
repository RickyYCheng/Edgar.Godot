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
	if !FileAccess.file_exists(source_file):
		printerr("Import file '" + source_file + "' not found!")
		return ERR_FILE_NOT_FOUND

	var file := FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return FAILED

	var text := file.get_as_text()
	var json_obj := JSON.new()
	var err := json_obj.parse(text)
	var json := json_obj.data if err == Error.OK else {"edges" = [], "layers" = [], "nodes" = []}

	var res := EdgarGraphResource.new()
	# Store the original source file path for later reference
	res.set_meta("source_file", source_file)

	var reimport_layers := false

	var layers = []
	for key in options:
		if key == "reimport_layers":
			reimport_layers = options[key]
		if not options[key] is EdgarLayersResource: continue
		var files = options[key].files.map(func(uid): return ResourceUID.get_id_path(ResourceUID.text_to_id(uid)))
		layers.push_back(files)

	res.set_meta("is_edgar_graph", true)
	res.set_meta("nodes", json["nodes"])
	res.set_meta("edges", json["edges"])
	res.set_meta("layers", layers if reimport_layers else json["layers"])
	var ret := ResourceSaver.save(res, save_path + "." + _get_save_extension())

	return ret
