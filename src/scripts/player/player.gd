class_name Player
extends CharacterBody2D

# 玩家角色：齐夏（占位实现）
# 在 2.5D 等距场景中移动，使用 CharacterBody2D + Y-sort 处理遮挡

# 设计说明：
# 虽然 TileMap 用等距投影渲染（菱形格），但 Godot 的 CharacterBody2D
# position/velocity 仍然是普通 2D 屏幕像素坐标系。所以"按 WASD 屏幕直观"
# 不需要任何坐标变换 —— 直接 velocity = input * speed 即可。
# 这是 Disco Elysium / Persona 5 / Hades 等等距游戏的标准做法。
#
# 视觉效果：玩家在屏幕上沿 WASD 方向移动，菱形格在脚下"流过"。

@export var speed: float = 200.0  # 屏幕速度（像素/秒）

var _input: PlayerInput = PlayerInput.new()

func _ready() -> void:
    # P5.5：加入 player group 方便 SceneManager 在切场前找到玩家
    add_to_group("player")
    _restore_position_from_save()

func _restore_position_from_save() -> void:
    # 如果 GameState 里有当前场景的历史位置，覆盖 .tscn 默认位置
    # 这样玩家来回穿越场景时能回到上次离开的位置
    var gs := get_node_or_null("/root/GameState")
    if gs == null or not gs.has_method("has_scene_position"):
        return
    var scene_root := get_tree().current_scene
    if scene_root == null:
        return
    var scene_path: String = scene_root.scene_file_path
    if scene_path == "" or not gs.has_scene_position(scene_path):
        return
    position = gs.get_scene_position(scene_path)

func calculate_velocity() -> Vector2:
    return _input.get_move_direction() * speed

func _physics_process(_delta: float) -> void:
    velocity = calculate_velocity()
    move_and_slide()
