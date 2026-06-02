extends GutTest

# P4.7 重构后：投「人羊」=胜，投任意参与者=输

const ControllerScript = preload("res://src/scripts/liar_game/liar_game_controller.gd")

var ctrl: LiarGameController

func before_each() -> void:
	ctrl = ControllerScript.new()
	add_child_autofree(ctrl)
	ctrl._ready()

func test_default_state_is_playing() -> void:
	assert_eq(ctrl.state, LiarGameController.State.PLAYING)
	assert_eq(ctrl.last_result, LiarGameController.Result.NONE)
	assert_eq(ctrl.last_voted, "")
	assert_eq(ctrl.lose_reason, "")

func test_vote_sheep_master_yields_win() -> void:
	watch_signals(ctrl)
	ctrl.submit_vote(LiarNpcId.SHEEP_MASTER)
	assert_eq(ctrl.state, LiarGameController.State.SUBMITTED)
	assert_eq(ctrl.last_result, LiarGameController.Result.WIN)
	assert_eq(ctrl.last_voted, LiarNpcId.SHEEP_MASTER)
	assert_eq(ctrl.lose_reason, "")
	assert_signal_emitted(ctrl, "vote_submitted")

func test_vote_any_participant_yields_lose() -> void:
	for npc_id in LiarNpcId.ALL:
		var c: LiarGameController = ControllerScript.new()
		add_child_autofree(c)
		c._ready()
		c.submit_vote(npc_id)
		assert_eq(c.last_result, LiarGameController.Result.LOSE,
			"投 %s 应该是 LOSE" % LiarNpcId.name_of(npc_id))
		assert_eq(c.lose_reason, "wrong_vote")

func test_repeat_submit_is_ignored() -> void:
	ctrl.submit_vote(LiarNpcId.TIANTIAN)   ## 第一次投错
	ctrl.submit_vote(LiarNpcId.SHEEP_MASTER)   ## 应被忽略
	assert_eq(ctrl.last_voted, LiarNpcId.TIANTIAN, "重复 submit 不覆盖结果")
	assert_eq(ctrl.last_result, LiarGameController.Result.LOSE)

func test_force_lose_with_reason_records_reason() -> void:
	watch_signals(ctrl)
	ctrl.force_lose("time_up")
	assert_eq(ctrl.state, LiarGameController.State.SUBMITTED)
	assert_eq(ctrl.last_result, LiarGameController.Result.LOSE)
	assert_eq(ctrl.lose_reason, "time_up")
	assert_signal_emitted(ctrl, "vote_submitted")

func test_reset_returns_to_playing() -> void:
	ctrl.submit_vote(LiarNpcId.TIANTIAN)
	ctrl.reset()
	assert_eq(ctrl.state, LiarGameController.State.PLAYING)
	assert_eq(ctrl.last_result, LiarGameController.Result.NONE)
	assert_eq(ctrl.last_voted, "")
	assert_eq(ctrl.lose_reason, "")

func test_npc_id_has_exactly_8_participants() -> void:
	assert_eq(LiarNpcId.ALL.size(), 8, "原作面试房间共 9 位参与者（含齐夏），故 NPC 应为 8")

func test_all_vote_targets_includes_sheep_master() -> void:
	assert_true(LiarNpcId.ALL_VOTE_TARGETS.has(LiarNpcId.SHEEP_MASTER))
	assert_eq(LiarNpcId.ALL_VOTE_TARGETS.size(), LiarNpcId.ALL.size() + 1)

func test_is_sheep_master_helper() -> void:
	assert_true(LiarNpcId.is_sheep_master(LiarNpcId.SHEEP_MASTER))
	assert_false(LiarNpcId.is_sheep_master(LiarNpcId.LIN_QIN))
	assert_false(LiarNpcId.is_sheep_master(""))
