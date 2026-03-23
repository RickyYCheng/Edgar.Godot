@tool
extends EdgarRenderer2D

func generate_layout() -> void:
	level = _generate_rnd_level_resource()
	super()

func _generate_rnd_level_resource() -> EdgarGraphResource:
	var res := EdgarGraphResource.new()
	
	res.set_meta("source_file", null) # empty for dynamic res
	res.set_meta("is_edgar_graph", true)
	
	var nodes := {}
	var edges := []
	
	# Create a local RNG with the injected seed for deterministic graph generation
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	
	# Randomly generate 1-3 basic rooms using the injected seed
	var basic_room_count := rng.randi_range(1, 3)
	var basic_room_names: PackedStringArray = []
	
	for i in basic_room_count:
		var room_name := "Room %d" % (i + 1)
		basic_room_names.append(room_name)
		nodes[room_name] = {
			"is_corridor_room": 0,
			"edgar_layer": 0,
			"is_pivot": false,
			"position_offset": {"x": 180.0 + i * 220.0, "y": 160.0},
		}
	
	# Always include the limit room
	nodes["Room Limit"] = {
		"is_corridor_room": 0,
		"edgar_layer": 1,
		"is_pivot": true,
		"position_offset": {"x": 180.0 + (basic_room_count - 1) * 110.0, "y": 380.0},
	}
	
	# Connect basic rooms linearly
	for i in basic_room_names.size() - 1:
		edges.append({
			"from_node": basic_room_names[i],
			"to_node": basic_room_names[i + 1]
		})
	
	# Connect the first basic room to the limit room
	if basic_room_names.size() > 0:
		edges.append({
			"from_node": basic_room_names[0],
			"to_node": "Room Limit"
		})
	
	var layers := [
		["res://examples/shared/basic.tmj"],  # layer 0: basic rooms
		["res://examples/shared/limit.tmj"]   # layer 1: limit room
	]
	
	res.set_meta("nodes", nodes)
	res.set_meta("edges", edges)
	res.set_meta("layers", layers)
	
	return res
