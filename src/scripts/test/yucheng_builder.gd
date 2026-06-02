extends Node

# P7：玉城主场景骨架（full 版）
# - 30×20 tile 街区，分 5 块视觉区（北休息区 / 中央街道 / 东废墟 / 南天堂口 / 西商店）
# - 8 个站桩 NPC（路人×2 + 郑英雄 + 思维 + 顾禹 + 聂北 + 商店老板 + 信息员）
# - 通往面试房间的入口（中央南侧）
# - 通往雨地的入口（保留）
# - 任务标记光柱（待 P7 阶段 5 接 QuestState）

@export var ground_layer_path: NodePath = NodePath("../Ground")
@export var ysort_path: NodePath = NodePath("../YSortContainer")

const TILE_GROUND: Vector2i = Vector2i(0, 0)
const TILE_DANGER: Vector2i = Vector2i(1, 0)
const TILE_GRASS: Vector2i = Vector2i(2, 0)
const TILE_WATER: Vector2i = Vector2i(3, 0)

const NPC_TEX: Texture2D = preload("res://src/assets/characters/player_placeholder.png")
const BUILDING_TEX: Texture2D = preload("res://src/assets/characters/building_placeholder.png")
const SUBMIT_TEX: Texture2D = preload("res://src/assets/characters/submit_marker.png")
const MOOD_BUBBLE_SCRIPT: Script = preload("res://src/scripts/liar_game/npc_mood_bubble.gd")

# NPC 配置（统一处理，避免 8 个独立函数）
# 每条：[id, dialogue_id, display_name, world_pos, color, special_kind ("" / "shop" / "info")]
const NPCS: Array = [
	["passer_a",       "yu_passer_a",       "茫然的女路人",   Vector2(-160, -120), Color(0.85, 0.65, 0.95), ""],
	["passer_b",       "yu_passer_b",       "受惊的男路人",   Vector2(220, -100),  Color(0.95, 0.45, 0.30), ""],
	["gu_yu",          "yu_gu_yu",          "顾禹·云游者",   Vector2(240, -180),  Color(0.45, 0.55, 0.95), ""],
	["si_wei",         "yu_si_wei",         "思维·智者",     Vector2(-100, 180),  Color(0.45, 0.95, 0.55), ""],
	["nie_bei",        "yu_nie_bei",        "聂北·玉城首领",  Vector2(60, 200),    Color(0.95, 0.85, 0.30), ""],
	["shopkeeper",     "yu_shopkeeper",     "玉城货摊老板",   Vector2(-260, 40),   Color(0.85, 0.55, 0.25), "shop"],
	["zheng_yingxiong","yu_zheng_yingxiong","郑英雄·清香者",  Vector2(-230, -30),  Color(0.45, 0.75, 1.0),  ""],
	["info_board",     "yu_info_board",     "玉城信息员",     Vector2(0, 40),      Color(0.95, 0.92, 0.85), "info"],
	# P8：东区废墟旁，戴鼠面具的女孩开了个小考验
	["rat_npc",        "rat_npc_yucheng",   "人鼠·瘦小女孩", Vector2(320, -60),   Color(0.7, 0.65, 0.6),   "game"],
]

func _ready() -> void:
	_build_ground()
	_spawn_decorations()
	_spawn_npcs()
	_spawn_interview_entrance()
	_spawn_rainy_field_door()

# ===== 街景 =====

func _build_ground() -> void:
	var ground: TileMapLayer = get_node_or_null(ground_layer_path) as TileMapLayer
	if ground == null:
		push_error("YuchengBuilder: TileMapLayer not found")
		return
	# 30×20 街区，按象限分 5 块
	for x in range(-15, 16):
		for y in range(-10, 11):
			ground.set_cell(Vector2i(x, y), 0, _tile_for(x, y))

func _tile_for(x: int, y: int) -> Vector2i:
	# 中央十字街道（宽度 4 格）保持默认地砖
	if abs(x) <= 2 or abs(y) <= 2:
		return TILE_GROUND
	# 西区·商店：水（蓝）作为店面背景反差
	if x < -2 and y < 0:
		return TILE_WATER
	# 北区·休息区：草地
	if y < -2 and x > 0:
		return TILE_GRASS
	# 东区·废墟：危险红
	if x > 2 and y >= 0:
		return TILE_DANGER
	# 南区·天堂口：水
	if y > 2 and x <= 0:
		return TILE_WATER
	return TILE_GROUND

func _spawn_decorations() -> void:
	# 4 个建筑摆设（每个分区一个），让玩家有"区域感"
	var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
	if ysort == null: return
	var deco_positions: Array = [
		Vector2(-320, -160),   ## 商店招牌
		Vector2(280, -200),    ## 废墟塔
		Vector2(-180, 280),    ## 天堂口石碑
		Vector2(180, 280),     ## 天堂口塔楼
	]
	for pos in deco_positions:
		var sb := StaticBody2D.new()
		sb.position = pos
		var s := Sprite2D.new()
		s.texture = BUILDING_TEX
		s.modulate = Color(0.6, 0.55, 0.5, 0.85)
		sb.add_child(s)
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(96, 64)
		col.shape = shape
		col.position = Vector2(0, 12)
		sb.add_child(col)
		ysort.add_child(sb)

# ===== NPC =====

