extends GutTest

# P8：RatGameController 状态机 + 计时 + 胜负

const ControllerScript = preload("res://src/scripts/rat_game/rat_game_controller.gd")

func _make(time_limit: float = 10.0) -> RatGameController:
	var c: RatGameController = ControllerScript.new()
	c.time_limit = time_limit
	add_child_autofree(c)
	c._ready()
	return c

func test_initial_state_is_ready() -> void:
	var c := _make(10.0)
	assert_eq(c.state, RatGameController.State.READY)
	assert_eq(c.last_result, RatGameController.Result.NONE)
	assert_almost_eq(c.time_left, 10.0, 0.01)

func test_start_game_enters_playing() -> void:
	var c := _make(10.0)
	c.start_game()
	assert_eq(c.state, RatGameController.State.PLAYING)
	assert_almost_eq(c.time_left, 10.0, 0.01)

func test_advance_time_decreases_when_playing() -> void:
	var c := _make(10.0)
	c.start_game()
	c.advance_time(3.0)
	assert_almost_eq(c.time_left, 7.0, 0.01)

func test_advance_time_ignored_when_not_playing() -> void:
	var c := _make(10.0)
	# READY 状态下 advance_time 应被忽略
	c.advance_time(3.0)
	assert_almost_eq(c.time_left, 10.0, 0.01)

func test_timeout_emits_signals_and_loses() -> void:
	var c := _make(5.0)
	c.start_game()
	watch_signals(c)
	c.advance_time(10.0)
	assert_signal_emitted(c, "time_expired")
	assert_signal_emitted(c, "game_ended")
	assert_eq(c.state, RatGameController.State.ENDED)
	assert_eq(c.last_result, RatGameController.Result.LOSE)

func test_reveal_win_yields_win() -> void:
	var c := _make(10.0)
	c.start_game()
	watch_signals(c)
	c.reveal_win()
	assert_eq(c.state, RatGameController.State.ENDED)
	assert_eq(c.last_result, RatGameController.Result.WIN)
	assert_signal_emitted(c, "game_ended")

func test_reveal_win_ignored_when_not_playing() -> void:
	var c := _make(10.0)
	# 没 start_game，reveal_win 应被忽略
	c.reveal_win()
	assert_eq(c.state, RatGameController.State.READY)
	assert_eq(c.last_result, RatGameController.Result.NONE)

func test_give_up_yields_lose() -> void:
	var c := _make(10.0)
	c.start_game()
	c.give_up()
	assert_eq(c.last_result, RatGameController.Result.LOSE)

func test_reset_returns_to_ready() -> void:
	var c := _make(10.0)
	c.start_game()
	c.advance_time(5.0)
	c.reveal_win()
	c.reset()
	assert_eq(c.state, RatGameController.State.READY)
	assert_eq(c.last_result, RatGameController.Result.NONE)
	assert_almost_eq(c.time_left, 10.0, 0.01)

func test_double_finish_is_ignored() -> void:
	var c := _make(10.0)
	c.start_game()
	c.reveal_win()
	c.give_up()   ## 已经 ENDED，再 give_up 应被忽略
	assert_eq(c.last_result, RatGameController.Result.WIN, "WIN 不应被后续 give_up 覆盖")
