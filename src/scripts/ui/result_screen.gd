extends CanvasLayer

# 关卡结算屏幕：全屏半透明 overlay + 标题 + 副标题 + 操作按钮
# 调用 show_win(title, subtitle) / show_lose(title, subtitle) 显示
# 玩家点按钮 → 触发 retry_pressed / load_save_pressed / continue_pressed 信号

signal retry_pressed()
signal load_save_pressed()
signal continue_pressed()

const PANEL_TEX: Texture2D = preload("res://src/assets/ui/dialogue_panel_9slice.png")
const BTN_NORMAL: Texture2D = preload("res://src/assets/ui/button_normal.png")
const BTN_HOVER: Texture2D = preload("res://src/assets/ui/button_hover.png")
const BTN_PRESSED: Texture2D = preload("res://src/assets/ui/button_pressed.png")

const TINT_LOSE: Color = Color(0.6, 0.05, 0.05, 0.55)    ## 暗红 overlay
const TINT_WIN: Color = Color(0.85, 0.7, 0.2, 0.45)      ## 暗金 overlay
const TITLE_COLOR_LOSE: Color = Color(0.95, 0.4, 0.4, 1)
const TITLE_COLOR_WIN: Color = Color(0.95, 0.85, 0.45, 1)

var _overlay: ColorRect
var _panel: PanelContainer
var _title_label: Label
var _subtitle_label: Label
var _button_box: VBoxContainer

func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false

func _build() -> void:
	_overlay = ColorRect.new()
	_overlay.anchor_left = 0
	_overlay.anchor_top = 0
	_overlay.anchor_right = 1
	_overlay.anchor_bottom = 1
	_overlay.color = TINT_LOSE
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -260
	_panel.offset_top = -180
	_panel.offset_right = 260
	_panel.offset_bottom = 180
	var sb := StyleBoxTexture.new()
	sb.texture = PANEL_TEX
	sb.texture_margin_left = 16
	sb.texture_margin_top = 16
	sb.texture_margin_right = 16
	sb.texture_margin_bottom = 16
	sb.content_margin_left = 36
	sb.content_margin_top = 28
	sb.content_margin_right = 36
	sb.content_margin_bottom = 28
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	_panel.add_child(vbox)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 32)
	_title_label.add_theme_constant_override("outline_size", 3)
	_title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	vbox.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle_label.add_theme_font_size_override("font_size", 15)
	_subtitle_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.8, 1))
	_subtitle_label.custom_minimum_size = Vector2(440, 0)
	vbox.add_child(_subtitle_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 14)
	vbox.add_child(spacer)

	_button_box = VBoxContainer.new()
	_button_box.add_theme_constant_override("separation", 8)
	vbox.add_child(_button_box)

func show_lose(title: String, subtitle: String) -> void:
	_title_label.text = title
	_title_label.add_theme_color_override("font_color", TITLE_COLOR_LOSE)
	_subtitle_label.text = subtitle
	_overlay.color = TINT_LOSE
	_set_buttons([
		{"label": "重新开始本关", "signal": "retry_pressed"},
		{"label": "读取存档 (F10)", "signal": "load_save_pressed"},
	])
	visible = true

func show_win(title: String, subtitle: String) -> void:
	_title_label.text = title
	_title_label.add_theme_color_override("font_color", TITLE_COLOR_WIN)
	_subtitle_label.text = subtitle
	_overlay.color = TINT_WIN
	_set_buttons([
		{"label": "继续探索", "signal": "continue_pressed"},
	])
	visible = true

func hide_screen() -> void:
	visible = false

func _set_buttons(items: Array) -> void:
	for child in _button_box.get_children():
		child.queue_free()
	for it in items:
		var btn := _make_btn(it["label"])
		var sig: String = it["signal"]
		btn.pressed.connect(_emit_named_signal.bind(sig))
		_button_box.add_child(btn)

func _emit_named_signal(sig_name: String) -> void:
	visible = false
	match sig_name:
		"retry_pressed": retry_pressed.emit()
		"load_save_pressed": load_save_pressed.emit()
		"continue_pressed": continue_pressed.emit()
		_: push_warning("ResultScreen: unknown signal name " + sig_name)

func _make_btn(label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 0.92))
	btn.add_theme_stylebox_override("normal", _btn_style(BTN_NORMAL))
	btn.add_theme_stylebox_override("hover", _btn_style(BTN_HOVER))
	btn.add_theme_stylebox_override("pressed", _btn_style(BTN_PRESSED))
	btn.add_theme_stylebox_override("focus", _btn_style(BTN_HOVER))
	return btn

func _btn_style(tex: Texture2D) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = 10
	sb.texture_margin_top = 6
	sb.texture_margin_right = 10
	sb.texture_margin_bottom = 6
	sb.content_margin_left = 18
	sb.content_margin_top = 10
	sb.content_margin_right = 14
	sb.content_margin_bottom = 10
	return sb
