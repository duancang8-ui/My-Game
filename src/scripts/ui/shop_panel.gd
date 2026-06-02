extends CanvasLayer

# P7：玉城商店面板
# - 列出 4 个道具（名/描述/价格）
# - 显示玩家当前道币
# - 购买按钮按当前道币是否足够动态启用
# - 关闭按钮（ESC 也可）

signal closed()

const PANEL_TEX: Texture2D = preload("res://src/assets/ui/dialogue_panel_9slice.png")
const BTN_NORMAL: Texture2D = preload("res://src/assets/ui/button_normal.png")
const BTN_HOVER: Texture2D = preload("res://src/assets/ui/button_hover.png")
const BTN_PRESSED: Texture2D = preload("res://src/assets/ui/button_pressed.png")

var _panel: PanelContainer
var _dao_label: Label
var _item_list_box: VBoxContainer
var _close_btn: Button

func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false

func _build() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -280
	_panel.offset_top = -230
	_panel.offset_right = 280
	_panel.offset_bottom = 230
	var sb := StyleBoxTexture.new()
	sb.texture = PANEL_TEX
	sb.texture_margin_left = 16
	sb.texture_margin_top = 16
	sb.texture_margin_right = 16
	sb.texture_margin_bottom = 16
	sb.content_margin_left = 24
	sb.content_margin_top = 20
	sb.content_margin_right = 24
	sb.content_margin_bottom = 20
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "🛒 玉城货摊"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	vbox.add_child(title)

	_dao_label = Label.new()
	_dao_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dao_label.add_theme_font_size_override("font_size", 14)
	_dao_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	vbox.add_child(_dao_label)

	_item_list_box = VBoxContainer.new()
	_item_list_box.add_theme_constant_override("separation", 6)
	vbox.add_child(_item_list_box)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	_close_btn = _make_btn("[ 关 闭 ]", Color(0.7, 0.65, 0.6))
	_close_btn.pressed.connect(_on_close_pressed)
	vbox.add_child(_close_btn)

func show_panel() -> void:
	_refresh()
	visible = true

func hide_panel() -> void:
	visible = false
	closed.emit()

func _refresh() -> void:
	_dao_label.text = "你身上有 🪙 %d 道" % GameState.dao_count
	# 清旧条目
	for child in _item_list_box.get_children():
		child.queue_free()
	for item_id in ItemRegistry.ALL:
		_item_list_box.add_child(_make_item_row(item_id))

func _make_item_row(item_id: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var info_v := VBoxContainer.new()
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info_v)

	var name_label := Label.new()
	name_label.text = "%s · %d 道" % [ItemRegistry.name_of(item_id), ItemRegistry.price_of(item_id)]
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	info_v.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = ItemRegistry.description_of(item_id)
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size = Vector2(360, 0)
	info_v.add_child(desc_label)

	var owned: int = GameState.get_item_count(item_id)
	var price: int = ItemRegistry.price_of(item_id)
	var can_buy: bool = GameState.dao_count >= price
	var btn: Button
	if can_buy:
		btn = _make_btn("买（已有 %d）" % owned, Color(0.95, 0.85, 0.45))
	else:
		btn = _make_btn("不够（已有 %d）" % owned, Color(0.55, 0.5, 0.45))
		btn.disabled = true
	btn.custom_minimum_size = Vector2(120, 36)
	var bound_id: String = item_id
	btn.pressed.connect(_on_buy_pressed.bind(bound_id))
	row.add_child(btn)
	return row

func _on_buy_pressed(item_id: String) -> void:
	var price: int = ItemRegistry.price_of(item_id)
	var ok: bool = GameState.try_purchase(item_id, price)
	if ok:
		if Toast != null:
			Toast.show_success("买入：%s（-%d 道）" % [ItemRegistry.name_of(item_id), price])
		if AudioManager != null:
			AudioManager.play_sfx("shop_purchase")
	else:
		if Toast != null:
			Toast.show_error("道不够……")
		if AudioManager != null:
			AudioManager.play_sfx("ui_click")
	_refresh()

func _on_close_pressed() -> void:
	hide_panel()

func _make_btn(label: String, font_color: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 0.92))
	btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.45, 0.4))
	btn.add_theme_stylebox_override("normal", _btn_style(BTN_NORMAL))
	btn.add_theme_stylebox_override("hover", _btn_style(BTN_HOVER))
	btn.add_theme_stylebox_override("pressed", _btn_style(BTN_PRESSED))
	btn.add_theme_stylebox_override("focus", _btn_style(BTN_HOVER))
	btn.add_theme_stylebox_override("disabled", _btn_style(BTN_NORMAL))
	return btn

func _btn_style(tex: Texture2D) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = 10
	sb.texture_margin_top = 6
	sb.texture_margin_right = 10
	sb.texture_margin_bottom = 6
	sb.content_margin_left = 14
	sb.content_margin_top = 8
	sb.content_margin_right = 14
	sb.content_margin_bottom = 8
	return sb

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		hide_panel()
		get_viewport().set_input_as_handled()
