extends Node

# P10：黑熊地下室场地生成
# - 16×10 暗色地下室
# - 中央铁圆板（视觉装饰）
# - 3 根铁柱按三角分布（玩家躲咆哮的安全锚）
# - 1 只黑熊 sprite（中央偏上，仅装饰 + 视觉震慑，不做 AI 追击）
# - 离开门（SCENE_CHANGE → yucheng_main）

@export var ground_layer_path: NodePath = NodePath("../Ground")
@export var ysort_path: NodePath = NodePath("../YSortContainer")

const TILE_GROUND: Vector2i = Vector2i(0, 0)
const TILE_DANGER: Vector2i = Vector2i(1, 0)

const NPC_TEX: Texture2D = preload("res://src/assets/characters/player_placeholder.png")
const TABLE_TEX: Texture2D = preload("res://src/assets/characters/table_placeholder.png")
const BUILDING_TEX: Texture2D = preload("res://src/assets/characters/building_placeholder.png")
const SUBMIT_TEX: Texture2D = preload("res://src/assets/characters/submit_marker.png")

# 3 根铁柱的位置（三角分布）
const PILLAR_POSITIONS: Array = [
	Vector2(-160, -80),   ## 左上
	Vector2(160, -80),    ## 右上
	Vector2(0, 140),      ## 下方
]

# 玩家在"咆哮判定时" 距离任意铁柱半径多少算"安全"
const SAFE_RADIUS: float = 60.0

# 实例引用，给 Orchestrator 查询玩家"是否安全"
var pillar_nodes: Array = []
var bear_sprite_node: Sprite2D = null

func _ready() -> void:
	_build_ground()
	_spawn_walls()
	_spawn_center_plate()
	_spawn_pillars()
	_spawn_bear()
	_spawn_exit_door()

func _build_ground() -> void:
	var ground: TileMapLayer = get_node_or_null(ground_layer_path) as TileMapLayer
	if ground == null:
		push_error("BearLairBuilder: TileMapLayer not found")
		return
	for x in range(-8, 9):
		for y in range(-5, 6):
			ground.set_cell(Vector2i(x, y), 0, TILE_GROUND)

func _spawn_walls() -> void:
	var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
	if ysort == null: return
	var walls: Array = [
		[Vector2(0, -200), Vector2(560, 16)],
		[Vector2(0, 200),  Vector2(560, 16)],
		[Vector2(-280, 0), Vector2(16, 400)],
		[Vector2(280, 0),  Vector2(16, 400)],
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

func _spawn_center_plate() -> void:
	var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
	if ysort == null: return
	var plate: Node2D = Node2D.new()
	plate.name = "CenterPlate"
	plate.position = Vector2(0, 0)
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = TABLE_TEX
	sprite.modulate = Color(0.35, 0.30, 0.28, 1.0)   ## 铁灰
	sprite.scale = Vector2(0.7, 0.7)
	plate.add_child(sprite)
	ysort.add_child(plate)

func _spawn_pillars() -> void:
	var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
	if ysort == null: return
	pillar_nodes.clear()
	for pos in PILLAR_POSITIONS:
		var pillar: StaticBody2D = StaticBody2D.new()
		pillar.name = "Pillar"
		pillar.position = pos

		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = BUILDING_TEX
		sprite.modulate = Color(0.45, 0.40, 0.35, 1.0)   ## 暗铁
		sprite.scale = Vector2(0.6, 0.7)
		pillar.add_child(sprite)

		var col: CollisionShape2D = CollisionShape2D.new()
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = Vector2(32, 32)
		col.shape = shape
		col.position = Vector2(0, 8)
		pillar.add_child(col)

		ysort.add_child(pillar)
		pillar_nodes.append(pillar)

func _spawn_bear() -> void:
	# 不可交互、不会移动的黑熊 sprite（中央偏上方）
	var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
	if ysort == null: return
	var bear: Node2D = Node2D.new()
	bear.name = "BlackBear"
	bear.position = Vector2(0, -150)

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = NPC_TEX
	sprite.modulate = Color(0.10, 0.10, 0.10, 1.0)   ## 漆黑
	sprite.scale = Vector2(1.8, 1.8)   ## 比 NPC 大很多
	bear.add_child(sprite)

	# 颈部白月牙（小 ColorRect 装饰）
	var moon: ColorRect = ColorRect.new()
	moon.color = Color(0.85, 0.82, 0.75, 0.7)
	moon.size = Vector2(20, 4)
	moon.position = Vector2(-10, -20)
	bear.add_child(moon)

	bear_sprite_node = sprite
	ysort.add_child(bear)

func _spawn_exit_door() -> void:
	var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
	if ysort == null: return
	var interactable_script: Script = load("res://src/scripts/interaction/interactable.gd")
	var door: Node2D = Node2D.new()
	door.name = "ExitDoor"
	door.position = Vector2(220, 160)

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
	inter.set("prompt_text", "[E] 离开地下室（门票不退）")
	var ishape: CollisionShape2D = CollisionShape2D.new()
	var icirc: CircleShape2D = CircleShape2D.new()
	icirc.radius = 28
	ishape.shape = icirc
	inter.add_child(ishape)
	door.add_child(inter)

	ysort.add_child(door)

# 给 Orchestrator 查询玩家是否在"安全区"（任意铁柱半径内）
func is_player_safe(player_pos: Vector2) -> bool:
	for p in pillar_nodes:
		if not is_instance_valid(p):
			continue
		if player_pos.distance_to(p.position) <= SAFE_RADIUS:
			return true
	return false

# 给 Orchestrator 在咆哮瞬间播放视觉效果（黑熊变色 + scale shake）
func play_roar_shake() -> void:
	if bear_sprite_node == null:
		return
	var t := create_tween()
	t.tween_property(bear_sprite_node, "modulate", Color(1, 0.3, 0.3, 1.0), 0.15)
	t.tween_property(bear_sprite_node, "modulate", Color(0.10, 0.10, 0.10, 1.0), 0.25)
