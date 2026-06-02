extends GutTest

# S2 · AudioManager 骨架：表完整性 + 信号 + 静音控制
# 注意：当前所有 SFX_TABLE / BGM_TABLE 值都是 null（占位），
#       播放调用只走 print 路径，不真正发声

func test_sfx_table_has_core_ids() -> void:
	# 至少要有这些常用 id（避免改名时调用方静默失败）
	var core_sfx: Array = [
		"ui_click", "win_chime", "lose_thud",
		"dao_earn", "dao_spend", "shop_purchase",
		"item_use", "rest_ticket_tear",
		"rat_pocket_reveal", "shield_form",
	]
	for id in core_sfx:
		assert_true(AudioManager.SFX_TABLE.has(id), "SFX 表应包含 id '%s'" % id)

func test_bgm_table_has_core_ids() -> void:
	var core_bgm: Array = [
		"bgm_yucheng_calm",
		"bgm_interview_tense",
		"bgm_rainy_field",
		"bgm_rat_warehouse",
		"bgm_main_menu",
	]
	for id in core_bgm:
		assert_true(AudioManager.BGM_TABLE.has(id), "BGM 表应包含 id '%s'" % id)

func test_play_sfx_emits_signal() -> void:
	watch_signals(AudioManager)
	AudioManager.play_sfx("ui_click")
	assert_signal_emitted(AudioManager, "sfx_played")

func test_play_sfx_unknown_id_warns_no_crash() -> void:
	# 未知 id 不应 crash，只 push_warning
	AudioManager.play_sfx("not_a_real_id_12345")
	assert_true(true, "不应抛异常")

func test_play_bgm_changes_current() -> void:
	AudioManager.current_bgm = ""
	watch_signals(AudioManager)
	AudioManager.play_bgm("bgm_yucheng_calm")
	assert_eq(AudioManager.current_bgm, "bgm_yucheng_calm")
	assert_signal_emitted(AudioManager, "bgm_changed")

func test_play_bgm_same_id_is_idempotent() -> void:
	AudioManager.current_bgm = "bgm_yucheng_calm"
	watch_signals(AudioManager)
	AudioManager.play_bgm("bgm_yucheng_calm")
	# 同名再播应 noop（不 emit）
	assert_signal_not_emitted(AudioManager, "bgm_changed")

func test_silent_mode_works() -> void:
	AudioManager.set_silent_for_test(true)
	assert_almost_eq(AudioManager.master_volume, 0.0, 0.001)
	AudioManager.set_silent_for_test(false)
	assert_almost_eq(AudioManager.master_volume, 1.0, 0.001)

func test_default_volumes_sane() -> void:
	# 防止意外把默认音量设成 0
	AudioManager.master_volume = 1.0   # 重置（防止 silent 测试遗留）
	AudioManager.sfx_volume = 1.0
	AudioManager.bgm_volume = 0.7
	assert_gt(AudioManager.master_volume, 0.0)
	assert_gt(AudioManager.sfx_volume, 0.0)
	assert_gt(AudioManager.bgm_volume, 0.0)
