@tool
class_name EdgarRenderer
extends TileMapLayer

signal markers_post_process(renderer: EdgarRenderer, markers: Node)
signal post_process(renderer: EdgarRenderer)

var generator: Callable
@export var level: Resource:
	get: return level
	set(v): 
		if not EdgarGodot.is_edgar_level_resource(v) and v != null: return
		level = v
		generator = EdgarGodot.get_generator(level)
@export var layout: Dictionary
@export_tool_button("Generate Layout") var generator_layout_btn : Callable = generate_layout

func _ready() -> void:
	if not Engine.is_editor_hint():
		_render()

func generate_layout() -> void:
	layout = generator.call()
	_render()

func _render() -> void:
	if layout == null:
		printerr("[EdgarGodot] Cannot render: layout is null.")
		return
	clear()
	for room in layout.rooms:
		var room_template = load(room.template)
		var tmj: Node = room_template.instantiate()
		for child in tmj.get_children():
			if child.name == "col" and child is TileMapLayer:
				if tile_set == null: tile_set = child.tile_set
				var tml : TileMapLayer = child
				var cells := tml.get_used_cells()
				for cell in cells:
					set_cell(cell + Vector2i(room.position / Vector2(tml.tile_set.tile_size)), tml.get_cell_source_id(cell), tml.get_cell_atlas_coords(cell), tml.get_cell_alternative_tile(cell))
			elif child.name == "markers":
				markers_post_process.emit(self, child)
		
		tmj.queue_free()
	post_process.emit(self)
