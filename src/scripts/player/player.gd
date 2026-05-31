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

func calculate_velocity() -> Vector2:
    return _input.get_move_direction() * speed

func _physics_process(_delta: float) -> void:
    velocity = calculate_velocity()
    move_and_slide()
