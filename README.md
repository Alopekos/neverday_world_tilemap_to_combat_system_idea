# 🟦 Tile Grid Adaptable to a TileMapLayer for Neverday 🟦

Hey! This little project is a **dynamic grid of tiles** that adapts to a 2D Godot environment depending on the camera.  
It checks if a tile exists and isn’t blocked by collisions.  
For now it spawns a fake visual `tile_grid` 🔳 but could easily be expanded into a combat or pathfinding system.

Don't ask about Neverday when though : 

![giphy](https://github.com/user-attachments/assets/7adf3781-f171-442d-ae47-125a39aabf97)

( or Neverday where or Neverday ever or Never Neverday Ever Neverday or Ever Never )

---

## 🎮 How to Test It

- git clone this repo  
- Launch Godot (made with **Godot 4.6**)  
- Move and zoom the camera around, add collisions, and enjoy! 🚀  

---

## How It Works

### 1️⃣ Get camera view in world space

```gdscript
var viewport_size = get_viewport().get_visible_rect().size
var world_size = viewport_size / camera.zoom
var world_position = camera.global_position - world_size * 0.5
var camera_rect = Rect2(world_position, world_size)
```

---

### 2️⃣ Build visible matrix

- Loop through the visible tile range 🔲  
- Check if a tile exists and has no collision overlapping wih it  
- Store `1` if walkable, `0` if not 

---

### 3️⃣ Spawn tiles

```gdscript
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
```

- `tile_grid[y][x]` stores references to tiles
- If using `CanvasLayer`, scale by `camera.zoom` so tiles match world size

---

## ✨ Notes

- Camera does **not move nodes**; it just changes how the canvas is drawn.  
- World → screen conversion in Godot 4:

```gdscript
screen_pos = get_viewport().get_canvas_transform() * world_pos
```

---

Feel free to reuse or expand this little experiment! 🛠️
