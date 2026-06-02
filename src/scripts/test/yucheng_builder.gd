extends Node

# 玉城占位场景生成器
# P4.7 重命名自 daocheng_builder（原作中 Cycle 1-后期主城是「玉城」而非「道城」；道城是更后期才到达）
# P5 时仅用于验证场景切换；P7+ 会被真正的玉城逻辑替换
# - 铺一张视觉差异明显的地图（中间一大块红色危险区，让玩家明确"我在不同场景"）
# - 玩家初始位置
# - 一扇返回门（Interactable SCENE_CHANGE → interview_room.tscn）
# - 一扇前往雨地的门

@export var ground_layer_path: NodePath = NodePath("../Ground")
@export var ysort_path: NodePath = NodePath("../YSortContainer")
@export var return_door_position: Vector2 = Vector2(300, 460)
@export var return_target: String = "res://src/scenes/world/interview_room.tscn"

const TILE_GROUND: Vector2i = Vector2i(0, 0)
const TILE_DANGER: Vector2i = Vector2i(1, 0)
const TILE_GRASS: Vector2i = Vector2i(2, 0)
const TILE_WATER: Vector2i = Vector2i(3, 0)
const SUBMIT_TEX: Texture2D = preload("res://src/assets/characters/submit_marker.png")

func _ready() -> void:
    _build_ground()
    _spawn_return_door()
    _spawn_rainy_field_door()

func _build_ground() -> void:
    var ground: TileMapLayer = get_node_or_null(ground_layer_path) as TileMapLayer
    if ground == null:
        push_error("YuchengBuilder: TileMapLayer not found")
        return
    # 24×16 较大的"街区"
    for x in range(-12, 13):
        for y in range(-8, 9):
            var atlas: Vector2i = TILE_GROUND
            # 中央 6×6 一片血红危险区
            if x >= -3 and x < 3 and y >= -3 and y < 3:
                atlas = TILE_DANGER
            elif (x + y) % 7 == 0:
                atlas = TILE_GRASS
            elif (x * y) % 11 == 0 and x != 0 and y != 0:
                atlas = TILE_WATER
            ground.set_cell(Vector2i(x, y), 0, atlas)

func _spawn_return_door() -> void:
    var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
    if ysort == null:
        return
    var interactable_script: Script = load("res://src/scripts/interaction/interactable.gd")
    var door: Node2D = Node2D.new()
    door.name = "ReturnDoor"
    door.position = return_door_position

    var sprite: Sprite2D = Sprite2D.new()
    sprite.texture = SUBMIT_TEX
    sprite.modulate = Color(0.6, 0.85, 1.0, 1.0)
    door.add_child(sprite)

    var label: Label = Label.new()
    label.text = "[返回面试房间]"
    label.position = Vector2(-50, 16)
    label.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0, 1.0))
    label.add_theme_font_size_override("font_size", 11)
    door.add_child(label)

    var inter: Area2D = Area2D.new()
    inter.name = "Interactable"
    inter.set_script(interactable_script)
    inter.collision_layer = 2
    inter.collision_mask = 0
    inter.set("interaction_type", 3)
    inter.set("scene_path", return_target)
    inter.set("prompt_text", "[E] 返回面试房间")
    var ishape: CollisionShape2D = CollisionShape2D.new()
    var icirc: CircleShape2D = CircleShape2D.new()
    icirc.radius = 32
    ishape.shape = icirc
    inter.add_child(ishape)
    door.add_child(inter)

    ysort.add_child(door)

func _spawn_rainy_field_door() -> void:
    var ysort: Node2D = get_node_or_null(ysort_path) as Node2D
    if ysort == null:
        return
    var interactable_script: Script = load("res://src/scripts/interaction/interactable.gd")
    var door: Node2D = Node2D.new()
    door.name = "RainyFieldDoor"
    door.position = Vector2(150, 200)   ## 玉城左上区域

    var sprite: Sprite2D = Sprite2D.new()
    sprite.texture = SUBMIT_TEX
    sprite.modulate = Color(1.0, 0.6, 0.4, 1.0)
    sprite.scale = Vector2(1.3, 1.3)
    door.add_child(sprite)

    var label: Label = Label.new()
    label.text = "[雨地 · 人狗游戏]"
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
    inter.set("prompt_text", "[E] 进入雨地（人狗游戏）")
    var ishape: CollisionShape2D = CollisionShape2D.new()
    var icirc: CircleShape2D = CircleShape2D.new()
    icirc.radius = 32
    ishape.shape = icirc
    inter.add_child(ishape)
    door.add_child(inter)

    ysort.add_child(door)
