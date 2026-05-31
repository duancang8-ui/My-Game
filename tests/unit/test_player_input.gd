extends GutTest

# 测试 PlayerInput 的基础接口与行为
# 用 Input.action_press() 模拟输入，无需真实键盘

const PlayerInputScript = preload("res://src/scripts/player/player_input.gd")

var player_input: PlayerInput

func before_each() -> void:
    player_input = PlayerInputScript.new()

func after_each() -> void:
    for action in ["move_up", "move_down", "move_left", "move_right"]:
        Input.action_release(action)

func test_no_input_returns_zero_vector() -> void:
    var dir: Vector2 = player_input.get_move_direction()
    assert_eq(dir, Vector2.ZERO, "无输入时应返回零向量")

func test_move_right_only() -> void:
    Input.action_press("move_right")
    var dir: Vector2 = player_input.get_move_direction()
    assert_eq(dir, Vector2.RIGHT, "按 D 应得到 RIGHT 向量")

func test_move_up_only() -> void:
    Input.action_press("move_up")
    var dir: Vector2 = player_input.get_move_direction()
    assert_eq(dir, Vector2.UP, "按 W 应得到 UP 向量")

func test_diagonal_normalized() -> void:
    Input.action_press("move_up")
    Input.action_press("move_right")
    var dir: Vector2 = player_input.get_move_direction()
    assert_almost_eq(dir.length(), 1.0, 0.001, "对角移动后向量应被归一化为长度 1")
