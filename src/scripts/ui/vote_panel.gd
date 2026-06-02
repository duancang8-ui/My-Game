extends CanvasLayer

# 「说谎者」关卡的投票 UI（弹出式）
# 玩家走到"提交答案"互动点 → 触发 show_for_npcs([...]) → 列出按钮
# 玩家点击某个 NPC 按钮 → 触发 vote_picked(npc_id) 信号
# 点击取消按钮 → cancelled 信号 + 关闭

signal vote_picked(npc_id: String)
signal cancelled()

const BTN_NORMAL: Texture2D = preload("res://src/assets/ui/button_normal.png")
const BTN_HOVER: Texture2D = preload("res://src/assets/ui/button_hover.png")
const BTN_PRESSED: Texture2D = preload("res://src/assets/ui/button_pressed.png")
const PANEL_TEX: Texture2D = preload("res://src/assets/ui/dialogue_panel_9slice.png")

var _panel: PanelContainer
var _vbox: VBoxContainer
var _title: Label

func _ready() -> void:
    layer = 50
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build()
    visible = false

func _build() -> void:
    _panel = PanelContainer.new()
    _panel.anchor_left = 0.5
    _panel.anchor_top = 0.5
    _panel.anchor_right = 0.5
    _panel.anchor_bottom = 0.5
    _panel.offset_left = -220
    _panel.offset_top = -200
    _panel.offset_right = 220
    _panel.offset_bottom = 200
    var sb := StyleBoxTexture.new()
    sb.texture = PANEL_TEX
    sb.texture_margin_left = 16
    sb.texture_margin_top = 16
    sb.texture_margin_right = 16
    sb.texture_margin_bottom = 16
    sb.content_margin_left = 24
    sb.content_margin_top = 24
    sb.content_margin_right = 24
    sb.content_margin_bottom = 24
    _panel.add_theme_stylebox_override("panel", sb)
    add_child(_panel)

    _vbox = VBoxContainer.new()
    _vbox.add_theme_constant_override("separation", 8)
    _panel.add_child(_vbox)

    _title = Label.new()
    _title.text = "你要在纸上写下谁的名字？"
    _title.add_theme_font_size_override("font_size", 18)
    _title.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85, 1))
    _title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _vbox.add_child(_title)

    var spacer := Control.new()
    spacer.custom_minimum_size = Vector2(0, 8)
    _vbox.add_child(spacer)

func show_for_npcs(npc_ids: Array) -> void:
    _clear_buttons()
    for npc_id in npc_ids:
        if LiarNpcId.is_sheep_master(npc_id):
            continue   ## 人羊单独渲染（放最下、高对比）
        var btn := _make_button("写下 " + LiarNpcId.name_of(npc_id), Color(0.95, 0.92, 0.85))
        var id: String = npc_id
        btn.pressed.connect(func() -> void:
            vote_picked.emit(id)
            visible = false
        )
        _vbox.add_child(btn)

    # 分割线提示"另类选项"
    var divider := Control.new()
    divider.custom_minimum_size = Vector2(0, 18)
    _vbox.add_child(divider)

    var sheep_label := Label.new()
    sheep_label.text = "—— 或者 ——"
    sheep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sheep_label.add_theme_font_size_override("font_size", 11)
    sheep_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
    _vbox.add_child(sheep_label)

    # 人羊按钮：暗红高对比，让玩家意识到"这是非常规答案"
    var sheep_btn := _make_button("[ 写下「人羊」 ]", Color(1.0, 0.55, 0.45))
    sheep_btn.pressed.connect(func() -> void:
        vote_picked.emit(LiarNpcId.SHEEP_MASTER)
        visible = false
    )
    _vbox.add_child(sheep_btn)

    var cancel_spacer := Control.new()
    cancel_spacer.custom_minimum_size = Vector2(0, 12)
    _vbox.add_child(cancel_spacer)

    var cancel_btn := _make_button("（再想想）取消", Color(0.65, 0.6, 0.55))
    cancel_btn.pressed.connect(func() -> void:
        cancelled.emit()
        visible = false
    )
    _vbox.add_child(cancel_btn)

    visible = true

func _clear_buttons() -> void:
    # 保留 _title 和第一个 spacer（前 2 个子节点），其余清空
    var children: Array = _vbox.get_children()
    for i in range(children.size() - 1, 1, -1):
        children[i].queue_free()

func _make_button(label: String, font_color: Color) -> Button:
    var btn := Button.new()
    btn.text = label
    btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
    btn.add_theme_font_size_override("font_size", 15)
    btn.add_theme_color_override("font_color", font_color)
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
    sb.content_margin_top = 8
    sb.content_margin_right = 14
    sb.content_margin_bottom = 8
    return sb
