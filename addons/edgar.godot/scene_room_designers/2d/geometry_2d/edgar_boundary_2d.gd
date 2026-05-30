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
