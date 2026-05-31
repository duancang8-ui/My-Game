class_name Player
extends CharacterBody2D

# 玩家角色：齐夏（占位实现）
# 在 2.5D 等距场景中移动，使用 CharacterBody2D + Y-sort 处理遮挡

@export var speed: float = 200.0  # 移动速度（像素/秒）

var _input: PlayerInput = PlayerInput.new()

func calculate_velocity() -> Vector2:
    var direction: Vector2 = _input.get_move_direction()
    return direction * speed

func _physics_process(_delta: float) -> void:
    velocity = calculate_velocity()
    move_and_slide()
