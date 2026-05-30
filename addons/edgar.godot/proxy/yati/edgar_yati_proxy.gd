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

extends RefCounted

const Importer := preload("./runtime/Importer.gd")
const EdgarMetaParser := preload("edgar_meta_parser.gd")
const POST_PROCESSOR_PATH := "res://addons/edgar.godot/edgar_post_processor.gd"

enum TEMPLATE_TYPE {
	INVALID,
	TILED,
	SCENE,
}

static func parse_template_type(template: String) -> TEMPLATE_TYPE:
	if template.ends_with(".tmj") \
	or template.ends_with(".tmx"):
		return TEMPLATE_TYPE.TILED
	
	if template.ends_with(".tscn") \
	or template.ends_with(".scn"):
		if template.begins_with("res://") \
		and ResourceLoader.exists(template):
			return TEMPLATE_TYPE.SCENE

	return TEMPLATE_TYPE.INVALID

static func load_room(template: String, post_processor: String = POST_PROCESSOR_PATH) -> Node:
	match parse_template_type(template):
		TEMPLATE_TYPE.SCENE:
			var scene: PackedScene = load(template)
			if scene == null:
				push_error("Edgar: Failed to load scene: " + template)
				return null
			return scene.instantiate()
		TEMPLATE_TYPE.TILED:
			var importer := Importer.new()
			var room_node := importer.import_with_post_processing(template, post_processor) as Node
			return room_node
	
	return null

static func get_anchor(template: String) -> Vector2:
	match parse_template_type(template):
		TEMPLATE_TYPE.SCENE:
			var scene: PackedScene = load(template)
			if scene == null:
				return Vector2.ZERO
			var state := scene.get_state()
			for i in state.get_node_property_count(0):
				if state.get_node_property_name(0, i) == "metadata/anchor":
					return state.get_node_property_value(0, i)
			return Vector2.ZERO
		TEMPLATE_TYPE.TILED:
			var result: Dictionary = EdgarMetaParser.parse(template)
			var anchor := result.get("anchor", Vector2.ZERO)
			return anchor
	
	return Vector2.ZERO

static func get_lnk(template: String) -> Dictionary:
	match parse_template_type(template):
		TEMPLATE_TYPE.SCENE:
			var scene: PackedScene = load(template)
			if scene == null:
				return {}
			var state := scene.get_state()
			for i in state.get_node_property_count(0):
				if state.get_node_property_name(0, i) == "metadata/lnk":
					return state.get_node_property_value(0, i)
			return {}
		TEMPLATE_TYPE.TILED:
			var result: Dictionary = EdgarMetaParser.parse(template)
			var lnk: Dictionary = result.get("lnk", {})
			return lnk
	
	return {}
