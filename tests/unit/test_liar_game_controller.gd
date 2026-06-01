extends GutTest

const ControllerScript = preload("res://src/scripts/liar_game/liar_game_controller.gd")

var ctrl: LiarGameController

func before_each() -> void:
    ctrl = ControllerScript.new()
    ctrl.liar_target_id = LiarNpcId.LIN_QIN  # 固定靶子
    add_child_autofree(ctrl)
    ctrl._ready()

func test_default_state_is_playing() -> void:
    assert_eq(ctrl.state, LiarGameController.State.PLAYING)
    assert_eq(ctrl.last_result, LiarGameController.Result.NONE)
    assert_eq(ctrl.last_voted, "")

func test_submit_correct_yields_win() -> void:
    watch_signals(ctrl)
    ctrl.submit_vote(LiarNpcId.LIN_QIN)
    assert_eq(ctrl.state, LiarGameController.State.SUBMITTED)
    assert_eq(ctrl.last_result, LiarGameController.Result.WIN)
    assert_eq(ctrl.last_voted, LiarNpcId.LIN_QIN)
    assert_signal_emitted(ctrl, "vote_submitted")

func test_submit_wrong_yields_lose() -> void:
    watch_signals(ctrl)
    ctrl.submit_vote(LiarNpcId.CHEN_JUNNAN)
    assert_eq(ctrl.last_result, LiarGameController.Result.LOSE)
    assert_eq(ctrl.last_voted, LiarNpcId.CHEN_JUNNAN)
    assert_signal_emitted(ctrl, "vote_submitted")

func test_repeat_submit_is_ignored() -> void:
    ctrl.submit_vote(LiarNpcId.CHEN_JUNNAN)
    ctrl.submit_vote(LiarNpcId.LIN_QIN)   ## 应被忽略，state 已是 SUBMITTED
    assert_eq(ctrl.last_voted, LiarNpcId.CHEN_JUNNAN, "重复 submit 不覆盖结果")
    assert_eq(ctrl.last_result, LiarGameController.Result.LOSE)

func test_reset_returns_to_playing() -> void:
    ctrl.submit_vote(LiarNpcId.CHEN_JUNNAN)
    ctrl.reset()
    assert_eq(ctrl.state, LiarGameController.State.PLAYING)
    assert_eq(ctrl.last_result, LiarGameController.Result.NONE)
    assert_eq(ctrl.last_voted, "")
