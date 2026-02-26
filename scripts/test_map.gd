extends Node2D

@onready var foreground: TileMapLayer = %Foreground
@onready var player_camera: Camera2D = %PlayerCamera
@onready var background: TileMapLayer = %Background

const TILE = preload("uid://cqjao80ty7ubn")
const WATER_TILE = preload("uid://dgdcl5adywn2t")

var camera_rect: Rect2
var tile_size: Vector2
var start_cell: Vector2i
var end_cell: Vector2i

const tile_names: Dictionary = {
	0: "Empty",
	2: "Ground",
	3: "Water"
}

#DEMO
var tile_grid: Array = []
var toggle_show_map: bool = false
var map_loading: bool = false
var foreground_in_fore : bool = true

#DEMO
signal map_freed

#DEMO
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if foreground_in_fore:
			%Foreground.z_index = 0
			%MapInstantializer.z_index = 1
			foreground_in_fore = false
		elif not foreground_in_fore:
			%Foreground.z_index = 1
			%MapInstantializer.z_index = 0
			foreground_in_fore = true
	
	if not event.is_action_pressed("ui_select"):
		return

	if map_loading:
		return

	if not toggle_show_map:
		map_loading = true
		toggle_show_map = true

		var created_map: Array = await get_visible_background_matrix(background, player_camera)
		create_map(created_map)
		await show_map()

		map_loading = false
	else:
		map_loading = true
		toggle_show_map = false

		hide_map()
		await map_freed

		map_loading = false


func get_visible_background_matrix(tilemap: TileMapLayer, camera: Camera2D) -> Array:
	await get_tree().physics_frame
	await get_tree().physics_frame

	set_tile_size(tilemap)
	set_camera_view_rect(camera)
	set_first_and_last_cell()

	var matrix: Array = []
	var space_state = get_world_2d().direct_space_state

	var center_shape: CircleShape2D = CircleShape2D.new()
	center_shape.radius = 2.0

	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = center_shape

	for y in range(start_cell.y, end_cell.y):
		var row: Array = []

		for x in range(start_cell.x, end_cell.x):
			var cell := Vector2i(x, y)
			var cell_pos := get_tile_pos(cell)
			var cell_rect := Rect2(cell_pos, tile_size)

			if not camera_rect.encloses(cell_rect):
				continue

			var center := cell_rect.get_center()
			query.transform = Transform2D(0, center)

			var collision_exists: bool = space_state.intersect_shape(query).size() > 0
			var tile_type: String = tile_names.get(tilemap.get_cell_source_id(cell), "Empty")
			var number_in_data: int = match_tile(tile_type, collision_exists)

			row.append(number_in_data)

		matrix.append(row)

	return matrix


func match_tile(tile_type: String, collision: bool) -> int:
	match tile_type:
		"Ground":
			return 0 if collision else 1
		"Water":
			return 2
		"Empty", _:
			return 0


func set_tile_size(tilemap: TileMapLayer) -> void:
	tile_size = tilemap.tile_set.tile_size


func set_camera_view_rect(camera: Camera2D) -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var world_size: Vector2 = viewport_size / camera.zoom
	var world_position: Vector2 = camera.global_position - world_size * 0.5

	camera_rect = Rect2(world_position, world_size)


func set_first_and_last_cell() -> void:
	start_cell = (camera_rect.position / tile_size).ceil()
	end_cell = ((camera_rect.position + camera_rect.size) / tile_size).floor()


func get_tile_pos(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * tile_size.x, cell.y * tile_size.y)

#DEMO
func create_map(output: Array) -> void:
	if output.is_empty():
		return

	empty_grid(output)

	for y in range(output.size()):
		for x in range(output[y].size()):
			var tile_position := Vector2(x, y)

			match output[y][x]:
				1:
					instantiate_tile(TILE, tile_position)
				2:
					instantiate_tile(WATER_TILE, tile_position)
				_:
					continue


func instantiate_tile(tile_scene: PackedScene, tile_position: Vector2) -> void:
	var tile: Node2D = tile_scene.instantiate()

	var world_pos := Vector2(
		(start_cell.x + tile_position.x) * tile_size.x + tile_size.x * 0.5,
		(start_cell.y + tile_position.y) * tile_size.y + tile_size.y * 0.5
	)

	tile.position = world_pos

	%MapInstantializer.add_child(tile)
	tile_grid[tile_position.y][tile_position.x] = tile


func show_map() -> void:
	if tile_grid.is_empty():
		return

	for i in range(tile_grid.size()):
		for j in range(tile_grid[i].size()):
			if tile_grid[i][j]:
				tile_grid[i][j].play_anim()

		await get_tree().create_timer(0.2).timeout


func hide_map() -> void:
	if tile_grid.is_empty():
		map_freed.emit()
		return

	for i in range(tile_grid.size()):
		for j in range(tile_grid[i].size()):
			if tile_grid[i][j]:
				tile_grid[i][j].play_anim_reversed()

		await get_tree().create_timer(0.2).timeout

	for i in range(tile_grid.size()):
		for j in range(tile_grid[i].size()):
			if tile_grid[i][j]:
				tile_grid[i][j].queue_free()

	tile_grid.clear()
	map_freed.emit()


func empty_grid(output: Array) -> void:
	tile_grid.clear()

	for y in range(output.size()):
		tile_grid.append([])

		for x in range(output[y].size()):
			tile_grid[y].append(null)
