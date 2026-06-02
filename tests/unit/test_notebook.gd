extends GutTest

# P4 final · a4：Notebook autoload 的写入和去重

func before_each() -> void:
	Notebook.entries.clear()

func test_record_unknown_dialogue_returns_false() -> void:
	var ok: bool = Notebook.record("not_in_table")
	assert_false(ok)
	assert_eq(Notebook.entries.size(), 0)

func test_record_known_v2_writes_entry() -> void:
	var ok: bool = Notebook.record("liar_li_shangwu_v2")
	assert_true(ok)
	assert_true(Notebook.entries.has("李尚武"))

func test_record_same_dialogue_twice_is_idempotent() -> void:
	Notebook.record("liar_li_shangwu_v2")
	var second: bool = Notebook.record("liar_li_shangwu_v2")
	assert_false(second, "重复记录同一 dialogue_id 应返回 false")
	assert_eq((Notebook.entries["李尚武"] as Array).size(), 1)

func test_v2_and_v3_combine_into_same_npc() -> void:
	# v2 写入"李尚武"，v3 写入"李尚武·v3"
	# 验证：不同 dialogue_id 都能写入，且 key 是各自的
	Notebook.record("liar_li_shangwu_v2")
	Notebook.record("liar_li_shangwu_v3")
	assert_true(Notebook.entries.has("李尚武"))
	assert_true(Notebook.entries.has("李尚武·v3"))

func test_observation_clue_writes_environment_entry() -> void:
	Notebook.record("observe_wall_grid")
	assert_true(Notebook.entries.has("环境"))
	assert_eq((Notebook.entries["环境"] as Array).size(), 1)

func test_insight_writes_special_entry() -> void:
	Notebook.record("liar_insight")
	assert_true(Notebook.entries.has("★关键"))
