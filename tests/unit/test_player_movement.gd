extends GutTest

const PlayerScript = preload("res://src/scripts/player/player.gd")

var player: Player

func before_each() -> void:
    player = PlayerScript.new()

func after_each() -> void:
    if is_instance_valid(player):
        player.free()
    for action in ["move_up", "move_down", "move_left", "move_right"]:
        Input.action_release(action)

func test_default_speed_is_200() -> void:
    assert_eq(player.speed, 200.0, "默认速度应为 200 px/s")

func test_calculate_velocity_no_input() -> void:
    var vel: Vector2 = player.calculate_velocity()
    assert_eq(vel, Vector2.ZERO, "无输入时速度为零")

func test_calculate_velocity_right() -> void:
    Input.action_press("move_right")
    var vel: Vector2 = player.calculate_velocity()
    assert_eq(vel, Vector2(200.0, 0.0), "按 D 时速度应为 (200, 0)")

func test_calculate_velocity_iso_diagonal_compensates() -> void:
    Input.action_press("move_up")
    Input.action_press("move_right")
    var vel: Vector2 = player.calculate_velocity()
    assert_almost_eq(vel.length(), 200.0, 0.01, "对角移动速度大小应等于 speed")
