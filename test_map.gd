extends Node2D
@onready var foreground: TileMapLayer = %Foreground
@onready var player_camera: Camera2D = %PlayerCamera

func _ready() -> void:
	await get_tree().create_timer(1).timeout
	var created_map: Array = get_visible_background_matrix(foreground, player_camera)
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
	var tile_rect_shape = RectangleShape2D.new()
	tile_rect_shape.extents = tile_size * 0.5

	# Query parameters (we reuse them)
	var shape_query := PhysicsShapeQueryParameters2D.new()
	shape_query.shape = tile_rect_shape

	for y in range(start_cell.y, end_cell.y):
		var row := []
		for x in range(start_cell.x, end_cell.x):
			# compute world center of tile
			var cell_center = Vector2(
				(x + 0.5) * tile_size.x,
				(y + 0.5) * tile_size.y
			)

			# set query transform
			shape_query.transform = Transform2D(0, cell_center)

			# intersect_shape returns collisions
			var collisions = space_state.intersect_shape(shape_query)

			# mark 1 if *any* collision detected
			row.append(0 if collisions.size() > 0 else 1)
		matrix.append(row)

	return matrix

####### Working function for foreground tiles #######

#func get_visible_background_matrix() -> Array:
	#var camera: Camera2D = $PlayerCamera
	#var tilemap: TileMapLayer = $Foreground
#
	## Camera rect in world space
	#var viewport_rect = get_viewport().get_visible_rect()
	#var cam_size = viewport_rect.size / camera.zoom
	#var camera_rect = Rect2(camera.global_position - cam_size / 2, cam_size)
#
	## Convert to tile coordinates
	#var start_cell = tilemap.local_to_map(tilemap.to_local(camera_rect.position))
	#var end_cell = tilemap.local_to_map(tilemap.to_local(camera_rect.position + camera_rect.size))
#
	#var min_x = min(start_cell.x, end_cell.x)
	#var max_x = max(start_cell.x, end_cell.x)
	#var min_y = min(start_cell.y, end_cell.y)
	#var max_y = max(start_cell.y, end_cell.y)
#
	#var matrix := []
#
	#for y in range(min_y, max_y + 1):
		#var row := []
		#for x in range(min_x, max_x + 1):
			#var cell = Vector2i(x, y)
			#if tilemap.get_cell_source_id(cell) != -1:
				#row.append(1)
			#else:
				#row.append(0)
		#matrix.append(row)
#
	#return matrix


func get_output(output: Array) -> void:
	for row in output:
		print(row)
