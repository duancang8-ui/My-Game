extends GutTest

const ControllerScript = preload("res://src/scripts/rotate_game/rotate_game_controller.gd")

var ctrl: RotateGameController

func before_each() -> void:
    ctrl = ControllerScript.new()
    ctrl.target_rotations = 10   ## 小目标方便测试
    ctrl.time_limit = 5.0
    add_child_autofree(ctrl)
    ctrl._ready()

func test_initial_state_is_ready() -> void:
    assert_eq(ctrl.state, RotateGameController.State.READY)
    assert_eq(ctrl.rotations, 0)
    assert_eq(ctrl.last_result, RotateGameController.Result.NONE)
    assert_almost_eq(ctrl.time_left, 5.0, 0.001)

func test_start_game_enters_playing() -> void:
    ctrl.start_game()
    assert_eq(ctrl.state, RotateGameController.State.PLAYING)

func test_add_rotation_when_not_playing_is_ignored() -> void:
    ctrl.add_rotation()
    assert_eq(ctrl.rotations, 0, "READY 状态下旋转应无效")

func test_add_rotation_increments_and_emits() -> void:
    ctrl.start_game()
    watch_signals(ctrl)
    ctrl.add_rotation()
    assert_eq(ctrl.rotations, 1)
    assert_signal_emitted(ctrl, "rotated")

func test_reaching_target_wins() -> void:
    ctrl.start_game()
    watch_signals(ctrl)
    for i in range(10):
        ctrl.add_rotation()
    assert_eq(ctrl.state, RotateGameController.State.ENDED)
    assert_eq(ctrl.last_result, RotateGameController.Result.WIN)
    assert_signal_emitted(ctrl, "game_ended")

func test_extra_rotation_after_win_ignored() -> void:
    ctrl.start_game()
    for i in range(10):
        ctrl.add_rotation()
    ctrl.add_rotation()  # 应被忽略
    assert_eq(ctrl.rotations, 10, "胜利后旋转无效")

func test_reset() -> void:
    ctrl.start_game()
    ctrl.add_rotation()
    ctrl.reset()
    assert_eq(ctrl.state, RotateGameController.State.READY)
    assert_eq(ctrl.rotations, 0)
    assert_eq(ctrl.last_result, RotateGameController.Result.NONE)
