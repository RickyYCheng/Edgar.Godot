@tool
class_name EdgarGraphNode
extends GraphNode

@onready var room_type_button: OptionButton = $RoomTypeButton
@onready var edgar_layer_button: OptionButton = $EdgarLayerButton

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
	}

func set_data(data):
	position_offset = Vector2(data.position_offset.x, data.position_offset.y)
	room_type_button.select(data.is_corridor_room)
	edgar_layer_button.select(data.edgar_layer)
