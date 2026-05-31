class_name Player
extends CharacterBody2D

# 玩家角色：齐夏（占位实现）
# 在 2.5D 等距场景中移动，使用 CharacterBody2D + Y-sort 处理遮挡

@export var speed: float = 200.0  # 移动速度（像素/秒）

# 等距视角的坐标修正矩阵（玩家输入方向 → 世界移动方向）
# 在 2:1 等距下：屏幕"上"对应世界 (-1, -0.5)，屏幕"右"对应世界 (1, 0.5)
const ISO_TRANSFORM: Transform2D = Transform2D(
    Vector2(1.0, 0.5),    # x 轴（屏幕"右"）映射到世界
    Vector2(-1.0, 0.5),   # y 轴（屏幕"下"）映射到世界
    Vector2.ZERO
)

var _input: PlayerInput = PlayerInput.new()

func calculate_velocity() -> Vector2:
    var direction: Vector2 = _input.get_move_direction()
    if direction.length() == 0.0:
        return Vector2.ZERO
    # 把玩家意图（直角方向）→ 等距视觉对应的世界方向
    var iso_direction: Vector2 = (ISO_TRANSFORM * direction).normalized()
    return iso_direction * speed

func _physics_process(_delta: float) -> void:
    velocity = calculate_velocity()
    move_and_slide()
