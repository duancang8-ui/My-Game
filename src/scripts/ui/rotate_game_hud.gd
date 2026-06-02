extends CanvasLayer

# 「雨后春笋」关卡专用 HUD
# - 顶部中央显示倒计时（大字，剩 5 秒变红色）
# - 进度条 + "X / 100" 文字
# - 玩家提示

const PANEL_TEX: Texture2D = preload("res://src/assets/ui/dialogue_panel_9slice.png")

@export var critical_time: float = 5.0     ## 剩余时间小于此值时变红

var _panel: PanelContainer
var _time_label: Label
var _progress_bar: ProgressBar
var _progress_label: Label
var _hint_label: Label
var _dao_label: Label   ## P4 final · c3 道币显示

func _ready() -> void:
    layer = 6
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build()
    visible = false
    set_process(true)

func _process(_delta: float) -> void:
    if _dao_label == null:
        return
    var gs = get_node_or_null("/root/GameState")
    if gs != null:
        _dao_label.text = "🪙 %d 道" % gs.dao_count

func _build() -> void:
    _panel = PanelContainer.new()
    _panel.anchor_left = 0.5
    _panel.anchor_top = 0
    _panel.anchor_right = 0.5
    _panel.anchor_bottom = 0
    _panel.offset_left = -260
    _panel.offset_top = 18
    _panel.offset_right = 260
    _panel.offset_bottom = 140
    var sb := StyleBoxTexture.new()
    sb.texture = PANEL_TEX
    sb.texture_margin_left = 16
    sb.texture_margin_top = 16
    sb.texture_margin_right = 16
    sb.texture_margin_bottom = 16
    sb.content_margin_left = 20
    sb.content_margin_top = 12
    sb.content_margin_right = 20
    sb.content_margin_bottom = 12
    _panel.add_theme_stylebox_override("panel", sb)
    add_child(_panel)

    var vbox := VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 6)
    _panel.add_child(vbox)

    _time_label = Label.new()
    _time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _time_label.add_theme_font_size_override("font_size", 26)
    _time_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
    _time_label.add_theme_constant_override("outline_size", 2)
    _time_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
    _time_label.text = "剩余 30.0 秒"
    vbox.add_child(_time_label)

    _progress_bar = ProgressBar.new()
    _progress_bar.min_value = 0
    _progress_bar.max_value = 100
    _progress_bar.value = 0
    _progress_bar.show_percentage = false
    _progress_bar.custom_minimum_size = Vector2(440, 16)
    vbox.add_child(_progress_bar)

    _progress_label = Label.new()
    _progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _progress_label.add_theme_font_size_override("font_size", 16)
    _progress_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85))
    _progress_label.text = "0 / 100 圈"
    vbox.add_child(_progress_label)

    _hint_label = Label.new()
    _hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _hint_label.add_theme_font_size_override("font_size", 12)
    _hint_label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.65))
    _hint_label.text = "[E] 旋转桌面"
    vbox.add_child(_hint_label)

    # P4 final · c3 道币显示（右下角）
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
    _time_label.text = "剩余 %.1f 秒" % time_left
    if time_left <= critical_time:
        _time_label.add_theme_color_override("font_color", Color(0.95, 0.4, 0.4))
    else:
        _time_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))

func update_progress(current: int, target: int) -> void:
    _progress_bar.max_value = target
    _progress_bar.value = current
    _progress_label.text = "%d / %d 圈" % [current, target]
