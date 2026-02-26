extends Node2D
@onready var foreground: TileMapLayer = %Foreground
@onready var player_camera: Camera2D = %PlayerCamera
@onready var background: TileMapLayer = %Background

const TILE = preload("uid://cqjao80ty7ubn")

var tile_grid : Array = []

func _ready() -> void:
	var created_map: Array = await get_visible_background_matrix(background, player_camera)
	create_map(created_map, player_camera, background)
	show_map()


func get_visible_background_matrix(tilemap : TileMapLayer, camera : Camera2D) -> Array:
	await get_tree().physics_frame
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


func create_map(output: Array, camera: Camera2D, tilemap: TileMapLayer) -> void:
	if output.is_empty():
		return
	
	empty_grid(output)
	
	var tile_size : Vector2 = tilemap.tile_set.tile_size
	var camera_rect : Rect2 = get_camera_view_rect(camera)
	var start_cell = (camera_rect.position / tile_size).ceil()

	for y in range(output.size()):
		for x in range(output[y].size()):
			if output[y][x] == 1:
				var tile : Node2D = TILE.instantiate()
				tile.scale = camera.zoom
				var world_pos = Vector2(
					(start_cell.x + x) * tile_size.x + (tile_size.x / 2),
					(start_cell.y + y) * tile_size.y + (tile_size.y / 2)
				)

				var screen_pos = get_viewport().get_canvas_transform() * world_pos 

				tile.position = screen_pos
				
				%MapInstantializer.add_child(tile)
				tile_grid[y][x] = tile

func show_map() -> void:
	for i :int in range(tile_grid.size()):
		for j : int in range(tile_grid[0].size()):
			if tile_grid[i][j]:
				tile_grid[i][j].play_anim()
		await get_tree().create_timer(0.2).timeout

func get_output(output: Array) -> void:
	for row in output:
		print(row)

func empty_grid(output: Array) -> void:
	for y in range(output.size()):
		tile_grid.append([])
		for x in range(output[y].size()):
			tile_grid[y].append(null)
