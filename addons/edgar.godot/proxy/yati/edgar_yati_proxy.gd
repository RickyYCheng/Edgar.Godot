extends RefCounted

const IMPORTER_PATH := "./runtime/Importer.gd"
const POST_PROCESSOR_PATH := "res://addons/edgar.godot/edgar_post_processor.gd"
const PARSER_PATH := "./edgar_meta_parser.gd"

static func load_room(template: String, post_processor: String = POST_PROCESSOR_PATH) -> Node:
	var importer := preload(IMPORTER_PATH).new()
	var room_node := importer.import_with_post_processing(template, post_processor) as Node
	return room_node

static func get_anchor(template: String) -> Vector2:
	var result: Dictionary = preload(PARSER_PATH).parse(template)
	var anchor := result.get("anchor", Vector2.ZERO)
	return anchor

static func get_lnk(template: String) -> Dictionary:
	var result: Dictionary = preload(PARSER_PATH).parse(template)
	var lnk: Dictionary = result.get("lnk", {})
	return lnk
