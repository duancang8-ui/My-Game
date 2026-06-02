extends GutTest

# P7：QuestState 任务链推进

func before_each() -> void:
	# 重置到第一个任务
	QuestState.set_current_quest_for_test("find_zheng_yingxiong")

func test_initial_quest_is_find_zheng() -> void:
	assert_eq(QuestState.current_quest_id, "find_zheng_yingxiong")
	assert_ne(QuestState.current_title(), "")
	assert_ne(QuestState.current_hint(), "")

func test_dialogue_trigger_advances_quest() -> void:
	# 完成与郑英雄对话 → 自动推进到下一个 quest
	QuestState.on_dialogue_ended("yu_zheng_yingxiong")
	assert_eq(QuestState.current_quest_id, "enter_interview_room")

func test_unrelated_dialogue_does_not_advance() -> void:
	QuestState.on_dialogue_ended("yu_passer_a")
	assert_eq(QuestState.current_quest_id, "find_zheng_yingxiong",
		"无关 dialogue 不应推进任务")

func test_scene_trigger_advances_quest() -> void:
	# 切到 enter_interview_room
	QuestState.set_current_quest_for_test("enter_interview_room")
	QuestState.on_scene_entered("res://src/scenes/world/interview_room.tscn")
	assert_eq(QuestState.current_quest_id, "back_to_yucheng")

func test_unrelated_scene_does_not_advance() -> void:
	QuestState.set_current_quest_for_test("enter_interview_room")
	QuestState.on_scene_entered("res://src/scenes/world/rainy_field.tscn")
	assert_eq(QuestState.current_quest_id, "enter_interview_room")

func test_quest_chain_ends_with_empty_next() -> void:
	# back_to_yucheng 的 next = "" → 完成后任务链结束
	QuestState.set_current_quest_for_test("back_to_yucheng")
	QuestState.on_scene_entered("res://src/scenes/world/yucheng_main.tscn")
	assert_eq(QuestState.current_quest_id, "")
	assert_eq(QuestState.current_title(), "", "无任务时 title 为空")
