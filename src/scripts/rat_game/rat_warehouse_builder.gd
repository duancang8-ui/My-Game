extends Node

# P8：人鼠仓库场景生成器
# - 小型仓库（14×10 tile）
# - 6 个货架（按 E 触发 rat_box_X 对话）
# - 1 个白炽灯开关（按 E 切换灯光，做"主观存在感"）
# - 1 张「仓鼠协会」贴纸（按 E 触发 rat_hamster_note + 写入 observed_clues）
# - 1 个人鼠 NPC（门口站桩，Orchestrator 切换其 dialogue_id v1/v2）
# - 1 扇离开门（SCENE_CHANGE → yucheng_main）

@export var ground_layer_path: NodePath = NodePath("../Ground")
@export var ysort_path: NodePath = NodePath("../YSortContainer")

const TILE_GROUND: Vector2i = Vector2i(0, 0)
const TILE_DANGER: Vector2i = Vector2i(1, 0)

const BUILDING_TEX: Texture2D = preload("res://src/assets/characters/building_placeholder.png")
const TABLE_TEX: Texture2D = preload("res://src/assets/characters/table_placeholder.png")
const NPC_TEX: Texture2D = preload("res://src/assets/characters/player_placeholder.png")
const SUBMIT_TEX: Texture2D = preload("res://src/assets/characters/submit_marker.png")

# 6 个箱子的位置 + dialogue_id
const BOXES: Array = [
	[Vector2(-180, -80),  "rat_box_1"],
	[Vector2(-60, -80),   "rat_box_2"],
	[Vector2(60, -80),    "rat_box_3"],
	[Vector2(-180, 40),   "rat_box_4"],
	[Vector2(-60, 40),    "rat_box_5"],
	[Vector2(60, 40),     "rat_box_6"],
]

# 灯光状态（仅做"主观存在感"，不影响判定）
var _light_on: bool = true
var _light_overlay: ColorRect = null

func _ready() -> void:
	_build_ground()
	_spawn_walls()
	_spawn_boxes()
	_spawn_hamster_note()
	_spawn_light_switch()
	_spawn_rat_npc()
	_spawn_exit_door()
	_spawn_light_overlay()

# ===== 地图 =====

func _build_ground() -> void:
	var ground: TileMapLayer = get_node_or_null(ground_layer_path) as TileMapLayer
	if ground == null:
		push_error("RatWarehouseBuilder: TileMapLayer not found")
		return
	# 14×10 小仓库
	for x in range(-7, 8):
		for y in range(-5, 6):
			ground.set_cell(Vector2i(x, y), 0, TILE_GROUND)

func _spawn_walls() -> void:
	# 4 面墙（用 StaticBody2D + RectangleShape2D 围一圈，防止玩家走出）
	var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
	if ysort == null: return
	var walls: Array = [
		[Vector2(0, -180), Vector2(480, 16)],   # 上墙
		[Vector2(0, 180),  Vector2(480, 16)],   # 下墙
		[Vector2(-240, 0), Vector2(16, 360)],   # 左墙
		[Vector2(240, 0),  Vector2(16, 360)],   # 右墙
	]
	for w in walls:
		var sb := StaticBody2D.new()
		sb.position = w[0]
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = w[1]
		col.shape = shape
		sb.add_child(col)
		ysort.add_child(sb)

# ===== 6 个箱子 =====

