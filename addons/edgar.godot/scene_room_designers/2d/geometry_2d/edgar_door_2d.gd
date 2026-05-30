@tool
class_name EdgarDoor2D
extends Line2D

@export var segment_size := 1

func _init() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	
	if Engine.is_editor_hint() \
	and default_color == Color.WHITE:
		default_color = Color("99FFCC50")


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	var pts := points
	if pts.size() >= 2:
		for i in range(pts.size() - 1):
			if not _is_orthogonal(pts[i], pts[i + 1]):
				warnings.append("Segment %d→%d is not orthogonal (must be horizontal or vertical)." % [i, i + 1])
	return warnings


func _is_orthogonal(a: Vector2, b: Vector2) -> bool:
	return is_zero_approx(a.x - b.x) or is_zero_approx(a.y - b.y)
