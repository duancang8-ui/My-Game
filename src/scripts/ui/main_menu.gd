extends Control

# M2：主菜单 — 项目入口
# 4 个按钮：新游戏 / 继续 / 设置（占位） / 退出
# 「新游戏」会 reset GameState 再切到面试房；「继续」走 SaveSystem.load_from_slot(0)

const BTN_NORMAL: Texture2D = preload("res://src/assets/ui/button_normal.png")
const BTN_HOVER: Texture2D = preload("res://src/assets/ui/button_hover.png")
const BTN_PRESSED: Texture2D = preload("res://src/assets/ui/button_pressed.png")
const PANEL_TEX: Texture2D = preload("res://src/assets/ui/dialogue_panel_9slice.png")

const START_SCENE: String = "res://src/scenes/world/interview_room.tscn"

func _ready() -> void:
	_build()

func _build() -> void:
	# 全屏黑底
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.05, 0.05, 1.0)
	bg.anchor_left = 0
	bg.anchor_top = 0
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	add_child(bg)

	# 中央 VBox
	var center := CenterContainer.new()
	center.anchor_left = 0
	center.anchor_top = 0
	center.anchor_right = 1
	center.anchor_bottom = 1
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	# 标题
	var title := Label.new()
	title.text = "十 日 终 焉"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	title.add_theme_constant_override("outline_size", 3)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "（同人 · 改编自杀虫队队员同名小说 · 非商业）"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color(0.65, 0.6, 0.55))
	vbox.add_child(subtitle)

	# 占位 — 留 30px 间隔
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer)

	# 4 个按钮
	vbox.add_child(_make_btn("▸  新游戏", _on_new_game))
	vbox.add_child(_make_btn("▸  继续上次", _on_continue))
	vbox.add_child(_make_btn("▸  设置（占位）", _on_settings))
	vbox.add_child(_make_btn("▸  退出", _on_quit))

	# 底部版本号
	var ver := Label.new()
	ver.anchor_left = 1.0
	ver.anchor_right = 1.0
	ver.anchor_top = 1.0
	ver.anchor_bottom = 1.0
	ver.offset_left = -200
	ver.offset_right = -16
	ver.offset_top = -36
	ver.offset_bottom = -16
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ver.add_theme_font_size_override("font_size", 11)
	ver.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	ver.text = "v0.12-main-menu  ·  Godot 4.6"
	add_child(ver)

func _make_btn(label: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(280, 48)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 0.92))
	btn.add_theme_stylebox_override("normal", _btn_style(BTN_NORMAL))
	btn.add_theme_stylebox_override("hover", _btn_style(BTN_HOVER))
	btn.add_theme_stylebox_override("pressed", _btn_style(BTN_PRESSED))
	btn.add_theme_stylebox_override("focus", _btn_style(BTN_HOVER))
	btn.pressed.connect(callback)
	return btn

func _btn_style(tex: Texture2D) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = 10
	sb.texture_margin_top = 6
	sb.texture_margin_right = 10
	sb.texture_margin_bottom = 6
	sb.content_margin_left = 24
	sb.content_margin_top = 10
	sb.content_margin_right = 24
	sb.content_margin_bottom = 10
	return sb

func _on_new_game() -> void:
	if AudioManager != null:
		AudioManager.play_sfx("ui_click")
	if GameState != null and GameState.has_method("reset"):
		GameState.reset()
	if Toast != null:
		Toast.show_info("新游戏开始")
	_goto(START_SCENE)

func _on_continue() -> void:
	if AudioManager != null:
		AudioManager.play_sfx("ui_click")
	var ss = get_node_or_null("/root/SaveSystem")
	if ss == null or not ss.slot_exists(0):
		if Toast != null:
			Toast.show_error("还没有存档（先开新游戏并 F9 存档）")
		return
	if not ss.load_from_slot(0):
		if Toast != null:
			Toast.show_error("存档读取失败")
		return
	var target: String = GameState.current_scene_path
	if target == "":
		target = START_SCENE
	if Toast != null:
		Toast.show_success("读档成功 ✓")
	_goto(target)

func _on_settings() -> void:
	if AudioManager != null:
		AudioManager.play_sfx("ui_click")
	if Toast != null:
		Toast.show_info("设置面板还没做 · 留给下个版本")

func _on_quit() -> void:
	if AudioManager != null:
		AudioManager.play_sfx("ui_click")
	get_tree().quit()

func _goto(scene_path: String) -> void:
	# 主菜单不走 SceneManager（避免 fade 双层），直接 change_scene_to_file
	var err: int = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("MainMenu: change_scene_to_file failed err=%d for %s" % [err, scene_path])
		if Toast != null:
			Toast.show_error("场景切换失败")
