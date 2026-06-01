extends Node

# 在 interview_room 场景里程序化生成围桌 5 NPC + 主理人 + 提交标记
# 避免在 .tscn 中重复粘 50 多个节点

@export var ground_layer_path: NodePath = NodePath("../Ground")
@export var ysort_path: NodePath = NodePath("../YSortContainer")
@export var table_position: Vector2 = Vector2(400, 320)
@export var seat_radius: float = 140.0
@export var submit_marker_position: Vector2 = Vector2(400, 240)

const TABLE_TEX: Texture2D = preload("res://src/assets/characters/table_placeholder.png")
const NPC_TEX: Texture2D = preload("res://src/assets/characters/player_placeholder.png")
const SUBMIT_TEX: Texture2D = preload("res://src/assets/characters/submit_marker.png")
const SHEEP_COLOR: Color = Color(0.85, 0.82, 0.75, 1.0)   # 人羊·张强（戴山羊面具）灰白色

const TILE_GROUND: Vector2i = Vector2i(0, 0)
const TILE_DANGER: Vector2i = Vector2i(1, 0)

func _ready() -> void:
    _build_ground()
    _spawn_table()
    _spawn_sheep_npc()
    _spawn_seated_npcs()
    _spawn_submit_marker()

func _build_ground() -> void:
    var ground: TileMapLayer = get_node_or_null(ground_layer_path) as TileMapLayer
    if ground == null:
        push_error("LiarRoomBuilder: Ground TileMapLayer not found")
        return
    # 12 × 8 小房间
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

func _spawn_sheep_npc() -> void:
    # 主理人·人羊（张强）站在桌子上方
    var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
    if ysort == null: return
    var sheep: CharacterBody2D = CharacterBody2D.new()
    sheep.name = "PersonSheep_ZhangQiang"
    sheep.position = table_position + Vector2(0, -160)   ## 在房间最上方
    var sprite: Sprite2D = Sprite2D.new()
    sprite.texture = NPC_TEX
    sprite.modulate = SHEEP_COLOR
    sprite.scale = Vector2(1.25, 1.25)   # 略大，体现"主理人"地位
    sheep.add_child(sprite)
    var col: CollisionShape2D = CollisionShape2D.new()
    var shape: CircleShape2D = CircleShape2D.new()
    shape.radius = 10
    col.shape = shape
    col.position = Vector2(0, 16)
    sheep.add_child(col)
    ysort.add_child(sheep)

func _spawn_seated_npcs() -> void:
    var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
    if ysort == null: return
    var interactable_script: Script = load("res://src/scripts/interaction/interactable.gd")
    var n: int = LiarNpcId.ALL.size()
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

        # 挂 Interactable
        var inter: Area2D = Area2D.new()
        inter.name = "Interactable"
        inter.set_script(interactable_script)
        inter.collision_layer = 2
        inter.collision_mask = 0
        inter.set("interaction_type", 1)  # Interactable.Type.DIALOGUE
        inter.set("dialogue_id", LiarNpcId.dialogue_id_of(npc_id))
        inter.set("prompt_text", "[E] 与 %s 交谈" % LiarNpcId.name_of(npc_id))
        var ishape: CollisionShape2D = CollisionShape2D.new()
        var icirc: CircleShape2D = CircleShape2D.new()
        icirc.radius = 32
        ishape.shape = icirc
        ishape.position = Vector2(0, 14)
        inter.add_child(ishape)
        body.add_child(inter)

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
    inter.set("interaction_type", 4)  # Interactable.Type.VOTE
    inter.set("prompt_text", "[E] 提交你的答案")
    var ishape: CollisionShape2D = CollisionShape2D.new()
    var icirc: CircleShape2D = CircleShape2D.new()
    icirc.radius = 28
    ishape.shape = icirc
    inter.add_child(ishape)
    marker.add_child(inter)

    ysort.add_child(marker)
