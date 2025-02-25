@tool
class_name EdgarGraphEditMenuButton
extends MenuButton

var popup : PopupMenu

signal id_pressed(id: int)
signal index_pressed(index: int)

func _ready() -> void:
	popup = get_popup()
	popup.id_pressed.connect(id_pressed.emit)
	popup.index_pressed.connect(index_pressed.emit)
