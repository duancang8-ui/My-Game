class_name PlayerInput
extends RefCounted

# 玩家输入抽象层
# 隔离 Godot 原生 Input，便于：
# 1. 单元测试（用 Input.action_press 模拟）
# 2. 移动端替换（虚拟摇杆只需替换这个类的实现）

func get_move_direction() -> Vector2:
    var dir: Vector2 = Vector2.ZERO
    if Input.is_action_pressed("move_right"):
        dir.x += 1.0
    if Input.is_action_pressed("move_left"):
        dir.x -= 1.0
    if Input.is_action_pressed("move_down"):
        dir.y += 1.0
    if Input.is_action_pressed("move_up"):
        dir.y -= 1.0
    if dir.length() > 0.0:
        dir = dir.normalized()
    return dir
