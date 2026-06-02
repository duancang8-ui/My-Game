extends Node

# M3：教学提示 autoload
# - 玩家首次进入某场景时，弹一段简短的"快捷键 / 玩法"提示
# - 同场景只显示 1 次（记录到 GameState.tutorial_seen，存档持久化）
# - 通过监听 SceneManager.scene_change_finished 自动触发
# - 也响应"首次进入面试房（main_scene 模式）"——因为 SceneManager 不会为初次加载发信号

# 每个场景的提示文本 —— 全部本项目原创
const HINTS: Dictionary = {
	"res://src/scenes/world/interview_room.tscn": "[首次进入] WASD 移动 · E 交互 · N 笔记本 · X 灵闻 · C 线索袋 · R 跳过今日（玉城里）",
	"res://src/scenes/world/yucheng_main.tscn":   "[首次进入玉城] 西区是商店 · 中央南门进面试房 · 东南找其他「考验」",
	"res://src/scenes/world/rat_warehouse.tscn":  "[首次进入仓库] 翻箱不一定能找到道 · 留心周围每一处细节",
	"res://src/scenes/world/bear_lair.tscn":      "[首次进入地下室] 听见「准备咆哮」立刻跑向最近的铁柱（3 根呈三角分布）",
	"res://src/scenes/world/rainy_field.tscn":    "[首次进入雨地] 按 E 反复转动桌子，30 秒内转 100 圈即过关",
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# SceneManager 切场完成后检查
	var sm = get_node_or_null("/root/SceneManager")
	if sm != null and sm.has_signal("scene_change_finished"):
		sm.scene_change_finished.connect(_on_scene_change_finished)
	# 初次启动（main_scene 直接加载）也检查一次
	call_deferred("_check_current_scene")

func _on_scene_change_finished(scene_path: String) -> void:
	_maybe_show_hint(scene_path)

func _check_current_scene() -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	_maybe_show_hint(scene_root.scene_file_path)

func _maybe_show_hint(scene_path: String) -> void:
	if scene_path == "" or not HINTS.has(scene_path):
		return
	var gs = get_node_or_null("/root/GameState")
	if gs == null or not gs.has_method("has_seen_tutorial"):
		return
	if gs.has_seen_tutorial(scene_path):
		return
	# 标记 + 延迟弹（让场景加载稳定后再说）
	gs.mark_tutorial_seen(scene_path)
	var hint: String = HINTS[scene_path]
	get_tree().create_timer(0.6).timeout.connect(func() -> void:
		if Toast != null:
			Toast.show_info(hint)
	)
