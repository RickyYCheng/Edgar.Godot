@tool
class_name EdgarBoundary2D
extends Polygon2D

func _init() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	
	if Engine.is_editor_hint() \
	and color == Color.WHITE:
		color = Color("FFCC9950")


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	var pts := polygon
	if pts.size() >= 2:
		for i in range(pts.size()):
			var a := pts[i]
			var b := pts[(i + 1) % pts.size()]
			if not _is_orthogonal(a, b):
				warnings.append("Edge %d→%d is not orthogonal (must be horizontal or vertical)." % [i, (i + 1) % pts.size()])
	return warnings


func _is_orthogonal(a: Vector2, b: Vector2) -> bool:
	return is_zero_approx(a.x - b.x) or is_zero_approx(a.y - b.y)