func _spawn_boxes() -> void:
	var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
	if ysort == null: return
	var interactable_script: Script = load("res://src/scripts/interaction/interactable.gd")
	for entry in BOXES:
		var pos: Vector2 = entry[0]
		var dialogue_id: String = entry[1]
		var box: StaticBody2D = StaticBody2D.new()
		box.name = "Box_" + dialogue_id
		box.position = pos

		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = TABLE_TEX
		sprite.modulate = Color(0.65, 0.55, 0.45, 1.0)
		sprite.scale = Vector2(0.7, 0.7)
		box.add_child(sprite)

		var col: CollisionShape2D = CollisionShape2D.new()
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = Vector2(60, 36)
		col.shape = shape
		col.position = Vector2(0, 6)
		box.add_child(col)

		var inter: Area2D = Area2D.new()
		inter.name = "Interactable"
		inter.set_script(interactable_script)
		inter.collision_layer = 2
		inter.collision_mask = 0
		inter.set("interaction_type", 1)   ## DIALOGUE
		inter.set("dialogue_id", dialogue_id)
		inter.set("prompt_text", "[E] 翻这个箱子")
		var ishape: CollisionShape2D = CollisionShape2D.new()
		var icirc: CircleShape2D = CircleShape2D.new()
		icirc.radius = 28
		ishape.shape = icirc
		inter.add_child(ishape)
		box.add_child(inter)

		ysort.add_child(box)

# ===== 仓鼠协会贴纸（破解线索）=====

func _spawn_hamster_note() -> void:
	var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
	if ysort == null: return
	var interactable_script: Script = load("res://src/scripts/interaction/interactable.gd")
	var note: Node2D = Node2D.new()
	note.name = "HamsterNote"
	note.position = Vector2(180, -150)   ## 右上角门框附近

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = SUBMIT_TEX
	sprite.modulate = Color(0.95, 0.85, 0.65, 0.8)
	sprite.scale = Vector2(0.45, 0.45)
	note.add_child(sprite)

	var label: Label = Label.new()
	label.text = "（旧贴纸）"
	label.position = Vector2(-30, 18)
	label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.6))
	label.add_theme_font_size_override("font_size", 10)
	note.add_child(label)

	var inter: Area2D = Area2D.new()
	inter.name = "Interactable"
	inter.set_script(interactable_script)
	inter.collision_layer = 2
	inter.collision_mask = 0
	inter.set("interaction_type", 1)   ## DIALOGUE
	inter.set("dialogue_id", "rat_hamster_note")
	inter.set("prompt_text", "[E] 看一眼这张贴纸")
	var ishape: CollisionShape2D = CollisionShape2D.new()
	var icirc: CircleShape2D = CircleShape2D.new()
	icirc.radius = 24
	ishape.shape = icirc
	inter.add_child(ishape)
	note.add_child(inter)

	ysort.add_child(note)

# ===== 白炽灯开关 + 灯光遮罩 =====

func _spawn_light_switch() -> void:
	var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
	if ysort == null: return
	var interactable_script: Script = load("res://src/scripts/interaction/interactable.gd")
	var sw: Node2D = Node2D.new()
	sw.name = "LightSwitch"
	sw.position = Vector2(-200, -150)

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = SUBMIT_TEX
	sprite.modulate = Color(0.85, 0.85, 0.95, 0.9)
	sprite.scale = Vector2(0.4, 0.4)
	sw.add_child(sprite)

	var label: Label = Label.new()
	label.text = "💡 灯开关"
	label.position = Vector2(-26, 16)
	label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	label.add_theme_font_size_override("font_size", 10)
	sw.add_child(label)

	var inter: Area2D = Area2D.new()
	inter.name = "Interactable"
	inter.set_script(interactable_script)
	inter.collision_layer = 2
	inter.collision_mask = 0
	inter.set("interaction_type", 2)   ## PICKUP（用作"toggle"语义，Orchestrator/builder 自己处理）
	inter.set("prompt_text", "[E] 按一下灯开关")
	# 自己监听这个 interactable 的 interaction_triggered → 切换灯
	inter.interaction_triggered.connect(_on_light_switch_pressed)
	var ishape: CollisionShape2D = CollisionShape2D.new()
	var icirc: CircleShape2D = CircleShape2D.new()
	icirc.radius = 22
	ishape.shape = icirc
	inter.add_child(ishape)
	sw.add_child(inter)

	ysort.add_child(sw)

