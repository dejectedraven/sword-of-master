@tool
extends EditorScript

const TILE_SIZE := 16
const COLS := 80
const ROWS := 45

enum TileType { FLOOR, WALL, CHEST, EXIT }

var _map: Array = []  # [row][col] of int (TileType)

func _run():
	_generate_map()
	var ts = _make_tileset()
	if ts == null: printerr("TileSet creation failed"); return
	var err = ResourceSaver.save(ts, "res://resources/tilesets/dungeon_tileset.tres")
	if err != OK: printerr("TileSet save failed:", err); return
	var tm = _make_tilemap(ts)
	if tm == null: printerr("TileMap creation failed"); return
	var scn = PackedScene.new()
	var pack_err = scn.pack(tm)
	if pack_err != OK: printerr("TileMap pack failed:", pack_err); return
	err = ResourceSaver.save(scn, "res://scenes/map/dungeon.tscn")
	if err != OK: printerr("TileMap save failed:", err); return
	print("=== 地宫地图生成完成 ===")
	print("TileSet: resources/tilesets/dungeon_tileset.tres")
	print("TileMap: scenes/map/dungeon.tscn")
	print("在 Godot 里打开 dungeon.tscn 即可编辑地图")

# ===== 地图布局 =====
func _generate_map():
	# 全地板
	_map.clear()
	for r in range(ROWS):
		var row = []
		for c in range(COLS):
			row.append(TileType.FLOOR)
		_map.append(row)

	# 画矩形房间墙壁
	_rect_room(15, 22, 16, 10)   # 出生室（左中）
	_rect_room(40, 22, 22, 14)   # 中央战斗大厅
	_rect_room(64, 22, 12, 10)   # Boss室（右中）
	_rect_room(15, 9, 10, 6)     # 宝箱室1（左上）
	_rect_room(15, 37, 10, 6)    # 宝箱室2（左下）
	_rect_room(68, 37, 10, 6)    # 出口室（右下）

	# 走廊
	_h_corr(22, 22, 29, 22)      # 出生室右墙(22)→大厅左墙(29)
	_h_corr(50, 22, 58, 22)      # 大厅右墙(50)→Boss室左墙(58)
	_v_corr(15, 11, 17)          # 宝箱室1底墙(11)→出生室顶墙(17)
	_v_corr(15, 26, 34)          # 出生室底墙(26)→宝箱室2顶墙(34)
	_corr(58, 22, 68, 34)        # Boss室→出口室（到出口室顶部34）

	# 外圈墙壁
	for c in range(COLS):
		_set_tile(0, c, TileType.WALL); _set_tile(1, c, TileType.WALL)
		_set_tile(ROWS-1, c, TileType.WALL); _set_tile(ROWS-2, c, TileType.WALL)
	for r in range(ROWS):
		_set_tile(r, 0, TileType.WALL); _set_tile(r, 1, TileType.WALL)
		_set_tile(r, COLS-1, TileType.WALL); _set_tile(r, COLS-2, TileType.WALL)

	# 特殊点
	_set_tile(22, 15, TileType.FLOOR)    # 英雄出生（保留为地板，entity自己放）
	_set_tile(22, 64, TileType.FLOOR)    # Boss出生
	_set_tile(9, 15, TileType.CHEST)     # 宝箱1
	_set_tile(37, 15, TileType.CHEST)    # 宝箱2
	_set_tile(37, 68, TileType.EXIT)     # 出口

func _set_tile(r: int, c: int, v: int):
	if r >= 0 and r < ROWS and c >= 0 and c < COLS:
		_map[r][c] = v

func _rect_room(cx: int, cy: int, w: int, h: int):
	var x0 = cx - w/2; var y0 = cy - h/2
	var x1 = cx + w/2; var y1 = cy + h/2
	for r in range(y0, y1):
		for c in range(x0, x1):
			if r == y0 or r == y1-1 or c == x0 or c == x1-1:
				_set_tile(r, c, TileType.WALL)

func _h_corr(c1: int, r1: int, c2: int, r: int):
	for c in range(mini(c1, c2), maxi(c1, c2)+1):
		_set_tile(r, c, TileType.FLOOR)
		_set_tile(r-1, c, TileType.FLOOR) if r > 0 else null
		_set_tile(r+1, c, TileType.FLOOR) if r < ROWS-1 else null

func _v_corr(c: int, r1: int, r2: int):
	for r in range(mini(r1, r2), maxi(r1, r2)+1):
		_set_tile(r, c, TileType.FLOOR)
		_set_tile(r, c-1, TileType.FLOOR) if c > 0 else null
		_set_tile(r, c+1, TileType.FLOOR) if c < COLS-1 else null

func _corr(c1: int, r1: int, c2: int, r2: int):
	_h_corr(c1, r1, c2, r1)
	_v_corr(c2, r1, r2)

# ===== TileSet 生成 =====
func _make_tileset() -> TileSet:
	var ts = TileSet.new()
	ts.add_physics_layer(0)                # 创建物理层 0
	ts.set_physics_layer_collision_layer(0, 2)  # 该层映射到 collision_layer=2（墙壁）
	ts.set_physics_layer_collision_mask(0, 0)
	var src = TileSetAtlasSource.new()
	src.texture = load("res://assets/environment/tilesheets/Tilemap_Flat.png")
	src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	for row in 16:
		for col in 40:
			src.create_tile(Vector2i(col, row))

	ts.add_source(src, 0)                  # 源必须加入 TileSet 后，TileData 才能访问物理层

	# 行 4-15 = 墙壁，加碰撞（此时 src 已关联 ts）
	for row in 16:
		for col in 40:
			if row >= 4:
				var td = src.get_tile_data(Vector2i(col, row), 0)
				if td == null: continue
				var poly = PackedVector2Array([
					Vector2(0, 0), Vector2(TILE_SIZE, 0),
					Vector2(TILE_SIZE, TILE_SIZE), Vector2(0, TILE_SIZE)
				])
				td.add_collision_polygon(0)
				td.set_collision_polygon_points(0, 0, poly)

	return ts

# ===== TileMap 生成 =====
func _make_tilemap(ts: TileSet) -> TileMap:
	var tm = TileMap.new()
	tm.tile_set = ts
	tm.name = "Dungeon"
	# 碰撞层已在 TileSet 物理层 0 上设置（collision_layer=2）

	var walls = [
		Vector2i(0, 4), Vector2i(1, 5), Vector2i(2, 4), Vector2i(3, 5),
		Vector2i(4, 8), Vector2i(5, 8), Vector2i(6, 8),
	]
	var floors = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0),
		Vector2i(8, 1), Vector2i(9, 1), Vector2i(10, 1), Vector2i(11, 1),
		Vector2i(0, 2), Vector2i(1, 2),
	]

	for r in range(ROWS):
		for c in range(COLS):
			match _map[r][c]:
				TileType.WALL:
					var idx = (r * 7 + c * 13) % walls.size()
					tm.set_cell(0, Vector2i(c, r), 0, walls[idx])
				TileType.CHEST, TileType.EXIT:
					var idx = (r * 3 + c * 7) % floors.size()
					tm.set_cell(0, Vector2i(c, r), 0, floors[idx])
				_:
					var idx = (r * 17 + c * 11) % floors.size()
					tm.set_cell(0, Vector2i(c, r), 0, floors[idx])
	return tm
