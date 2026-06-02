extends GutTest

# P9：道具效果填实 — GameState 端的契约（消耗 / 库存 / sniffed_npcs / 防御符）

func before_each() -> void:
	GameState.reset()

# ===== 桃木防御符（消耗模式：has → remove → 剩余 -1）=====

func test_defense_charm_consume_decreases_count() -> void:
	GameState.add_item("item_defense_charm", 2)
	assert_true(GameState.has_item("item_defense_charm"))
	GameState.remove_item("item_defense_charm", 1)
	assert_eq(GameState.get_item_count("item_defense_charm"), 1)
	GameState.remove_item("item_defense_charm", 1)
	assert_false(GameState.has_item("item_defense_charm"))

# ===== 休息券（pending flag 配合）=====

func test_rest_ticket_with_pending_can_consume() -> void:
	GameState.add_item("item_rest_ticket", 1)
	GameState.mark_pending_day_advance()
	# 模拟 YuchengHud 消耗流程
	if GameState.has_item("item_rest_ticket") and GameState.pending_day_advance:
		GameState.remove_item("item_rest_ticket", 1)
		GameState.pending_day_advance = false
	assert_false(GameState.has_item("item_rest_ticket"))
	assert_false(GameState.pending_day_advance)

# ===== 线索袋（mark_observed 协议）=====

func test_clue_bag_marks_unobserved_one() -> void:
	GameState.add_item("item_clue_bag", 1)
	assert_eq(GameState.observed_clue_count(), 0)
	# 模拟 orchestrator 流程：消耗 + 标记
	GameState.remove_item("item_clue_bag", 1)
	GameState.mark_observed("observe_wall_grid")
	assert_eq(GameState.observed_clue_count(), 1)
	assert_false(GameState.has_item("item_clue_bag"))

# ===== 灵闻笔记 / sniffed_npcs =====

func test_initial_sniffed_is_empty() -> void:
	assert_false(GameState.has_sniffed("liar_sheep_master"))

func test_mark_sniffed_first_time_returns_true() -> void:
	var ok: bool = GameState.mark_sniffed("liar_sheep_master")
	assert_true(ok)
	assert_true(GameState.has_sniffed("liar_sheep_master"))

func test_mark_sniffed_duplicate_returns_false() -> void:
	GameState.mark_sniffed("liar_sheep_master")
	var ok: bool = GameState.mark_sniffed("liar_sheep_master")
	assert_false(ok)

func test_sniffed_independent_per_npc() -> void:
	GameState.mark_sniffed("liar_li_shangwu")
	assert_true(GameState.has_sniffed("liar_li_shangwu"))
	assert_false(GameState.has_sniffed("liar_sheep_master"))

func test_reset_clears_sniffed() -> void:
	GameState.mark_sniffed("liar_lin_qin")
	GameState.reset()
	assert_false(GameState.has_sniffed("liar_lin_qin"))

func test_sniffed_round_trip_in_dict() -> void:
	GameState.mark_sniffed("liar_lin_qin")
	GameState.mark_sniffed("liar_sheep_master")
	var dict: Dictionary = GameState.to_dict()
	GameState.reset()
	GameState.from_dict(dict)
	assert_true(GameState.has_sniffed("liar_lin_qin"))
	assert_true(GameState.has_sniffed("liar_sheep_master"))
	assert_false(GameState.has_sniffed("liar_qiao_jiajin"))
