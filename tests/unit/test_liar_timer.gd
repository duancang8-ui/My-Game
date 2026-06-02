extends GutTest

# P4.6 · a3 限时机制（在 P4.7 重构后仍保留）

const ControllerScript = preload("res://src/scripts/liar_game/liar_game_controller.gd")

func _make(time_limit: float = 10.0) -> LiarGameController:
	var c: LiarGameController = ControllerScript.new()
	c.time_limit = time_limit
	add_child_autofree(c)
	c._ready()
	return c

func test_initial_time_left_equals_time_limit() -> void:
	var c := _make(30.0)
	assert_almost_eq(c.time_left, 30.0, 0.01)

func test_advance_time_decreases_time_left() -> void:
	var c := _make(10.0)
	c.advance_time(3.0)
	assert_almost_eq(c.time_left, 7.0, 0.01)

func test_time_changed_signal_emits_on_advance() -> void:
	var c := _make(10.0)
	watch_signals(c)
	c.advance_time(1.5)
	assert_signal_emitted(c, "time_changed")

func test_advance_past_zero_emits_time_expired_and_loses() -> void:
	var c := _make(5.0)
	watch_signals(c)
	c.advance_time(10.0)
	assert_signal_emitted(c, "time_expired")
	assert_eq(c.state, LiarGameController.State.SUBMITTED)
	assert_eq(c.last_result, LiarGameController.Result.LOSE)
	assert_eq(c.lose_reason, "time_up")
	assert_almost_eq(c.time_left, 0.0, 0.01)

func test_submitted_state_freezes_timer() -> void:
	var c := _make(10.0)
	c.submit_vote(LiarNpcId.TIANTIAN)   ## 投错，进入 SUBMITTED
	var before: float = c.time_left
	c.advance_time(5.0)
	assert_almost_eq(c.time_left, before, 0.01, "SUBMITTED 后 advance_time 应被忽略")

func test_reset_restores_time_to_full() -> void:
	var c := _make(10.0)
	c.advance_time(7.0)
	c.reset()
	assert_almost_eq(c.time_left, 10.0, 0.01)
	assert_eq(c.state, LiarGameController.State.PLAYING)
	assert_eq(c.lose_reason, "")
