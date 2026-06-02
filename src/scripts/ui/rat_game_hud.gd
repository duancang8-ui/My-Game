extends CanvasLayer

# P8 「人鼠 · 仓库寻道」HUD
# - 顶部中央：剩余时间（< 60s 变红 + 闪烁）
# - 右下：道币
# - 中央下方：当前小提示（如「这里只有 X 个箱子，时间不够全翻」）

const PANEL_TEX: Texture2D = preload("res://src/assets/ui/dialogue_panel_9slice.png")

var _panel: PanelContainer
var _time_label: Label
var _hint_label: Label
var _dao_label: Label
var _blink_phase: float = 0.0

func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	set_process(true)

func _process(delta: float) -> void:
	_refresh_dao()
	_tick_blink(delta)

func _build() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.0
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.0
	_panel.offset_left = -200
	_panel.offset_top = 18
	_panel.offset_right = 200
	_panel.offset_bottom = 100
	var sb := StyleBoxTexture.new()
	sb.texture = PANEL_TEX
	sb.texture_margin_left = 16
	sb.texture_margin_top = 16
	sb.texture_margin_right = 16
	sb.texture_margin_bottom = 16
	sb.content_margin_left = 18
	sb.content_margin_top = 10
	sb.content_margin_right = 18
	sb.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_panel.add_child(vbox)

	_time_label = Label.new()
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_label.add_theme_font_size_override("font_size", 22)
	_time_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	_time_label.text = "⏳ 5:00"
	vbox.add_child(_time_label)

	_hint_label = Label.new()
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 11)
	_hint_label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.65))
	_hint_label.text = "5 分钟内找到「道」并带出仓库"
	vbox.add_child(_hint_label)

	# 道币（右下）
	_dao_label = Label.new()
	_dao_label.anchor_left = 1.0
	_dao_label.anchor_right = 1.0
	_dao_label.anchor_top = 1.0
	_dao_label.anchor_bottom = 1.0
	_dao_label.offset_left = -150
	_dao_label.offset_right = -20
	_dao_label.offset_top = -50
	_dao_label.offset_bottom = -16
	_dao_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dao_label.add_theme_font_size_override("font_size", 18)
	_dao_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	add_child(_dao_label)

func update_time(time_left: float) -> void:
	var total: int = int(ceil(time_left))
	var mm: int = total / 60
	var ss: int = total % 60
	_time_label.text = "⏳ %d:%02d" % [mm, ss]
	if time_left <= 60.0:
		_time_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	else:
		_time_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))

func set_hint(text: String) -> void:
	if _hint_label != null:
		_hint_label.text = text

func _refresh_dao() -> void:
	if _dao_label == null:
		return
	var gs = get_node_or_null("/root/GameState")
	if gs != null:
		_dao_label.text = "🪙 %d 道" % gs.dao_count

func _tick_blink(delta: float) -> void:
	if _time_label == null:
		return
	if _time_label.text.begins_with("⏳ 0:"):
		_blink_phase += delta * 4.0
		var a: float = 0.5 + 0.5 * abs(sin(_blink_phase))
		_time_label.modulate = Color(1, 1, 1, a)
	else:
		_time_label.modulate = Color.WHITE
