extends Node

# P7：轻量任务系统（autoload）
# 单线任务链：完成当前 → 自动推进到下一个
# 触发方式：
#   - 玩家与某 NPC 完成对话 → DialogueController 钩子告诉 QuestState
#   - 玩家进入某场景 → SceneManager 钩子告诉 QuestState
# 占位：日后可扩展为"多线/可选/支线"

signal quest_changed(quest_id: String, title: String, hint: String)

# 内置任务定义
# trigger_kind: "dialogue" / "scene"
# trigger_value: 对应 dialogue_id 或 scene_file_path
# next: 完成后自动启动的下一个 quest id（"" 表示链结束）
const QUEST_TABLE: Dictionary = {
	"find_zheng_yingxiong": {
		"title": "找到郑英雄",
		"hint": "去玉城西区，那个看起来在闻空气的男人就是。",
		"trigger_kind": "dialogue",
		"trigger_value": "yu_zheng_yingxiong",
		"next": "enter_interview_room",
	},
	"enter_interview_room": {
		"title": "接受面试",
		"hint": "中央南侧那扇门通往面试房间。再活一次。",
		"trigger_kind": "scene",
		"trigger_value": "res://src/scenes/world/interview_room.tscn",
		"next": "back_to_yucheng",
	},
	"back_to_yucheng": {
		"title": "活着回到玉城",
		"hint": "面试房通关后会自然出现出口。走出去。",
		"trigger_kind": "scene",
		"trigger_value": "res://src/scenes/world/yucheng_main.tscn",
		"next": "",
	},
}

var current_quest_id: String = "find_zheng_yingxiong"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 默认从第一个任务开始（除非 GameState 已有进度，此处先简化为静态起点）
	call_deferred("_emit_current")

func _emit_current() -> void:
	if current_quest_id == "":
		quest_changed.emit("", "", "")
		return
	if not QUEST_TABLE.has(current_quest_id):
		quest_changed.emit(current_quest_id, "", "")
		return
	var q = QUEST_TABLE[current_quest_id]
	quest_changed.emit(current_quest_id, q["title"], q["hint"])

func current_title() -> String:
	if current_quest_id == "" or not QUEST_TABLE.has(current_quest_id):
		return ""
	return QUEST_TABLE[current_quest_id]["title"]

func current_hint() -> String:
	if current_quest_id == "" or not QUEST_TABLE.has(current_quest_id):
		return ""
	return QUEST_TABLE[current_quest_id]["hint"]

func on_dialogue_ended(dialogue_id: String) -> void:
	_check_trigger("dialogue", dialogue_id)

func on_scene_entered(scene_path: String) -> void:
	_check_trigger("scene", scene_path)

func _check_trigger(kind: String, value: String) -> void:
	if current_quest_id == "" or not QUEST_TABLE.has(current_quest_id):
		return
	var q = QUEST_TABLE[current_quest_id]
	if q["trigger_kind"] != kind:
		return
	if q["trigger_value"] != value:
		return
	# 完成当前任务，推进到下一个
	_advance_to(q.get("next", ""))

func _advance_to(next_id: String) -> void:
	var prev_title: String = current_title()
	current_quest_id = next_id
	if Toast != null and prev_title != "":
		Toast.show_success("任务完成：%s ✓" % prev_title)
	_emit_current()

# 测试 helper：手动设置当前任务
func set_current_quest_for_test(quest_id: String) -> void:
	current_quest_id = quest_id
	_emit_current()
