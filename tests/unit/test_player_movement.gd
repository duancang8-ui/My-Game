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
    assert_eq(player.speed, 200.0, "默认屏幕速度应为 200 px/s")

func test_calculate_velocity_no_input() -> void:
    var vel: Vector2 = player.calculate_velocity()
    assert_eq(vel, Vector2.ZERO, "无输入时速度为零")

# 等距正变换：世界 (wx, wy) → 屏幕 (wx - wy, (wx + wy) / 2)
func _world_to_screen(world_v: Vector2) -> Vector2:
    return Vector2(world_v.x - world_v.y, (world_v.x + world_v.y) / 2.0)

func test_press_right_yields_horizontal_screen_motion() -> void:
    # 按 D：期望屏幕水平向右走，屏幕速度 = (200, 0)
    Input.action_press("move_right")
    var vel: Vector2 = player.calculate_velocity()
    var screen_v: Vector2 = _world_to_screen(vel)
    assert_almost_eq(screen_v.x, 200.0, 0.01, "按 D 屏幕水平速度应为 +200")
    assert_almost_eq(screen_v.y, 0.0, 0.01, "按 D 屏幕垂直速度应为 0")

func test_press_up_yields_vertical_screen_motion() -> void:
    # 按 W：期望屏幕垂直向上走，屏幕速度 = (0, -200)
    Input.action_press("move_up")
    var vel: Vector2 = player.calculate_velocity()
    var screen_v: Vector2 = _world_to_screen(vel)
    assert_almost_eq(screen_v.x, 0.0, 0.01, "按 W 屏幕水平速度应为 0")
    assert_almost_eq(screen_v.y, -200.0, 0.01, "按 W 屏幕垂直速度应为 -200")

func test_diagonal_screen_speed_consistent() -> void:
    # 按 D+S：期望屏幕 ↘ 方向，屏幕速度幅度仍为 200（不会比单方向更快）
    Input.action_press("move_right")
    Input.action_press("move_down")
    var vel: Vector2 = player.calculate_velocity()
    var screen_v: Vector2 = _world_to_screen(vel)
    assert_almost_eq(screen_v.length(), 200.0, 0.01, "对角移动屏幕速度幅度应等于 speed")