func _spawn_npcs() -> void:
	var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
	if ysort == null: return
	var interactable_script: Script = load("res://src/scripts/interaction/interactable.gd")
	for entry in NPCS:
		var node_name: String = entry[0]
		var dialogue_id: String = entry[1]
		var display_name: String = entry[2]
		var pos: Vector2 = entry[3]
		var color: Color = entry[4]
		var special: String = entry[5]
		_spawn_one_npc(ysort, interactable_script, node_name, dialogue_id, display_name, pos, color, special)

func _spawn_one_npc(ysort: Node2D, interactable_script: Script,
		node_name: String, dialogue_id: String, display_name: String,
		pos: Vector2, color: Color, special: String) -> void:
	var body: CharacterBody2D = CharacterBody2D.new()
	body.name = "Yu_" + node_name
	body.position = pos

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = NPC_TEX
	sprite.modulate = color
	body.add_child(sprite)

	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 8
	col.shape = shape
	col.position = Vector2(0, 14)
	body.add_child(col)

	var inter: Area2D = Area2D.new()
	inter.name = "Interactable"
	inter.set_script(interactable_script)
	inter.collision_layer = 2
	inter.collision_mask = 0
	inter.set("interaction_type", 1)   ## DIALOGUE
	inter.set("dialogue_id", dialogue_id)
	var prompt_prefix: String = "[E] "
	if special == "shop":
		prompt_prefix = "[E] 找老板买点东西 · "
	elif special == "info":
		prompt_prefix = "[E] 看一眼信息板 · "
	elif special == "game":
		prompt_prefix = "[E] 听听她的「考验」 · "
	inter.set("prompt_text", prompt_prefix + "与 " + display_name + " 交谈")
	var ishape: CollisionShape2D = CollisionShape2D.new()
	var icirc: CircleShape2D = CircleShape2D.new()
	icirc.radius = 32
	ishape.shape = icirc
	ishape.position = Vector2(0, 14)
	inter.add_child(ishape)
	body.add_child(inter)

	# 微表情气泡（沿用 P4 final · b1）
	var bubble := Node2D.new()
	bubble.name = "MoodBubble"
	bubble.set_script(MOOD_BUBBLE_SCRIPT)
	body.add_child(bubble)

	ysort.add_child(body)

# ===== 出入口 =====

func _spawn_interview_entrance() -> void:
	# 通往面试房间的入口（中央南侧）
	var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
	if ysort == null: return
	var interactable_script: Script = load("res://src/scripts/interaction/interactable.gd")
	var door: Node2D = Node2D.new()
	door.name = "InterviewEntrance"
	door.position = Vector2(0, 140)

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = SUBMIT_TEX
	sprite.modulate = Color(0.95, 0.45, 0.45, 1.0)   ## 暗红 = "面试房间"
	sprite.scale = Vector2(1.4, 1.4)
	door.add_child(sprite)

	var label: Label = Label.new()
	label.text = "[面试房间]"
	label.position = Vector2(-36, 22)
	label.add_theme_color_override("font_color", Color(0.95, 0.55, 0.55))
	label.add_theme_font_size_override("font_size", 11)
	door.add_child(label)

	var inter: Area2D = Area2D.new()
	inter.name = "Interactable"
	inter.set_script(interactable_script)
	inter.collision_layer = 2
	inter.collision_mask = 0
	inter.set("interaction_type", 3)   ## SCENE_CHANGE
	inter.set("scene_path", "res://src/scenes/world/interview_room.tscn")
	inter.set("prompt_text", "[E] 走进面试房间（再活一次）")
	var ishape: CollisionShape2D = CollisionShape2D.new()
	var icirc: CircleShape2D = CircleShape2D.new()
	icirc.radius = 32
	ishape.shape = icirc
	inter.add_child(ishape)
	door.add_child(inter)

	ysort.add_child(door)

func _spawn_rainy_field_door() -> void:
	# 雨地（独立测试场景，原作里雨后春笋已并入面试房，但保留这扇门用于纯玩法测试）
	var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
	if ysort == null: return
	var interactable_script: Script = load("res://src/scripts/interaction/interactable.gd")
	var door: Node2D = Node2D.new()
	door.name = "RainyFieldDoor"
	door.position = Vector2(320, 220)   ## 南区·东侧

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = SUBMIT_TEX
	sprite.modulate = Color(1.0, 0.6, 0.4, 1.0)
	sprite.scale = Vector2(1.2, 1.2)
	door.add_child(sprite)

	var label: Label = Label.new()
	label.text = "[雨地 · 测试用]"
	label.position = Vector2(-44, 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.6))
	label.add_theme_font_size_override("font_size", 11)
	door.add_child(label)

	var inter: Area2D = Area2D.new()
	inter.name = "Interactable"
	inter.set_script(interactable_script)
	inter.collision_layer = 2
	inter.collision_mask = 0
	inter.set("interaction_type", 3)
	inter.set("scene_path", "res://src/scenes/world/rainy_field.tscn")
	inter.set("prompt_text", "[E] 进入雨地（独立场景）")
	var ishape: CollisionShape2D = CollisionShape2D.new()
	var icirc: CircleShape2D = CircleShape2D.new()
	icirc.radius = 32
	ishape.shape = icirc
	inter.add_child(ishape)
	door.add_child(inter)

	ysort.add_child(door)
