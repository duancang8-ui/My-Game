extends GutTest

# P10：BearGameController 状态机 + 计时 + 体力 + 咆哮周期

const ControllerScript = preload("res://src/scripts/bear_game/bear_game_controller.gd")

func _make(time_limit: float = 90.0, max_stamina: int = 5, roar_interval: float = 12.0) -> BearGameController:
	var c: BearGameController = ControllerScript.new()
	c.time_limit = time_limit
	c.max_stamina = max_stamina
	c.roar_interval = roar_interval
	add_child_autofree(c)
	c._ready()
	return c

func test_initial_state_is_ready() -> void:
	var c := _make()
	assert_eq(c.state, BearGameController.State.READY)
	assert_eq(c.stamina, 5)
	assert_almost_eq(c.time_left, 90.0, 0.01)

func test_start_game_enters_playing() -> void:
	var c := _make()
	c.start_game()
	assert_eq(c.state, BearGameController.State.PLAYING)
	assert_eq(c.stamina, c.max_stamina)

func test_advance_time_decreases_time_left() -> void:
	var c := _make(10.0)
	c.start_game()
	c.advance_time(3.0)
	assert_almost_eq(c.time_left, 7.0, 0.01)

func test_time_to_zero_yields_win() -> void:
	var c := _make(5.0)
	c.start_game()
	watch_signals(c)
	c.advance_time(10.0)
	assert_eq(c.state, BearGameController.State.ENDED)
	assert_eq(c.last_result, BearGameController.Result.WIN)
	assert_signal_emitted(c, "game_ended")

func test_apply_roar_judgement_unsafe_decrements_stamina() -> void:
	var c := _make(60.0, 5)
	c.start_game()
	c.apply_roar_judgement(false)
	assert_eq(c.stamina, 4)

func test_apply_roar_judgement_safe_keeps_stamina() -> void:
	var c := _make(60.0, 5)
	c.start_game()
	c.apply_roar_judgement(true)
	assert_eq(c.stamina, 5)

func test_stamina_zero_yields_lose() -> void:
	var c := _make(60.0, 2)
	c.start_game()
	watch_signals(c)
	c.apply_roar_judgement(false)
	c.apply_roar_judgement(false)
	assert_eq(c.state, BearGameController.State.ENDED)
	assert_eq(c.last_result, BearGameController.Result.LOSE)
	assert_signal_emitted(c, "game_ended")
	assert_eq(c.stamina, 0)

func test_roar_warning_emits_in_warning_phase() -> void:
	var c := _make(60.0, 5, 10.0)
	c.warning_duration = 3.0
	c.start_game()
	watch_signals(c)
	# 推到 7 秒：still safe（time_to_roar = 3，刚进入预警）
	c.advance_time(7.1)
	assert_signal_emitted(c, "roar_warning")

func test_roar_judgement_needed_emits_at_phase_end() -> void:
	var c := _make(60.0, 5, 5.0)
	c.start_game()
	watch_signals(c)
	c.advance_time(5.1)
	assert_signal_emitted(c, "roar_judgement_needed")

func test_apply_roar_judgement_ignored_when_not_playing() -> void:
	var c := _make()
	# READY state — 没 start_game
	c.apply_roar_judgement(false)
	assert_eq(c.stamina, 5, "未开始时不应扣体力")

func test_reset_restores_full_state() -> void:
	var c := _make(60.0, 5)
	c.start_game()
	c.advance_time(20.0)
	c.apply_roar_judgement(false)
	c.reset()
	assert_eq(c.state, BearGameController.State.READY)
	assert_eq(c.stamina, 5)
	assert_almost_eq(c.time_left, 60.0, 0.01)
