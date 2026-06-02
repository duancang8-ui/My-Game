extends CanvasLayer

# P4.6 · b2/b3 演出基类
# 全屏 overlay + 居中台词 Label，3 段式播放：
#   FADE_IN (0.6s):  overlay alpha 0 → target_alpha
#   HOLD    (2.0s):  显示台词
#   FADE_OUT(0.4s):  alpha 回到 0（外部接管，本类只负责动画）
# 玩家可按 E（interact action） 跳过 HOLD，立即进入 FADE_OUT。
# 完成后 emit finished()，由 Orchestrator 在它之后继续后续动作（show_lose / show_win / spawn door 等）

signal finished()

@export var overlay_color: Color = Color(0.6, 0.05, 0.05, 0.85)
@export var title_color: Color = Color(1.0, 0.85, 0.45)
@export var subtitle_color: Color = Color(0.95, 0.85, 0.8)
@export var fade_in_duration: float = 0.6
@export var hold_duration: float = 2.0
@export var fade_out_duration: float = 0.4

var _overlay: ColorRect
var _title_label: Label
var _subtitle_label: Label
var _tween: Tween
var _state: int = 0   ## 0 idle / 1 fade_in / 2 hold / 3 fade_out
var _skippable: bool = true

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()

func _build() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(overlay_color.r, overlay_color.g, overlay_color.b, 0.0)
	_overlay.anchor_left = 0
	_overlay.anchor_top = 0
	_overlay.anchor_right = 1
	_overlay.anchor_bottom = 1
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	var vbox := VBoxContainer.new()
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -340
	vbox.offset_right = 340
	vbox.offset_top = -60
	vbox.offset_bottom = 60
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	_overlay.add_child(vbox)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 28)
	_title_label.add_theme_color_override("font_color", title_color)
	_title_label.modulate = Color(1, 1, 1, 0)   ## 先透明，跟随 overlay 一起 fade-in
	vbox.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_size_override("font_size", 16)
	_subtitle_label.add_theme_color_override("font_color", subtitle_color)
	_subtitle_label.modulate = Color(1, 1, 1, 0)
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_subtitle_label)

	var hint := Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 0.6))
	hint.text = "[按 E 跳过]"
	vbox.add_child(hint)

func play(title: String, subtitle: String, color_override: Color = Color()) -> void:
	if _state != 0:
		return
	_title_label.text = title
	_subtitle_label.text = subtitle
	if color_override.a > 0.0:
		_overlay.color = Color(color_override.r, color_override.g, color_override.b, 0.0)
	else:
		_overlay.color = Color(overlay_color.r, overlay_color.g, overlay_color.b, 0.0)
	visible = true
	_skippable = true
	_run_sequence()

func _run_sequence() -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_state = 1
	# fade in
	_tween.set_parallel(true)
	_tween.tween_property(_overlay, "color:a", overlay_color.a, fade_in_duration)
	_tween.tween_property(_title_label, "modulate:a", 1.0, fade_in_duration)
	_tween.tween_property(_subtitle_label, "modulate:a", 1.0, fade_in_duration)
	_tween.chain()
	# hold (with skip)
	_tween.tween_callback(func() -> void: _state = 2)
	_tween.tween_interval(hold_duration)
	# fade out
	_tween.tween_callback(func() -> void: _state = 3)
	_tween.set_parallel(true)
	_tween.tween_property(_overlay, "color:a", 0.0, fade_out_duration)
	_tween.tween_property(_title_label, "modulate:a", 0.0, fade_out_duration)
	_tween.tween_property(_subtitle_label, "modulate:a", 0.0, fade_out_duration)
	_tween.chain()
	_tween.tween_callback(_finish)

func _finish() -> void:
	visible = false
	_state = 0
	finished.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _skippable:
		return
	if _state != 1 and _state != 2:
		return
	if event.is_action_pressed("interact") \
			or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
				and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT):
		# 立刻跳到 fade-out
		_skippable = false
		if _tween != null and _tween.is_running():
			_tween.kill()
		_tween = create_tween()
		_state = 3
		_tween.set_parallel(true)
		_tween.tween_property(_overlay, "color:a", 0.0, fade_out_duration * 0.5)
		_tween.tween_property(_title_label, "modulate:a", 0.0, fade_out_duration * 0.5)
		_tween.tween_property(_subtitle_label, "modulate:a", 0.0, fade_out_duration * 0.5)
		_tween.chain()
		_tween.tween_callback(_finish)
		get_viewport().set_input_as_handled()