func _on_light_switch_pressed(_inter: Interactable) -> void:
	_light_on = not _light_on
	if _light_overlay != null:
		_light_overlay.color = Color(0, 0, 0, 0.0) if _light_on else Color(0, 0, 0, 0.7)
	if Toast != null:
		Toast.show_info("灯%s了" % ["开" if _light_on else "关"])
	if AudioManager != null:
		AudioManager.play_sfx("light_switch")

func _spawn_light_overlay() -> void:
	# 全屏黑色遮罩（仅在灯关闭时显示，呼应原作"道应该发光"的陷阱）
	_light_overlay = ColorRect.new()
	_light_overlay.color = Color(0, 0, 0, 0)
	_light_overlay.anchor_left = 0
	_light_overlay.anchor_top = 0
	_light_overlay.anchor_right = 1
	_light_overlay.anchor_bottom = 1
	_light_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_light_overlay.z_index = -1   ## 不挡 HUD
	var layer := CanvasLayer.new()
	layer.layer = 3
	add_child(layer)
	layer.add_child(_light_overlay)

# ===== 人鼠 NPC（门口）=====

func _spawn_rat_npc() -> void:
	var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
	if ysort == null: return
	var interactable_script: Script = load("res://src/scripts/interaction/interactable.gd")
	var npc: CharacterBody2D = CharacterBody2D.new()
	npc.name = "RatNpc"
	npc.position = Vector2(140, 160)   ## 右下角门口

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = NPC_TEX
	sprite.modulate = Color(0.7, 0.65, 0.6, 1.0)   ## 鼠灰
	npc.add_child(sprite)

	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 8
	col.shape = shape
	col.position = Vector2(0, 14)
	npc.add_child(col)

	var inter: Area2D = Area2D.new()
	inter.name = "Interactable"
	inter.set_script(interactable_script)
	inter.collision_layer = 2
	inter.collision_mask = 0
	inter.set("interaction_type", 1)   ## DIALOGUE
	inter.set("dialogue_id", "rat_door_talk")   ## 初始 v1；Orchestrator 视情况切到 v2
	inter.set("prompt_text", "[E] 跟门口的人鼠搭话")
	var ishape: CollisionShape2D = CollisionShape2D.new()
	var icirc: CircleShape2D = CircleShape2D.new()
	icirc.radius = 32
	ishape.shape = icirc
	ishape.position = Vector2(0, 14)
	inter.add_child(ishape)
	npc.add_child(inter)

	ysort.add_child(npc)

# ===== 离开门（直接回玉城；门票不退）=====

func _spawn_exit_door() -> void:
	var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
	if ysort == null: return
	var interactable_script: Script = load("res://src/scripts/interaction/interactable.gd")
	var door: Node2D = Node2D.new()
	door.name = "ExitDoor"
	door.position = Vector2(200, 160)

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = SUBMIT_TEX
	sprite.modulate = Color(0.5, 0.85, 1.0, 1.0)
	sprite.scale = Vector2(1.1, 1.1)
	door.add_child(sprite)

	var label: Label = Label.new()
	label.text = "[离开 · 回玉城]"
	label.position = Vector2(-44, 18)
	label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	label.add_theme_font_size_override("font_size", 11)
	door.add_child(label)

	var inter: Area2D = Area2D.new()
	inter.name = "Interactable"
	inter.set_script(interactable_script)
	inter.collision_layer = 2
	inter.collision_mask = 0
	inter.set("interaction_type", 3)   ## SCENE_CHANGE
	inter.set("scene_path", "res://src/scenes/world/yucheng_main.tscn")
	inter.set("prompt_text", "[E] 离开仓库（门票不退）")
	var ishape: CollisionShape2D = CollisionShape2D.new()
	var icirc: CircleShape2D = CircleShape2D.new()
	icirc.radius = 28
	ishape.shape = icirc
	inter.add_child(ishape)
	door.add_child(inter)

	ysort.add_child(door)
