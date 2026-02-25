extends Node2D
@onready var foreground: TileMapLayer = %Foreground
@onready var player_camera: Camera2D = %PlayerCamera
@onready var background: TileMapLayer = %Background

func _ready() -> void:
	await get_tree().create_timer(1).timeout
	var created_map: Array = get_visible_background_matrix(background, player_camera)
	get_output(created_map)


func get_visible_background_matrix(tilemap : TileMapLayer, camera : Camera2D) -> Array:

	var tile_size: Vector2 = tilemap.tile_set.tile_size
	var camera_rect : Rect2 = get_camera_view_rect(camera)

	# Convert world bounds to cell range
	var start_cell = (camera_rect.position / tile_size).ceil()
	var end_cell = ((camera_rect.position + camera_rect.size) / tile_size).floor()

	var matrix := []
	var space_state = get_world_2d().direct_space_state

	# Prepare a reusable circle shape
	var center_shape : CircleShape2D = CircleShape2D.new()
	center_shape.radius = 2.0 

	# Query parameters of shape circle that gets reused
	var query : PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = center_shape

	for y in range(start_cell.y, end_cell.y):
		var row : Array = []
		for x in range(start_cell.x, end_cell.x):
			# compute world center of tile
			var cell = Vector2i(x, y)
			var cell_pos = get_tile_pos(cell, tile_size)
			var cell_rect = Rect2(cell_pos, tile_size)

			#Check if cell is fully display and not cut in half
			if not camera_rect.encloses(cell_rect):
				continue

			var center = cell_rect.get_center()
			query.transform = Transform2D(0, center)

			# check for tile and collisions
			var tile_exists : bool = tilemap.get_cell_source_id(cell) != -1
			var collision_exists : bool = space_state.intersect_shape(query).size() > 0

			var walkable: bool = tile_exists and not collision_exists
			
			#TODO depending on terrain and map change 1 to 2,3,4 etc.
			row.append(1 if walkable else 0)
		matrix.append(row)

	return matrix


func get_camera_view_rect(camera: Camera2D) -> Rect2:
	var viewport_size : Vector2 = get_viewport().get_visible_rect().size
	var world_size : Vector2 = viewport_size / camera.zoom
	var world_position : Vector2 = camera.global_position - world_size * 0.5
	
	return Rect2(world_position, world_size)


func get_tile_pos(cell: Vector2i, tile_size: Vector2)-> Vector2:
	return Vector2(cell.x * tile_size.x, cell.y * tile_size.y)


func get_output(output: Array) -> void:
	for row in output:
		print(row)
