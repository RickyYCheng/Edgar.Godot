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

static func load_room(template: String, post_processor: String = POST_PROCESSOR_PATH) -> Node:
	var importer := Importer.new()
	var room_node := importer.import_with_post_processing(template, post_processor) as Node
	return room_node

static func get_anchor(template: String) -> Vector2:
	var result: Dictionary = EdgarMetaParser.parse(template)
	var anchor := result.get("anchor", Vector2.ZERO)
	return anchor

static func get_lnk(template: String) -> Dictionary:
	var result: Dictionary = EdgarMetaParser.parse(template)
	var lnk: Dictionary = result.get("lnk", {})
	return lnk
