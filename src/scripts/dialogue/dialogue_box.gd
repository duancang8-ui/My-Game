class_name DialogueBox
extends CanvasLayer

# 对话框 UI：显示 DialogueRunner 当前 line 的内容
# 占位风格：底部面板 + 黑色背景 + 白色文字 + 选项按钮列表
# 后续美术 polish 阶段再升级为"赛博中式都市怪诞"风（spec §6）

signal choice_picked(index: int)
signal continue_pressed()

@onready var _speaker_label: Label = $Panel/Margin/VBox/SpeakerTag/SpeakerLabel
@onready var _text_label: RichTextLabel = $Panel/Margin/VBox/TextLabel
@onready var _choices_box: VBoxContainer = $Panel/Margin/VBox/Choices
@onready var _continue_hint: Label = $Panel/Margin/VBox/ContinueHint

const BTN_NORMAL: Texture2D = preload("res://src/assets/ui/button_normal.png")
const BTN_HOVER: Texture2D = preload("res://src/assets/ui/button_hover.png")
const BTN_PRESSED: Texture2D = preload("res://src/assets/ui/button_pressed.png")

var _runner: DialogueRunner = null

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # 对话期间即使暂停游戏也能响应

func attach_runner(runner: DialogueRunner) -> void:
	_runner = runner
	if not runner.line_changed.is_connected(_on_line_changed):
		runner.line_changed.connect(_on_line_changed)
	if not runner.dialogue_ended.is_connected(_on_dialogue_ended):
		runner.dialogue_ended.connect(_on_dialogue_ended)

func _on_line_changed(line: DialogueLine) -> void:
	visible = true
	_speaker_label.text = line.speaker_name
	_text_label.text = line.text
	_refresh_choices(line)

func _on_dialogue_ended() -> void:
	visible = false
	_clear_choices()

func _refresh_choices(line: DialogueLine) -> void:
	_clear_choices()
	if line.choices.size() == 0:
		_continue_hint.visible = true
		_choices_box.visible = false
		return
	_continue_hint.visible = false
	_choices_box.visible = true
	for i in range(line.choices.size()):
		var choice: DialogueChoice = line.choices[i]
		var btn: Button = Button.new()
		btn.text = "%d. %s" % [i + 1, choice.label]
		btn.add_theme_font_size_override("font_size", 15)
		btn.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85, 1))
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 0.92, 1))
		btn.add_theme_color_override("font_pressed_color", Color(0.85, 0.5, 0.5, 1))
		btn.add_theme_stylebox_override("normal", _make_btn_style(BTN_NORMAL))
		btn.add_theme_stylebox_override("hover", _make_btn_style(BTN_HOVER))
		btn.add_theme_stylebox_override("pressed", _make_btn_style(BTN_PRESSED))
		btn.add_theme_stylebox_override("focus", _make_btn_style(BTN_HOVER))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var idx: int = i
		btn.pressed.connect(func() -> void: choice_picked.emit(idx))
		_choices_box.add_child(btn)

func _make_btn_style(tex: Texture2D) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = 10
	sb.texture_margin_top = 6
	sb.texture_margin_right = 10
	sb.texture_margin_bottom = 6
	sb.content_margin_left = 18
	sb.content_margin_top = 6
	sb.content_margin_right = 14
	sb.content_margin_bottom = 6
	return sb

func _clear_choices() -> void:
	for child in _choices_box.get_children():
		child.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if _runner == null or not _runner.is_active():
		return
	# 当前行无选项时，按 E 或鼠标左键继续
	if _runner.current_line.choices.size() == 0:
		var should_advance: bool = false
		if event.is_action_pressed("interact"):
			should_advance = true
		elif event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				should_advance = true
		if should_advance:
			continue_pressed.emit()
			get_viewport().set_input_as_handled()
