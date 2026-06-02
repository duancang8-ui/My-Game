extends CanvasLayer

# P10 「黑熊地下室」HUD
# - 顶部居中：时间 + 体力（5 颗心）
# - 中央：「咆哮预警」横幅（短暂闪烁 3 秒）
# - 右下：道币

const PANEL_TEX: Texture2D = preload("res://src/assets/ui/dialogue_panel_9slice.png")

var _panel: PanelContainer
var _time_label: Label
var _stamina_label: Label
var _warning_banner: Label
var _dao_label: Label
var _warning_hide_at: float = -1.0
var _warning_blink_phase: float = 0.0
var _time_acc: float = 0.0

func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	set_process(true)

func _process(delta: float) -> void:
	_time_acc += delta
	_refresh_dao()
	_tick_warning_banner(delta)

func _build() -> void:
	# 顶部面板
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.0
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.0
	_panel.offset_left = -180
	_panel.offset_top = 18
	_panel.offset_right = 180
	_panel.offset_bottom = 88
	var sb := StyleBoxTexture.new()
	sb.texture = PANEL_TEX
	sb.texture_margin_left = 16
	sb.texture_margin_top = 16
	sb.texture_margin_right = 16
	sb.texture_margin_bottom = 16
	sb.content_margin_left = 16
	sb.content_margin_top = 10
	sb.content_margin_right = 16
	sb.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	_panel.add_child(vbox)

	_time_label = Label.new()
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_label.add_theme_font_size_override("font_size", 20)
	_time_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	_time_label.text = "⏳ 1:30"
	vbox.add_child(_time_label)

	_stamina_label = Label.new()
	_stamina_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stamina_label.add_theme_font_size_override("font_size", 16)
	_stamina_label.add_theme_color_override("font_color", Color(0.95, 0.45, 0.45))
	_stamina_label.text = "❤️ ❤️ ❤️ ❤️ ❤️"
	vbox.add_child(_stamina_label)

	# 中央咆哮预警 banner（默认不可见）
	_warning_banner = Label.new()
	_warning_banner.anchor_left = 0.5
	_warning_banner.anchor_top = 0.5
	_warning_banner.anchor_right = 0.5
	_warning_banner.anchor_bottom = 0.5
	_warning_banner.offset_left = -300
	_warning_banner.offset_right = 300
	_warning_banner.offset_top = -50
	_warning_banner.offset_bottom = -16
	_warning_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning_banner.add_theme_font_size_override("font_size", 28)
	_warning_banner.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	_warning_banner.add_theme_constant_override("outline_size", 3)
	_warning_banner.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_warning_banner.text = "⚠️ 黑熊准备咆哮 · 找铁柱！"
	_warning_banner.visible = false
	add_child(_warning_banner)

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
	if time_left <= 15.0:
		_time_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	else:
		_time_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))

func update_stamina(stamina: int) -> void:
	if stamina <= 0:
		_stamina_label.text = "💀"
	else:
		var hearts: String = ""
		for i in range(stamina):
			hearts += "❤️ "
		_stamina_label.text = hearts.strip_edges()

func show_warning(duration: float = 3.0) -> void:
	_warning_banner.visible = true
	_warning_hide_at = _time_acc + duration

func _tick_warning_banner(delta: float) -> void:
	if not _warning_banner.visible:
		return
	if _time_acc >= _warning_hide_at:
		_warning_banner.visible = false
		_warning_banner.modulate = Color.WHITE
		return
	# 闪烁
	_warning_blink_phase += delta * 6.0
	var a: float = 0.5 + 0.5 * abs(sin(_warning_blink_phase))
	_warning_banner.modulate = Color(1, 1, 1, a)

func _refresh_dao() -> void:
	if _dao_label == null:
		return
	var gs = get_node_or_null("/root/GameState")
	if gs != null:
		_dao_label.text = "🪙 %d 道" % gs.dao_count
