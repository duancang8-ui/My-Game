class_name Player
extends CharacterBody2D

# 玩家角色：齐夏（占位实现）
# 在 2.5D 等距场景中移动，使用 CharacterBody2D + Y-sort 处理遮挡

@export var speed: float = 200.0  # 屏幕速度（像素/秒）— 玩家在屏幕上的视觉速度

# 屏幕方向 → 世界方向的反等距变换矩阵
# 2:1 等距下：屏幕 (1, 0) ← 世界 (0.5, -0.5)；屏幕 (0, 1) ← 世界 (1, 1)
# 不归一化，保持屏幕速度幅度恒定（按 WASD 屏幕视觉方向与按键一致）
const ISO_INVERSE: Transform2D = Transform2D(
    Vector2(0.5, -0.5),   # 屏幕 +x（按 D）对应的世界向量
    Vector2(1.0, 1.0),    # 屏幕 +y（按 S）对应的世界向量
    Vector2.ZERO
)

var _input: PlayerInput = PlayerInput.new()

func calculate_velocity() -> Vector2:
    var screen_dir: Vector2 = _input.get_move_direction()
    if screen_dir.length() == 0.0:
        return Vector2.ZERO
    # 屏幕方向 → 世界速度；不再 normalize，让屏幕速度恒等于 speed
    return ISO_INVERSE * screen_dir * speed

func _physics_process(_delta: float) -> void:
    velocity = calculate_velocity()
    move_and_slide()
