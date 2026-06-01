class_name Toast
extends CanvasLayer

# 屏幕右下角通知弹窗（"已存档" / "已读档" / "失败" 等）
# 用法：autoload 后调用 Toast.show_info("...") / show_success("...") / show_error("...")
# 多条同时触发会排队（FIFO），避免遮挡

const SHOW_DURATION: float = 2.0   ## 完整显示时间（秒）
const FADE_DURATION: float = 0.25  ## 淡入/淡出时间

enum Kind { INFO, SUCCESS, ERROR }

const COLOR_INFO: Color = Color(0.42, 0.62, 0.86, 1.0)        ## 蓝
const COLOR_SUCCESS: Color = Color(0.37, 0.80, 0.45, 1.0)     ## 绿
const COLOR_ERROR: Color = Color(0.72, 0.16, 0.16, 1.0)       ## 暗红（道城风）

var _panel: PanelContainer
var _label: Label
var _accent: ColorRect       ## 左侧色条
var _queue: Array[Dictionary] = []  ## [{ text, kind }]
var _busy: bool = false

func _ready() -> void:
    layer = 100  ## 置顶
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_ui()
    _panel.modulate.a = 0.0  ## 默认透明

func _build_ui() -> void:
    _panel = PanelContainer.new()
    _panel.anchor_left = 1.0
    _panel.anchor_top = 1.0
    _panel.anchor_right = 1.0
    _panel.anchor_bottom = 1.0
    _panel.offset_left = -360
    _panel.offset_top = -100
    _panel.offset_right = -24
    _panel.offset_bottom = -40
    _panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
    _panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.05, 0.05, 0.05, 0.95)
    sb.border_width_left = 4
    sb.border_color = COLOR_INFO
    sb.corner_radius_top_left = 4
    sb.corner_radius_top_right = 4
    sb.corner_radius_bottom_left = 4
    sb.corner_radius_bottom_right = 4
    sb.content_margin_left = 14
    sb.content_margin_right = 14
    sb.content_margin_top = 10
    sb.content_margin_bottom = 10
    _panel.add_theme_stylebox_override("panel", sb)
    add_child(_panel)

    _label = Label.new()
    _label.add_theme_font_size_override("font_size", 15)
    _label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
    _label.text = ""
    _label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _panel.add_child(_label)

func show_info(text: String) -> void:
    _enqueue(text, Kind.INFO)

func show_success(text: String) -> void:
    _enqueue(text, Kind.SUCCESS)

func show_error(text: String) -> void:
    _enqueue(text, Kind.ERROR)

func _enqueue(text: String, kind: int) -> void:
    _queue.append({"text": text, "kind": kind})
    if not _busy:
        _process_next()

func _process_next() -> void:
    if _queue.is_empty():
        _busy = false
        return
    _busy = true
    var item: Dictionary = _queue.pop_front()
    _show_one(item["text"], item["kind"])

func _show_one(text: String, kind: int) -> void:
    _label.text = text
    var color: Color = COLOR_INFO
    match kind:
        Kind.SUCCESS: color = COLOR_SUCCESS
        Kind.ERROR: color = COLOR_ERROR
        _: color = COLOR_INFO
    var sb: StyleBoxFlat = _panel.get_theme_stylebox("panel") as StyleBoxFlat
    if sb != null:
        sb.border_color = color

    var tween: Tween = create_tween()
    tween.tween_property(_panel, "modulate:a", 1.0, FADE_DURATION)
    tween.tween_interval(SHOW_DURATION)
    tween.tween_property(_panel, "modulate:a", 0.0, FADE_DURATION)
    tween.finished.connect(_process_next, CONNECT_ONE_SHOT)
