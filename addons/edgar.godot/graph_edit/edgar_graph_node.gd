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
class_name EdgarGraphNode
extends GraphNode

@onready var room_type_button: OptionButton = $RoomTypeButton
@onready var edgar_layer_button: OptionButton = $EdgarLayerButton
@onready var is_pivot_button: CheckButton = $IsPivotButton

func _ready() -> void:
	edgar_layer_button.clear()
	for i in range(20):
		var layer := ProjectSettings.get("layer_names/edgar/layer_"+str(i+1))
		if layer == null || layer == "": continue
		edgar_layer_button.add_item(layer)

func get_data():
	return {
		"position_offset": {"x": position_offset.x, "y": position_offset.y},
		"is_corridor_room": room_type_button.selected if room_type_button.selected >= 0 else 0,
		"edgar_layer": edgar_layer_button.selected if edgar_layer_button.selected >= 0 else 0,
		"is_pivot": is_pivot_button.button_pressed,
	}

func set_data(data):
	position_offset = Vector2(data.position_offset.x, data.position_offset.y)
	room_type_button.select(data.is_corridor_room)
	edgar_layer_button.select(data.edgar_layer)
	is_pivot_button.button_pressed = data.is_pivot
