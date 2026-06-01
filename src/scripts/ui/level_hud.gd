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

func _process(_delta: float) -> void:
    _refresh()

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
        _progress_label.text = "✓ 已对话 %d/%d　[color=#ffd93d]去桌前提交答案吧[/color]" % [count, total]
        _progress_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.55))
    else:
        _progress_label.text = "已对话: %d/%d 名囚徒" % [count, total]
