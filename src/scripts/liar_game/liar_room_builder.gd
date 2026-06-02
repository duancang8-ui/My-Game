extends Node

# 程序化生成「说谎者」房间内容
# P4.7 重构：8 NPC 围桌 + 1 个人羊（可对话）+ 桌中央"提交"标记
# 原作语境：屋子封闭无门、四壁画方格、桌子中央有座钟

@export var ground_layer_path: NodePath = NodePath("../Ground")
@export var ysort_path: NodePath = NodePath("../YSortContainer")
@export var table_position: Vector2 = Vector2(400, 320)
@export var seat_radius: float = 150.0
@export var submit_marker_position: Vector2 = Vector2(400, 240)   ## 默认与桌中心同 x

const TABLE_TEX: Texture2D = preload("res://src/assets/characters/table_placeholder.png")
const NPC_TEX: Texture2D = preload("res://src/assets/characters/player_placeholder.png")
const SUBMIT_TEX: Texture2D = preload("res://src/assets/characters/submit_marker.png")
const MOOD_BUBBLE_SCRIPT: Script = preload("res://src/scripts/liar_game/npc_mood_bubble.gd")

const TILE_GROUND: Vector2i = Vector2i(0, 0)

func _ready() -> void:
	_build_ground()
	_spawn_table()
	_spawn_sheep_master()
	_spawn_seated_npcs()
	_spawn_submit_marker()
	# P4 final · 4.9：3 个环境观察点（墙边方格 / 座钟 / 桌上尸体）
	_spawn_observation_clues()

func _build_ground() -> void:
	var ground: TileMapLayer = get_node_or_null(ground_layer_path) as TileMapLayer
	if ground == null:
		push_error("LiarRoomBuilder: Ground TileMapLayer not found")
		return
	# 12 × 8 小房间（与原作设定 4×4×3 方格的视觉感呼应）
	for x in range(-6, 7):
		for y in range(-4, 5):
			ground.set_cell(Vector2i(x, y), 0, TILE_GROUND)

func _spawn_table() -> void:
	var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
	if ysort == null: return
	var table_body: StaticBody2D = StaticBody2D.new()
	table_body.name = "Table"
	table_body.position = table_position
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = TABLE_TEX
	table_body.add_child(sprite)
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(108, 70)
	col.shape = shape
	table_body.add_child(col)
	ysort.add_child(table_body)

func _spawn_sheep_master() -> void:
	# 人羊（戴山羊面具的男人），站在房间最上方观察
	# P4.7 让玩家可与之对话（dialogue_id = liar_sheep_master）
	var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
	if ysort == null: return
	var interactable_script: Script = load("res://src/scripts/interaction/interactable.gd")

	var sheep: CharacterBody2D = CharacterBody2D.new()
	sheep.name = "NPC_sheep_master"
	sheep.position = table_position + Vector2(0, -170)

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = NPC_TEX
	sprite.modulate = LiarNpcId.COLORS[LiarNpcId.SHEEP_MASTER]
	sprite.scale = Vector2(1.25, 1.25)   ## 略大，体现"主理人"地位
	sheep.add_child(sprite)

	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 10
	col.shape = shape
	col.position = Vector2(0, 16)
	sheep.add_child(col)

	var inter: Area2D = Area2D.new()
	inter.name = "Interactable"
	inter.set_script(interactable_script)
	inter.collision_layer = 2
	inter.collision_mask = 0
	inter.set("interaction_type", 1)   ## DIALOGUE
	inter.set("dialogue_id", LiarNpcId.dialogue_id_of(LiarNpcId.SHEEP_MASTER))
	inter.set("prompt_text", "[E] 看着山羊面具下的眼睛")
	var ishape: CollisionShape2D = CollisionShape2D.new()
	var icirc: CircleShape2D = CircleShape2D.new()
	icirc.radius = 36
	ishape.shape = icirc
	ishape.position = Vector2(0, 14)
	inter.add_child(ishape)
	sheep.add_child(inter)

	ysort.add_child(sheep)

