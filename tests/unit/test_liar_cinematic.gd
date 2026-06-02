extends GutTest

# P4.6 · b2/b3 Cinematic 基类：状态机 + finished signal

const CinematicScript = preload("res://src/scripts/liar_game/liar_cinematic.gd")

func _make() -> Node:
	var c: Node = CinematicScript.new()
	add_child_autofree(c)
	# add_child_autofree 已触发 _ready → _build()，无需再显式调
	c.fade_in_duration = 0.01
	c.hold_duration = 0.02
	c.fade_out_duration = 0.01
	return c

func test_initial_invisible_and_idle() -> void:
	var c := _make()
	assert_false(c.visible, "默认不可见")
	assert_eq(c._state, 0, "默认 state == idle(0)")

func test_play_sets_visible_and_starts_state_machine() -> void:
	var c := _make()
	c.play("败北", "你输了")
	assert_true(c.visible, "play 后应可见")
	assert_eq(c._title_label.text, "败北")
	assert_eq(c._subtitle_label.text, "你输了")

func test_finished_signal_emits_after_full_sequence() -> void:
	var c := _make()
	watch_signals(c)
	c.play("X", "y")
	# 等总时长（fade_in 0.01 + hold 0.02 + fade_out 0.01 = ~0.04s）+ 安全余量
	await get_tree().create_timer(0.15).timeout
	assert_signal_emitted(c, "finished", "Cinematic 完整播放后应 emit finished")
	assert_false(c.visible, "finished 后应回到不可见")

func test_repeat_play_during_active_is_ignored() -> void:
	var c := _make()
	c.play("first", "1")
	c.play("second", "2")   ## 应被忽略
	assert_eq(c._title_label.text, "first", "正在播放时不能用新参数覆盖")
