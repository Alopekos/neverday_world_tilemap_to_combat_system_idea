extends Node2D
@onready var foreground: TileMapLayer = %Foreground
@onready var player_camera: Camera2D = %PlayerCamera
@onready var background: TileMapLayer = %Background

func _ready() -> void:
	await get_tree().create_timer(1).timeout
	var created_map: Array = get_visible_background_matrix(background, player_camera)
	get_output(created_map)


func get_visible_background_matrix(layer : TileMapLayer, camera : Camera2D) -> Array:

	# Get the TileSet and tile size
	var ts := layer.tile_set
	var tile_size: Vector2 = ts.tile_size
	
	# Compute world bounds of the viewport
	var viewport_rect = get_viewport().get_visible_rect()
	var world_size = viewport_rect.size / camera.zoom
	var world_start = camera.global_position - world_size * 0.5

	# Convert world bounds to cell range
	var start_cell = (world_start / tile_size).floor()
	var end_cell = ((world_start + world_size) / tile_size).ceil()

	var matrix := []
	var space_state = get_world_2d().direct_space_state

	# Prepare a reusable rectangle shape:
	var center_shape = CircleShape2D.new()
	center_shape.radius = 2.0   # small radius (1–4 pixels works well)



	# Query parameters (we reuse them)
	var shape_query := PhysicsShapeQueryParameters2D.new()
	shape_query.shape = center_shape

	for y in range(start_cell.y, end_cell.y):
		var row := []
		for x in range(start_cell.x, end_cell.x):
			# compute world center of tile
			var cell = Vector2i(x, y)
			var cell_center = Vector2((x + 0.5) * tile_size.x, (y + 0.5) * tile_size.y)

			# set circle for query transform
			shape_query.transform = Transform2D(0, cell_center)

			# check for tile and collisions
			var found_tile : bool = has_tile(layer, cell)
			var found_collisions : bool = has_collisions(space_state, shape_query)

			var walkable: bool = found_tile and not found_collisions
			row.append(1 if walkable else 0)
		matrix.append(row)

	return matrix

func has_collisions(space_state, shape_query)-> bool:
	return space_state.intersect_shape(shape_query).size() > 0

func has_tile(layer, cell) -> bool:
	return layer.get_cell_source_id(cell) != -1


func get_output(output: Array) -> void:
	for row in output:
		print(row)
