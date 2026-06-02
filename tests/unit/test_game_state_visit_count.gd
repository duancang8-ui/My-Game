extends GutTest

# P4.6 · a2: GameState.npc_visit_count

func before_each() -> void:
	GameState.reset()

func test_initial_count_is_zero() -> void:
	assert_eq(GameState.get_visit_count("liar_lin_qin"), 0)

func test_increment_returns_new_count() -> void:
	var n1: int = GameState.increment_visit_count("liar_lin_qin")
	assert_eq(n1, 1)
	var n2: int = GameState.increment_visit_count("liar_lin_qin")
	assert_eq(n2, 2)

func test_get_after_increment() -> void:
	GameState.increment_visit_count("liar_lin_qin")
	GameState.increment_visit_count("liar_lin_qin")
	GameState.increment_visit_count("liar_lin_qin")
	assert_eq(GameState.get_visit_count("liar_lin_qin"), 3)

func test_independent_counts_per_dialogue() -> void:
	GameState.increment_visit_count("liar_lin_qin")
	GameState.increment_visit_count("liar_li_shangwu")
	GameState.increment_visit_count("liar_li_shangwu")
	assert_eq(GameState.get_visit_count("liar_lin_qin"), 1)
	assert_eq(GameState.get_visit_count("liar_li_shangwu"), 2)

func test_reset_clears_visit_counts() -> void:
	GameState.increment_visit_count("liar_lin_qin")
	GameState.reset()
	assert_eq(GameState.get_visit_count("liar_lin_qin"), 0)

func test_to_dict_includes_visit_counts() -> void:
	GameState.increment_visit_count("liar_lin_qin")
	GameState.increment_visit_count("liar_lin_qin")
	var d: Dictionary = GameState.to_dict()
	assert_true(d.has("npc_visit_count"))
	assert_eq(int(d["npc_visit_count"].get("liar_lin_qin", 0)), 2)

func test_from_dict_restores_visit_counts() -> void:
	GameState.from_dict({"npc_visit_count": {"liar_lin_qin": 2, "liar_li_shangwu": 1}})
	assert_eq(GameState.get_visit_count("liar_lin_qin"), 2)
	assert_eq(GameState.get_visit_count("liar_li_shangwu"), 1)

func test_from_dict_with_missing_visit_count_resets_to_empty() -> void:
	GameState.increment_visit_count("liar_lin_qin")
	GameState.from_dict({})   ## 没有 npc_visit_count 键
	assert_eq(GameState.get_visit_count("liar_lin_qin"), 0, "缺失键时应清空旧数据")
