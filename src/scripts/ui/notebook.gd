extends CanvasLayer

# P4 final · a4：笔记本系统（Autoload）
# - 玩家与某个 NPC 进行 v2/v3 对话结束后，自动写入「关键事实」摘要
# - 按 N 切换显示
# - 投票面板可主动调用 show_panel() 同场展示
# - 条目按 NPC 显示：每个 NPC 一行汇总（v2 职业事实 + v3 观察事实）
#
# 摘要文本为本项目原创笔触（与对话同步），便于玩家做笔记决策

const PANEL_TEX: Texture2D = preload("res://src/assets/ui/dialogue_panel_9slice.png")

# dialogue_id → "NPC 名|条目摘要"
const ENTRY_TABLE: Dictionary = {
	# v2 故事关键事实
	"liar_tiantian_v2":    "甜甜|陕西 · 技术工作者，被广告牌砸晕在车里",
	"liar_qiao_jiajin_v2": "乔家劲|广东 · 放贷，天台地震时摔下",
	"liar_han_yimo_v2":    "韩一墨|广西 · 网络作家，写大结局，没察觉地震",
	"liar_zhang_chenze_v2":"章晨泽|四川 · 律师，开庭途中车被顶进裂缝",
	"liar_li_shangwu_v2":  "李尚武|内蒙 · 刑警,蹲守诈骗犯,被细线勒颈",
	"liar_lin_qin_v2":     "林檎|宁夏 · 心理咨询师,工作室在 26 楼,天花板塌下",
	"liar_zhao_haibo_v2":  "赵海博|江苏 · 神经外科,开颅术中,手术室天花板裂开",
	"liar_xiao_ran_v2":    "肖冉|云南 · 幼师,带小孩过马路被车撞",
	"liar_sheep_master_v2":"人羊|讲了一个故事：要「创造一个神」",
	# v3 观察事实
	"liar_tiantian_v3":    "甜甜·v3|提到「人羊也在讲故事」",
	"liar_qiao_jiajin_v3": "乔家劲·v3|觉得人羊最不对劲，越安静越可疑",
	"liar_han_yimo_v3":    "韩一墨·v3|提到「叙述者」是不是可靠",
	"liar_zhang_chenze_v3":"章晨泽·v3|「举办者一定在房间或故事里留了线索」",
	"liar_li_shangwu_v3":  "李尚武·v3|察觉「九位」措辞——人羊把自己算了进去",
	"liar_lin_qin_v3":     "林檎·v3|觉察空气不稀薄——这屋子不该这么舒服",
	"liar_zhao_haibo_v3":  "赵海博·v3|断言人羊「不是人」（单手砸碎头骨）",
	"liar_xiao_ran_v3":    "肖冉·v3|直接说「投人羊」",
	"liar_sheep_master_v3":"人羊·v3|含糊：「规则是绝对的」",
	# 观察点
	"observe_wall_grid":   "环境|房间约 48 立方米（4×4×3）",
	"observe_clock":       "环境|十多个小时密闭，可空气没事",
	"observe_corpse":      "环境|尸体凉得太快，但血未干",
	"liar_insight":        "★关键|九人呼吸超过 48 立方，但我们没缺氧 → 我们已死",
}

var entries: Dictionary = {}   # npc_name → Array[String] 多条事实

var _panel: PanelContainer
var _label: RichTextLabel
var _hint: Label

func _ready() -> void:
	layer = 70
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
	_panel.offset_top = -220
	_panel.offset_right = 280
	_panel.offset_bottom = 220
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
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "📓 齐夏的笔记本"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	vbox.add_child(title)

	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = true
	_label.custom_minimum_size = Vector2(520, 320)
	_label.add_theme_font_size_override("normal_font_size", 13)
	_label.add_theme_color_override("default_color", Color(0.92, 0.88, 0.78))
	vbox.add_child(_label)

	_hint = Label.new()
	_hint.text = "[N] 关闭笔记本"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 11)
	_hint.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6))
	vbox.add_child(_hint)

func record(dialogue_id: String) -> bool:
	if not ENTRY_TABLE.has(dialogue_id):
		return false
	var raw: String = ENTRY_TABLE[dialogue_id]
	var parts: PackedStringArray = raw.split("|")
	if parts.size() < 2:
		return false
	var npc_key: String = parts[0]
	var fact: String = parts[1]
	if not entries.has(npc_key):
		entries[npc_key] = []
	if (entries[npc_key] as Array).has(fact):
		return false
	(entries[npc_key] as Array).append(fact)
	return true

func _render_entries() -> void:
	if _label == null:
		return
	if entries.is_empty():
		_label.text = "[color=#888]……还没记下任何线索。\n（去和每个人都聊聊，或者观察房间里的东西）[/color]"
		return
	var lines: PackedStringArray = PackedStringArray()
	# 按字典顺序展示，但"★关键"行优先
	var keys: Array = entries.keys()
	keys.sort()
	for k in keys:
		var npc_lines: Array = entries[k]
		var color: String = "#ffd93d" if k.begins_with("★") else "#e0d8b8"
		lines.append("[color=" + color + "][b]" + str(k) + "[/b][/color]")
		for f in npc_lines:
			lines.append("  • " + str(f))
		lines.append("")
	_label.text = "\n".join(lines)

func show_panel() -> void:
	_render_entries()
	visible = true

func hide_panel() -> void:
	visible = false

func toggle() -> void:
	if visible:
		hide_panel()
	else:
		show_panel()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo and k.keycode == KEY_N:
			toggle()
			get_viewport().set_input_as_handled()
