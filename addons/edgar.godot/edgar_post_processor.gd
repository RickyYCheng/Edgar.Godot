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

func _post_process(base_node: Node2D):
	var lnk : Node2D = base_node.get_children().filter(func(node): return node.has_meta("lnk"))[0]
	
	var boundary : PackedVector2Array
	var doors : Array[PackedVector2Array]
	
	for node in lnk.get_children():
		if not node.has_meta("lnk"): continue
		match node.get_meta("lnk"):
			"boundary": 
				boundary = node.polygon
				for i in range(boundary.size()):
					boundary[i] += node.position
			"door": 
				var door : PackedVector2Array = node.points
				for i in range(door.size()):
					door[i] += node.position
				doors.push_back(door)
			_: pass
	
	var lnk_dict := {
		"boundary": boundary,
		"doors": doors,
	}
	
	base_node.set_meta("lnk", lnk_dict)
	
	base_node.remove_child(lnk)
	lnk.queue_free()
	
	return base_node