func _spawn_seated_npcs() -> void:
	var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
	if ysort == null: return
	var interactable_script: Script = load("res://src/scripts/interaction/interactable.gd")
	var n: int = LiarNpcId.ALL.size()   ## 8 位参与者
	for i in range(n):
		var npc_id: String = LiarNpcId.ALL[i]
		var angle: float = (float(i) / float(n)) * TAU + PI / 2.0  # 从下方开始顺时针环坐
		var pos: Vector2 = table_position + Vector2(cos(angle), sin(angle) * 0.55) * seat_radius

		var body: CharacterBody2D = CharacterBody2D.new()
		body.name = "NPC_" + npc_id
		body.position = pos

		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = NPC_TEX
		sprite.modulate = LiarNpcId.COLORS[npc_id]
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
		inter.set("dialogue_id", LiarNpcId.dialogue_id_of(npc_id))
		inter.set("prompt_text", "[E] 与 %s 交谈" % LiarNpcId.name_of(npc_id))
		var ishape: CollisionShape2D = CollisionShape2D.new()
		var icirc: CircleShape2D = CircleShape2D.new()
		icirc.radius = 32
		ishape.shape = icirc
		ishape.position = Vector2(0, 14)
		inter.add_child(ishape)
		body.add_child(inter)

		# P4 final · b1：每个 NPC 顶上一个微表情气泡（5-15s 一次）
		var bubble := Node2D.new()
		bubble.name = "MoodBubble"
		bubble.set_script(MOOD_BUBBLE_SCRIPT)
		body.add_child(bubble)

		ysort.add_child(body)

func _spawn_submit_marker() -> void:
	var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
	if ysort == null: return
	var interactable_script: Script = load("res://src/scripts/interaction/interactable.gd")
	var marker: Node2D = Node2D.new()
	marker.name = "SubmitMarker"
	marker.position = submit_marker_position

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = SUBMIT_TEX
	marker.add_child(sprite)

	var inter: Area2D = Area2D.new()
	inter.name = "Interactable"
	inter.set_script(interactable_script)
	inter.collision_layer = 2
	inter.collision_mask = 0
	inter.set("interaction_type", 4)   ## VOTE
	inter.set("prompt_text", "[E] 在纸上写下名字")
	var ishape: CollisionShape2D = CollisionShape2D.new()
	var icirc: CircleShape2D = CircleShape2D.new()
	icirc.radius = 28
	ishape.shape = icirc
	inter.add_child(ishape)
	marker.add_child(inter)

	ysort.add_child(marker)

func _spawn_observation_clues() -> void:
	# P4 final · 4.9：3 个可观察的环境线索
	# 玩家走近某点按 E → 触发 observe_xxx 对话 → mark_observed
	# 攒齐 3 个 → 触发 liar_insight 灵光闪现
	var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
	if ysort == null: return
	_make_clue(ysort, "observe_wall_grid",
		table_position + Vector2(-280, -20),
		"[E] 数一数墙上的方格",
		Color(0.7, 0.7, 0.85, 0.9))
	_make_clue(ysort, "observe_clock",
		table_position + Vector2(0, -10),
		"[E] 看看桌上的座钟",
		Color(0.95, 0.85, 0.45, 0.9))
	_make_clue(ysort, "observe_corpse",
		table_position + Vector2(-60, -25),
		"[E] 看看那具尸体",
		Color(0.6, 0.25, 0.25, 0.9))

func _make_clue(ysort: Node2D, dialogue_id: String, pos: Vector2, prompt: String, color: Color) -> void:
	var interactable_script: Script = load("res://src/scripts/interaction/interactable.gd")
	var clue: Node2D = Node2D.new()
	clue.name = "Clue_" + dialogue_id
	clue.position = pos

	var dot: Sprite2D = Sprite2D.new()
	dot.texture = SUBMIT_TEX
	dot.modulate = color
	dot.scale = Vector2(0.6, 0.6)
	clue.add_child(dot)

	var inter: Area2D = Area2D.new()
	inter.name = "Interactable"
	inter.set_script(interactable_script)
	inter.collision_layer = 2
	inter.collision_mask = 0
	inter.set("interaction_type", 1)   ## DIALOGUE
	inter.set("dialogue_id", dialogue_id)
	inter.set("prompt_text", prompt)
	var ishape: CollisionShape2D = CollisionShape2D.new()
	var icirc: CircleShape2D = CircleShape2D.new()
	icirc.radius = 24
	ishape.shape = icirc
	inter.add_child(ishape)
	clue.add_child(inter)

	ysort.add_child(clue)
