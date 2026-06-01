extends Node

# 雨地场景生成器
# - 16×10 等距地图，水蓝色瓦片占主
# - 中央一张桌子（占位贴图）
# - 一只人狗（戴狗面具，棕色染色 + scale 1.2）

@export var ground_layer_path: NodePath = NodePath("../Ground")
@export var ysort_path: NodePath = NodePath("../YSortContainer")
@export var table_position: Vector2 = Vector2(400, 320)

const TILE_WATER: Vector2i = Vector2i(3, 0)
const TILE_DANGER: Vector2i = Vector2i(1, 0)
const TABLE_TEX: Texture2D = preload("res://src/assets/characters/table_placeholder.png")
const NPC_TEX: Texture2D = preload("res://src/assets/characters/player_placeholder.png")
const DOG_COLOR: Color = Color(0.6, 0.45, 0.3, 1.0)   ## 棕色（人狗）

func _ready() -> void:
    _build_ground()
    _spawn_table()
    _spawn_dog_master()

func _build_ground() -> void:
    var ground: TileMapLayer = get_node_or_null(ground_layer_path) as TileMapLayer
    if ground == null:
        push_error("RainyFieldBuilder: TileMapLayer not found")
        return
    # 16×10 雨地，大部分蓝色瓦片
    for x in range(-8, 9):
        for y in range(-5, 6):
            ground.set_cell(Vector2i(x, y), 0, TILE_WATER)
    # 桌子周围一圈"湿润但非水"区域用 DANGER 颜色（暗红，警示)
    for dx in range(-2, 3):
        for dy in range(-2, 3):
            ground.set_cell(Vector2i(dx, dy), 0, TILE_DANGER)

func _spawn_table() -> void:
    var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
    if ysort == null:
        return
    var body: StaticBody2D = StaticBody2D.new()
    body.name = "RotatingTable"
    body.position = table_position

    var sprite: Sprite2D = Sprite2D.new()
    sprite.texture = TABLE_TEX
    sprite.modulate = Color(0.85, 0.85, 0.95, 1.0)   ## 略发亮（湿润感）
    body.add_child(sprite)

    var col: CollisionShape2D = CollisionShape2D.new()
    var shape: RectangleShape2D = RectangleShape2D.new()
    shape.size = Vector2(108, 70)
    col.shape = shape
    body.add_child(col)

    ysort.add_child(body)

func _spawn_dog_master() -> void:
    var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
    if ysort == null:
        return
    var dog: CharacterBody2D = CharacterBody2D.new()
    dog.name = "PersonDog_Master"
    dog.position = table_position + Vector2(0, -160)   ## 桌子上方

    var sprite: Sprite2D = Sprite2D.new()
    sprite.texture = NPC_TEX
    sprite.modulate = DOG_COLOR
    sprite.scale = Vector2(1.25, 1.25)
    dog.add_child(sprite)

    var col: CollisionShape2D = CollisionShape2D.new()
    var shape: CircleShape2D = CircleShape2D.new()
    shape.radius = 10
    col.shape = shape
    col.position = Vector2(0, 16)
    dog.add_child(col)

    ysort.add_child(dog)
