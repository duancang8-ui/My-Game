extends CanvasLayer

# 顶部 HUD：显示玩家当前进度（已对话 X/N 名 NPC + 操作提示）
# 监听 GameState.completed_dialogues 来计数
# 这样过场结束后玩家能清楚下一步做什么

const PANEL_TEX: Texture2D = preload("res://src/assets/ui/dialogue_panel_9slice.png")

@export var npc_dialogue_ids: Array[String] = []
@export var hint_text: String = "[E] 与人交谈　|　走到桌前的黄色光球提交答案"

var _panel: PanelContainer
var _progress_label: Label
var _hint_label: Label
var _sheep_hint_label: RichTextLabel
var _sheep_hint_text: String = ""
# P4.6 · a3 倒计时显示
var _timer_label: Label
var _timer_visible: bool = false
var _timer_blink_phase: float = 0.0
# P4 final · c3 道币显示
var _dao_label: Label

func _ready() -> void:
    layer = 5
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build()
    _refresh()
    # 监听 GameState 变化（DialogueController 调用 mark_dialogue_completed 后刷新）
    var gs = get_node_or_null("/root/GameState")
    if gs != null and not gs.is_connected("tree_exited", _refresh):
        # GameState 没有 changed signal，用 polling 简单处理
        set_process(true)

func _process(delta: float) -> void:
    _refresh()
    _tick_timer_blink(delta)

func _build() -> void:
    _panel = PanelContainer.new()
    _panel.anchor_left = 0.5
    _panel.anchor_top = 0
    _panel.anchor_right = 0.5
    _panel.anchor_bottom = 0
    _panel.offset_left = -280
    _panel.offset_top = 20
    _panel.offset_right = 280
    _panel.offset_bottom = 80
    var sb := StyleBoxTexture.new()
    sb.texture = PANEL_TEX
    sb.texture_margin_left = 16
    sb.texture_margin_top = 16
    sb.texture_margin_right = 16
    sb.texture_margin_bottom = 16
    sb.content_margin_left = 20
    sb.content_margin_top = 8
    sb.content_margin_right = 20
    sb.content_margin_bottom = 8
    _panel.add_theme_stylebox_override("panel", sb)
    add_child(_panel)

    var vbox := VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 2)
    _panel.add_child(vbox)

    _progress_label = Label.new()
    _progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _progress_label.add_theme_font_size_override("font_size", 16)
    _progress_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
    vbox.add_child(_progress_label)

    _hint_label = Label.new()
    _hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _hint_label.add_theme_font_size_override("font_size", 12)
    _hint_label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.65))
    _hint_label.text = hint_text
    vbox.add_child(_hint_label)

    _sheep_hint_label = RichTextLabel.new()
    _sheep_hint_label.bbcode_enabled = true
    _sheep_hint_label.fit_content = true
    _sheep_hint_label.scroll_active = false
    _sheep_hint_label.custom_minimum_size = Vector2(540, 0)
    _sheep_hint_label.add_theme_font_size_override("normal_font_size", 13)
    _sheep_hint_label.add_theme_color_override("default_color", Color(0.95, 0.45, 0.45))
    _sheep_hint_label.visible = false
    vbox.add_child(_sheep_hint_label)

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

    # P4.6 · a3 倒计时（独立 Label，右上角）
    _timer_label = Label.new()
    _timer_label.anchor_left = 1.0
    _timer_label.anchor_right = 1.0
    _timer_label.anchor_top = 0.0
    _timer_label.anchor_bottom = 0.0
    _timer_label.offset_left = -180
    _timer_label.offset_right = -20
    _timer_label.offset_top = 24
    _timer_label.offset_bottom = 60
    _timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _timer_label.add_theme_font_size_override("font_size", 22)
    _timer_label.add_theme_color_override("font_color", Color(0.95, 0.65, 0.35))
    _timer_label.visible = false
    add_child(_timer_label)

func update_timer(time_left: float) -> void:
    if _timer_label == null:
        return
    _timer_visible = true
    _timer_label.visible = true
    var total: int = int(ceil(time_left))
    var mm: int = total / 60
    var ss: int = total % 60
    _timer_label.text = "⏳ %02d:%02d" % [mm, ss]
    if time_left <= 60.0:
        _timer_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
    else:
        _timer_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))

func hide_timer() -> void:
    _timer_visible = false
    if _timer_label != null:
        _timer_label.visible = false

func _tick_timer_blink(delta: float) -> void:
    if not _timer_visible or _timer_label == null:
        return
    # 当剩余 < 60s 时（颜色已变红），叠加 modulate 闪烁
    var text: String = _timer_label.text
    if text.begins_with("⏳ 00:"):
        _timer_blink_phase += delta * 4.0
        var a: float = 0.45 + 0.55 * abs(sin(_timer_blink_phase))
        _timer_label.modulate = Color(1, 1, 1, a)
    else:
        _timer_label.modulate = Color.WHITE

func set_sheep_hint(text: String) -> void:
    _sheep_hint_text = text
    if _sheep_hint_label != null:
        _sheep_hint_label.text = text
        _sheep_hint_label.visible = (text != "")

func _refresh() -> void:
    var gs = get_node_or_null("/root/GameState")
    if gs == null:
        _progress_label.text = "已对话: 0/%d" % npc_dialogue_ids.size()
        return
    var count: int = 0
    for did in npc_dialogue_ids:
        if gs.completed_dialogues.has(did):
            count += 1
    var total: int = npc_dialogue_ids.size()
    if count >= total and total > 0:
        _progress_label.text = "✓ 已对话 %d/%d　[color=#ffd93d]去桌前写下名字吧[/color]" % [count, total]
        _progress_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.55))
    else:
        _progress_label.text = "已对话: %d/%d 名参与者" % [count, total]
    # P4 final · c3 道币
    if _dao_label != null:
        _dao_label.text = "🪙 %d 道" % gs.dao_count
