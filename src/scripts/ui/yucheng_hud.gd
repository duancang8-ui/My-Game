extends CanvasLayer

# P7：玉城常驻 HUD
# - 右上角面板：Cycle / Day / 道币 / 当前任务
# - 监听 QuestState.quest_changed 更新任务行
# - _process 轮询 GameState 更新 day/cycle/dao

const PANEL_TEX: Texture2D = preload("res://src/assets/ui/dialogue_panel_9slice.png")

var _panel: PanelContainer
var _cycle_day_label: Label
var _dao_label: Label
var _quest_label: Label

func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	# 接入 QuestState 信号
	var qs = get_node_or_null("/root/QuestState")
	if qs != null and qs.has_signal("quest_changed"):
		qs.quest_changed.connect(_on_quest_changed)
		# 立刻刷一次
		_on_quest_changed(qs.current_quest_id, qs.current_title(), qs.current_hint())
	set_process(true)

func _process(_delta: float) -> void:
	_refresh_state()

func _build() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 1.0
	_panel.anchor_top = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 0.0
	_panel.offset_left = -260
	_panel.offset_top = 18
	_panel.offset_right = -16
	_panel.offset_bottom = 160
	var sb := StyleBoxTexture.new()
	sb.texture = PANEL_TEX
	sb.texture_margin_left = 16
	sb.texture_margin_top = 16
	sb.texture_margin_right = 16
	sb.texture_margin_bottom = 16
	sb.content_margin_left = 16
	sb.content_margin_top = 8
	sb.content_margin_right = 16
	sb.content_margin_bottom = 8
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_panel.add_child(vbox)

	_cycle_day_label = Label.new()
	_cycle_day_label.add_theme_font_size_override("font_size", 14)
	_cycle_day_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	vbox.add_child(_cycle_day_label)

	_dao_label = Label.new()
	_dao_label.add_theme_font_size_override("font_size", 14)
	_dao_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	vbox.add_child(_dao_label)

	var divider := HSeparator.new()
	vbox.add_child(divider)

	_quest_label = Label.new()
	_quest_label.add_theme_font_size_override("font_size", 12)
	_quest_label.add_theme_color_override("font_color", Color(0.85, 0.92, 0.95))
	_quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_quest_label.custom_minimum_size = Vector2(224, 0)
	vbox.add_child(_quest_label)

func _refresh_state() -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs == null:
		return
	_cycle_day_label.text = "Cycle %d · Day %d" % [gs.current_cycle, gs.current_day]
	_dao_label.text = "🪙 %d 道" % gs.dao_count

func _on_quest_changed(quest_id: String, title: String, hint: String) -> void:
	if quest_id == "":
		_quest_label.text = "（无任务）"
		return
	_quest_label.text = "📌 %s\n%s" % [title, hint]
