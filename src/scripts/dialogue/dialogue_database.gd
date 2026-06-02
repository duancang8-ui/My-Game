extends Node

# Autoload 单例：根据 dialogue_id 提供对话数据
# 用 lazy 初始化：首次访问时注册内置对话，保证在 _ready 不被调用的环境下也能工作（如 --script 模式）
#
# P4.7 重构：按原作 Ch1-15 校正
#   - 8 位其他参与者（玩家齐夏 + 8 NPC = 9 位）
#   - 所有人都抽到"说谎者"卡，唯一可投的是「人羊」
#   - 主城从"道城"改为"玉城"
#
# 所有对话内容为本项目自创笔触，保留原作人物设定（姓名、籍贯、职业、关键剧情节点），
# 但不复制原作具体段落文字。

var _dialogues_by_id: Dictionary = {}  # String -> Array[DialogueLine]
var _start_ids: Dictionary = {}        # String -> String
var _initialized: bool = false

func _ready() -> void:
	_ensure_initialized()

func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	_register_builtin_dialogues()

func _register_builtin_dialogues() -> void:
	_register_liar_opening_cutscene()
	_register_liar_sheep_rules()
	_register_liar_npc_dialogues_v1()
	_register_liar_npc_dialogues_v2()
	_register_liar_npc_dialogues_v3()
	_register_liar_sheep_master_dialogues()
	# P4 final · 4.9：3 个环境观察点 + 灵光闪现
	_register_liar_observation_clues()
	# P4 final · 4.8：说谎者赢后同房间触发雨后春笋的衔接过场
	_register_rainy_in_room_intro()
	_register_rainy_field_intro()

func register(dialogue_id: String, lines: Array, start_id: String) -> void:
	_dialogues_by_id[dialogue_id] = lines
	_start_ids[dialogue_id] = start_id

func has_dialogue(dialogue_id: String) -> bool:
	_ensure_initialized()
	return _dialogues_by_id.has(dialogue_id)

func get_lines(dialogue_id: String) -> Array:
	_ensure_initialized()
	return _dialogues_by_id.get(dialogue_id, [])

func get_start_id(dialogue_id: String) -> String:
	_ensure_initialized()
	return _start_ids.get(dialogue_id, "")

# === 工具函数 ===

func _narration(id: String, text: String) -> DialogueLine:
	var l: DialogueLine = DialogueLine.new()
	l.line_id = id
	l.speaker_name = "旁白"
	l.text = text
	return l

func _speaker_line(id: String, speaker: String, text: String) -> DialogueLine:
	var l: DialogueLine = DialogueLine.new()
	l.line_id = id
	l.speaker_name = speaker
	l.text = text
	return l

# === 开场过场：齐夏醒来在面试房间 + 人羊登场 + 当场示众杀人 ===

func _register_liar_opening_cutscene() -> void:
	var lines: Array[DialogueLine] = []
	lines.append(_narration("liar_open_01",
		"你不记得自己是怎么睡着的。\n[color=#888]上一秒还在通勤路上，下一秒——眼皮却怎么也撑不开。[/color]"))
	lines.append(_narration("liar_open_02",
		"等终于睁开眼，你坐在一张破旧的圆桌前。\n桌面上有一座制式繁复的小座钟，[color=#ffd93d]正滴答地走着[/color]。"))
	lines.append(_narration("liar_open_03",
		"你慢慢扫视四周——\n[color=#b71c1c]围着这张桌子，一共坐了十个人[/color]，每个人脸上都沾着灰。\n他们也才刚醒，眼神里只有迷茫。"))
	lines.append(_narration("liar_open_04",
		"这屋子没有门。\n四面是墙，墙上、地板、天花板都画着规整的方格线。\n[color=#aaaaaa]……我们到底是怎么进来的？[/color]"))
	lines.append(_narration_with_speaker("liar_open_05", "?",
		"[color=#b71c1c]在你们身边，静静地站着一个戴山羊面具的男人。[/color]\n面具上的羊毛打着结、变了色，连他的呼吸都带着一股说不上来的腐味。"))
	lines.append(_speaker_line("liar_open_06", "山羊面具",
		"早安，[color=#ffd93d]九位[/color]。\n（他笑了一下，声音从面具里闷闷地传出来）\n你们已经在我面前沉睡了十二个小时。"))
	lines.append(_narration("liar_open_07",
		"[color=#aaaaaa]——九位？桌边明明有十个人。[/color]\n你下意识数了一遍，没错。包括自己一共十个。\n[color=#888]那……还有一位是什么？[/color]"))
	lines.append(_narration("liar_open_08",
		"你伸手去摸口袋——手机不在。\n[color=#888]腿，使不上力。[/color]\n刚才一时没注意，原来双腿早就被某种东西放倒了。"))
	lines.append(_narration("liar_open_09",
		"[color=#b71c1c]——闷响。[/color]\n山羊面具不知何时绕到桌子另一侧，一只手按在了那个一直憨憨笑着的年轻人头上。\n下一刻，那颗头被砸进了桌面。"))
	lines.append(_narration("liar_open_10",
		"[color=#b71c1c]粉白色的东西在桌上铺开。[/color]\n桌边的每个人都被溅到了血点。\n房间外的某个远处，似乎在这一瞬响起了一声沉钟。"))
	lines.append(_speaker_line("liar_open_11", "山羊面具",
		"我准备了十个人，是为了用其中一个，让剩下的九位安静下来。\n[color=#b71c1c]——现在，「九位」了。[/color]"))

	for i in range(lines.size() - 1):
		lines[i].auto_next_line_id = lines[i + 1].line_id
	register("liar_opening_cutscene", lines, lines[0].line_id)

# === 规则过场：人羊宣布"说谎者"规则 + 玩家抽牌看到"说谎者" ===

func _register_liar_sheep_rules() -> void:
	var lines: Array[DialogueLine] = []
	lines.append(_speaker_line("liar_rules_01", "人羊",
		"[color=#b71c1c]容我自我介绍一下。[/color]\n我是「人羊」，你们是「参与者」。"))
	lines.append(_speaker_line("liar_rules_02", "人羊",
		"我把你们聚在这儿，是为了玩一场[color=#ffd93d]游戏[/color]。\n赢了，你们当中的一位会成为「神」。\n输了……（他垂下头）输了就太可惜了。"))
	lines.append(_speaker_line("liar_rules_03", "人羊",
		"这一场游戏，叫做[color=#ffd93d]「说谎者」[/color]。\n规则很简单——\n请[color=#ffd93d]每个人都讲一段[/color]：来到这里之前，最后发生的故事。"))
	lines.append(_speaker_line("liar_rules_04", "人羊",
		"在所有讲故事的人当中，[color=#ffd93d]有一个人说了假话[/color]。\n讲完后请投票——\n[color=#b71c1c]八个人都选中说谎者[/color]，说谎者出局，其余人活；\n但有任意一个人选错……所有人，都要被[color=#b71c1c]「制裁」[/color]。"))
	lines.append(_narration("liar_rules_05",
		"[color=#888]——人羊从怀里掏出一叠卡片，每个人面前放了一张。[/color]\n卡片背面印着「女娲游戏」四个字。"))
	lines.append(_speaker_line("liar_rules_06", "人羊",
		"对了，差点忘说——\n这些是[color=#ffd93d]身份牌[/color]。\n抽到「说谎者」的那位，[color=#b71c1c]必须撒谎[/color]。"))
	lines.append(_narration("liar_rules_07",
		"你用指尖扣住自己面前的卡片，[color=#aaaaaa]悄悄向自己的眼前翻开一角[/color]。"))
	lines.append(_narration("liar_rules_08",
		"[color=#b71c1c]——说谎者。[/color]\n你愣了几秒。\n[color=#aaaaaa]为什么是我？[/color]"))
	lines.append(_narration("liar_rules_09",
		"[color=#888]——好。无论如何，先去和每个人都聊一聊。[/color]\n[color=#aaaaaa]他们的故事里，也许会有比「我是说谎者」更重要的破绽。[/color]"))

	for i in range(lines.size() - 1):
		lines[i].auto_next_line_id = lines[i + 1].line_id
	register("liar_sheep_rules", lines, lines[0].line_id)

# ========== 8 NPC 对话 ==========
# 每个 NPC 三轮：
#   v1：自我介绍（base id，玩家第一次走近）
#   v2：玩家追问"被抓前最后发生的事"，NPC 讲一段故事（每段藏一处可疑细节）
#   v3：玩家追问"你怎么看其他人"，NPC 说出自己的怀疑或观察

func _register_liar_npc_dialogues_v1() -> void:
	_v1(LiarNpcId.TIANTIAN, "甜甜",
		"（她把一缕脏头发别到耳后，挤出一个职业性的笑）\n我叫[color=#ffd93d]甜甜[/color]。\n职业……嗯，就当我是[color=#888]「技术工作者」[/color]吧。我们凭本事赚钱。",
		"（她还想说什么，眼角余光瞟到桌上那具尸体，又把话咽了回去）")
	_v1(LiarNpcId.QIAO_JIAJIN, "乔家劲",
		"（满身花臂，叼着一根没点燃的烟）\n[color=#ffd93d]乔家劲[/color]，紫荆城混的。\n粉肠……这种破地方多说一句都浪费力气。",
		"（他把目光挪开，往人羊那边瞟了一眼）")
	_v1(LiarNpcId.HAN_YIMO, "韩一墨",
		"（声音很轻）\n[color=#ffd93d]韩一墨[/color]。",
		"[color=#888]……[/color]")
	_v1(LiarNpcId.ZHANG_CHENZE, "章晨泽",
		"（她双手环抱，嫌恶地搓了搓袖口的灰）\n[color=#ffd93d]章晨泽[/color]，律师。\n要不是在这种地方相遇，我应该会先递上一张名片。",
		"（她瞥了一眼那个戴山羊面具的男人）\n[color=#888]非法拘禁罪[/color]——这是底线问题。但他显然不在乎。")
	_v1(LiarNpcId.LI_SHANGWU, "李尚武",
		"（他坐得笔直，神情沉稳）\n[color=#ffd93d]李尚武[/color]，刑警。\n我们当中只有[color=#ffd93d]一个[/color]是说谎者——所以剩下的八位，应该想办法[color=#ffd93d]一起[/color]活下去。",
		"（他扫了一圈，目光在每个人身上停了半秒）")
	_v1(LiarNpcId.LIN_QIN, "林檎",
		"（她轻声开口，呼吸有一点抖）\n大家好。我叫[color=#ffd93d]林檎[/color]——\n[color=#888]苹果的「檎」。父母给我起的名字。[/color]\n我是心理咨询师。",
		"（她用指节轻轻敲了一下桌面，节奏稳定）")
	_v1(LiarNpcId.ZHAO_HAIBO, "赵海博",
		"（他扯了扯自己脏兮兮的白大褂）\n[color=#ffd93d]赵海博[/color]，医生。\n你应该从我的穿着，就能看出来。",
		"（他没有看你，目光落在那座座钟上）")
	_v1(LiarNpcId.XIAO_RAN, "肖冉",
		"（她说话时身体在抖）\n我……我叫[color=#ffd93d]肖冉[/color]，幼师。\n大理来的。\n[color=#888]——你能不能、坐过来一点？我害怕……[/color]",
		"（她用手按住嘴，又看了一眼桌上的尸体，整个人缩成一团）")

func _register_liar_npc_dialogues_v2() -> void:
	_v2(LiarNpcId.TIANTIAN, "甜甜",
		"（她叹了口气）\n……来这儿之前，我在上班。\n那天的客人是个奇葩——他非要在自己的车里。\n[color=#888]我把头伸出车窗透气，[/color]上面挂着一块巨大的广告牌……\n[color=#b71c1c]广告牌「哐」地一声砸下来。我就什么都不知道了。[/color]")
	_v2(LiarNpcId.QIAO_JIAJIN, "乔家劲",
		"（他咧嘴一笑，露出黄牙）\n靓仔，我做的就是放贷的，紫荆城那一带没人不认识我。\n那天我在天台上数完账，正要下楼——[color=#b71c1c]地动了一下[/color]。\n人没站稳，从天台栽下去……\n后来？[color=#888]后来就在这儿醒来了，没死。[/color]")
	_v2(LiarNpcId.HAN_YIMO, "韩一墨",
		"（他停顿了很久才开口）\n[color=#888]我在写大结局。[/color]\n书里上百号人物都要在那一章登场，我整个人——\n[color=#aaaaaa]——心思全在键盘上[/color]。\n后来怎么来的，我不知道。我连地震都没察觉。")
	_v2(LiarNpcId.ZHANG_CHENZE, "章晨泽",
		"（她声音平静，像在背一份案卷）\n我在开车去见当事人，刚过武侯祠。\n时速大约四十迈。\n[color=#b71c1c]前面的地面裂开了。[/color]我立刻刹车，停得很稳——\n[color=#888]但后面的车追尾，把我的车顶进了那道裂缝里。[/color]\n几声巨响之后，我就在这儿了。")
	_v2(LiarNpcId.LI_SHANGWU, "李尚武",
		"（他下意识摸了摸自己的脖子）\n[color=#ffd93d]我那天在蹲守一个诈骗犯。[/color]我们已经盯了他三天了——三天都没人露面。\n我让搭档跑去买烟。\n[color=#b71c1c]——一条细线从后座绕过来，勒住我的脖子。[/color]\n我把座椅放倒，挣脱了一下，但身后那人砸了我后脑勺。\n（他指了指脖颈，那里果然有一道淡淡的红痕）")
	_v2(LiarNpcId.LIN_QIN, "林檎",
		"（她语速很均匀）\n那天我在工作室等一位访客——是个幼师。\n她始终没来。\n[color=#b71c1c]地震的时候，整栋楼都在晃。[/color]\n我在二十六楼。\n[color=#888]后来天花板塌下来了……我眼前一黑。[/color]")
	_v2(LiarNpcId.ZHAO_HAIBO, "赵海博",
		"（他语气专业，每个名词都很精准）\n我正在做开颅手术。脑室内肿瘤，已经引起脑积水。\n[color=#b71c1c]我刚取下患者的头骨，准备剪硬脑膜。[/color]\n地震来了。我决定终止手术，把头骨先盖回去——\n[color=#888]但护士撞了我一下，我摔在地上。手术室的天花板裂开了。[/color]\n再睁眼，就在这里。")
	_v2(LiarNpcId.XIAO_RAN, "肖冉",
		"（她声音很小，几乎像哭腔）\n我那天带着一个小朋友过马路。\n[color=#b71c1c]地面忽然裂开，一辆车从右边冲过来……[/color]\n我把孩子推开——\n[color=#888]但是我自己没躲开。[/color]\n[color=#aaaaaa]后来就在这里了。[/color]")

func _register_liar_npc_dialogues_v3() -> void:
	_v3(LiarNpcId.TIANTIAN, "甜甜",
		"（她左右看了看，凑过来低声说）\n[color=#aaaaaa]这屋子真的没有门吗？[/color]\n我也不知道说谎者是谁……但是[color=#ffd93d]人羊从一开始就在「讲故事」[/color]啊——\n他说要「创造一个神」，那不也是个故事？")
	_v3(LiarNpcId.QIAO_JIAJIN, "乔家劲",
		"（他重重地咳了一声）\n粉肠，靓仔你听好——\n[color=#aaaaaa]我做这行这么多年[/color]，[color=#ffd93d]一眼就看出大家都不简单[/color]。\n但要我说真的[color=#b71c1c]最不对劲的[/color]，是站在那儿不动的那位「人羊」。\n他比谁都安静……越安静越可疑。")
	_v3(LiarNpcId.HAN_YIMO, "韩一墨",
		"（他终于多说了两句）\n[color=#888]……写小说的人，会留意「叙述者」是不是可靠。[/color]\n这场游戏的「叙述者」——\n[color=#ffd93d]从规则到一切，都是他一个人说的。[/color]\n[color=#aaaaaa]他到底是不是「讲故事的人」？这是关键。[/color]")
	_v3(LiarNpcId.ZHANG_CHENZE, "章晨泽",
		"（她推了推鬓角）\n这个游戏的「赢面」对说谎者来说[color=#ffd93d]大得不正常[/color]。\n我们彼此都不认识，怎么可能听出对方故事里的破绽？\n[color=#aaaaaa]——所以「举办者」一定留了线索。要么在故事里，要么在房间里。[/color]\n[color=#888]这几面方格墙，你看了吗？[/color]")
	_v3(LiarNpcId.LI_SHANGWU, "李尚武",
		"（他眉头一直没松）\n你也察觉了？\n[color=#aaaaaa]人羊一开始就说我们是「九位」。[/color]\n[color=#ffd93d]他用词非常小心——「九位讲故事的人」，他自己显然也算了进去。[/color]\n（他用拇指敲了敲桌面）\n这条线索，可能比任何一个人的故事都重要。")
	_v3(LiarNpcId.LIN_QIN, "林檎",
		"（她语速依然均匀）\n我刚才在数——\n[color=#aaaaaa]我们一共十个人在这屋里，已经超过一个小时了。[/color]\n[color=#ffd93d]可我没觉得这空气稀薄。[/color]\n[color=#888]如果我们都是「活人」……这个房间太小了，不可能不缺氧。[/color]")
	_v3(LiarNpcId.ZHAO_HAIBO, "赵海博",
		"（他冷静得像在讨论病例）\n刚才人羊单手把那位的头颅按碎了。\n[color=#aaaaaa]这超出了正常人类的力量极限。[/color]\n[color=#ffd93d]他不是「人」。[/color]\n（他抬起眼，看了你一眼）\n所以这场游戏里，「不是人」的那一位也讲过故事——这一点别忘了。")
	_v3(LiarNpcId.XIAO_RAN, "肖冉",
		"（她还在抖）\n[color=#aaaaaa]我害怕……[/color]\n但是你听——\n[color=#ffd93d]那个戴山羊面具的，他讲了一个故事[/color]：他说他「在创造神」。\n这不是故事是什么……？\n[color=#888]我们……我们应该投他吗？[/color]")

# 工具函数：把 v1/v2/v3 内容包装为完整的 DialogueLine 列表并注册
func _v1(npc_id: String, speaker: String, body: String, body2: String = "") -> void:
	var base: String = LiarNpcId.dialogue_id_of(npc_id)
	var l1: DialogueLine = DialogueLine.new()
	l1.line_id = base + "_01"
	l1.speaker_name = speaker
	l1.text = body
	if body2 != "":
		l1.auto_next_line_id = base + "_02"
		var l2: DialogueLine = DialogueLine.new()
		l2.line_id = base + "_02"
		l2.speaker_name = speaker
		l2.text = body2
		register(base, [l1, l2], l1.line_id)
	else:
		register(base, [l1], l1.line_id)

func _v2(npc_id: String, speaker: String, body: String) -> void:
	var base: String = LiarNpcId.dialogue_id_of(npc_id)
	var prompt: DialogueLine = DialogueLine.new()
	prompt.line_id = base + "_v2_prompt"
	prompt.speaker_name = "齐夏"
	prompt.text = "[color=#aaaaaa]能不能跟我说说——[/color]\n[color=#ffd93d]你来这儿之前，最后发生的事？[/color]"
	prompt.auto_next_line_id = base + "_v2_reply"
	var reply: DialogueLine = DialogueLine.new()
	reply.line_id = base + "_v2_reply"
	reply.speaker_name = speaker
	reply.text = body
	register(base + "_v2", [prompt, reply], prompt.line_id)

func _v3(npc_id: String, speaker: String, body: String) -> void:
	var base: String = LiarNpcId.dialogue_id_of(npc_id)
	var prompt: DialogueLine = DialogueLine.new()
	prompt.line_id = base + "_v3_prompt"
	prompt.speaker_name = "齐夏"
	prompt.text = "[color=#aaaaaa]（你压低声音）[/color]\n[color=#ffd93d]你觉得，谁最不对劲？[/color]"
	prompt.auto_next_line_id = base + "_v3_reply"
	var reply: DialogueLine = DialogueLine.new()
	reply.line_id = base + "_v3_reply"
	reply.speaker_name = speaker
	reply.text = body
	register(base + "_v3", [prompt, reply], prompt.line_id)

# === P4 final · 4.9 环境观察点 + 灵光闪现 ===

func _register_liar_observation_clues() -> void:
	# 墙边方格：齐夏数方格、估算房间体积
	var w1: DialogueLine = DialogueLine.new()
	w1.line_id = "observe_wall_grid_01"
	w1.speaker_name = "齐夏"
	w1.text = "[color=#aaaaaa]（你靠近墙边，伸手摸了摸那一道道线）[/color]\n[color=#ffd93d]这些方格大致每边一米。[/color]\n墙面是横 4 竖 3。地面和天花板是 4 × 4。"
	w1.auto_next_line_id = "observe_wall_grid_02"
	var w2: DialogueLine = DialogueLine.new()
	w2.line_id = "observe_wall_grid_02"
	w2.speaker_name = "齐夏"
	w2.text = "[color=#aaaaaa]（你心里默算）[/color]\n4 × 4 × 3 = [color=#ffd93d]48 立方米[/color]。\n这屋子……一共就这么大。"
	register("observe_wall_grid", [w1, w2], w1.line_id)

	# 座钟观察：感知"时间"
	var c1: DialogueLine = DialogueLine.new()
	c1.line_id = "observe_clock_01"
	c1.speaker_name = "齐夏"
	c1.text = "[color=#aaaaaa]（你盯着座钟）[/color]\n表针走得很正常。从醒来到现在……\n[color=#ffd93d]已经过了快一个小时了。[/color]"
	c1.auto_next_line_id = "observe_clock_02"
	var c2: DialogueLine = DialogueLine.new()
	c2.line_id = "observe_clock_02"
	c2.speaker_name = "齐夏"
	c2.text = "[color=#aaaaaa]人羊说过——我们之前已经在这里「沉睡了十二个小时」。[/color]\n加上现在的一小时。这屋子封闭着，[color=#ffd93d]十多个小时[/color]……\n空气够吗？"
	register("observe_clock", [c1, c2], c1.line_id)

	# 尸体观察：感知"温度"
	var b1: DialogueLine = DialogueLine.new()
	b1.line_id = "observe_corpse_01"
	b1.speaker_name = "齐夏"
	b1.text = "[color=#aaaaaa]（你硬着头皮伸出手，碰了碰那具趴在桌上的尸体）[/color]\n[color=#b71c1c]——已经没有体温了。[/color]"
	b1.auto_next_line_id = "observe_corpse_02"
	var b2: DialogueLine = DialogueLine.new()
	b2.line_id = "observe_corpse_02"
	b2.speaker_name = "齐夏"
	b2.text = "[color=#aaaaaa]可是血——还没有完全干。[/color]\n[color=#888]他被人羊砸碎头骨，也不过一个小时。[/color]\n[color=#ffd93d]这冷得太快了。不正常。[/color]"
	register("observe_corpse", [b1, b2], b1.line_id)

	# 灵光闪现：观察够 3 次触发
	var i1: DialogueLine = DialogueLine.new()
	i1.line_id = "liar_insight_01"
	i1.speaker_name = "齐夏"
	i1.text = "[color=#aaaaaa]（一道光从脑子里穿过）[/color]\n[color=#ffd93d]等等——[/color]\n这屋子 48 立方米。我们十个人在这儿快一个钟头了。"
	i1.auto_next_line_id = "liar_insight_02"
	var i2: DialogueLine = DialogueLine.new()
	i2.line_id = "liar_insight_02"
	i2.speaker_name = "齐夏"
	i2.text = "[color=#888]一个成年人每分钟要吸掉差不多 0.007 立方米空气。[/color]\n十个人一小时就要吃掉 4.2 立方米。\n再加上之前沉睡的十二个小时——[color=#ffd93d]远远超过 48 立方[/color]。"
	i2.auto_next_line_id = "liar_insight_03"
	var i3: DialogueLine = DialogueLine.new()
	i3.line_id = "liar_insight_03"
	i3.speaker_name = "齐夏"
	i3.text = "[color=#b71c1c]但我没缺氧。[/color]\n那具尸体——血还没干，体温却消失得太快。\n[color=#b71c1c]……我们根本不需要呼吸了。[/color]"
	i3.auto_next_line_id = "liar_insight_04"
	var i4: DialogueLine = DialogueLine.new()
	i4.line_id = "liar_insight_04"
	i4.speaker_name = "齐夏"
	i4.text = "[color=#aaaaaa]人羊讲过一个故事——「创造一个神」。[/color]\n[color=#ffd93d]他才是唯一一个，「明明在讲故事，却不在「九位」里」的人。[/color]\n[color=#888]——投他。九份纸上都写他。[/color]"
	register("liar_insight", [i1, i2, i3, i4], i1.line_id)

# === 人羊 NPC 三轮对话（人羊也可被走近交谈，但他的「故事」才是关键）===

func _register_liar_sheep_master_dialogues() -> void:
	var base: String = LiarNpcId.dialogue_id_of(LiarNpcId.SHEEP_MASTER)
	# v1
	var v1_1: DialogueLine = DialogueLine.new()
	v1_1.line_id = base + "_01"
	v1_1.speaker_name = "人羊"
	v1_1.text = "[color=#b71c1c]——欢迎，九位之一。[/color]\n（他的脸隐在山羊面具背后，看不出表情）\n好好[color=#ffd93d]想清楚[/color]再写下名字。"
	register(base, [v1_1], v1_1.line_id)
	# v2
	var v2_p: DialogueLine = DialogueLine.new()
	v2_p.line_id = base + "_v2_prompt"
	v2_p.speaker_name = "齐夏"
	v2_p.text = "[color=#aaaaaa]——你能不能告诉我，你「在做什么」？[/color]"
	v2_p.auto_next_line_id = base + "_v2_reply"
	var v2_r: DialogueLine = DialogueLine.new()
	v2_r.line_id = base + "_v2_reply"
	v2_r.speaker_name = "人羊"
	v2_r.text = "（他歪了一下头，缓缓开口）\n我们要[color=#ffd93d]创造一个「神」[/color]。\n和女娲一样的神。\n（他声音忽高忽低）她创造了人，又化作了彩虹——我们不能没有女娲，所以——\n[color=#b71c1c]要造一个新的。[/color]"
	register(base + "_v2", [v2_p, v2_r], v2_p.line_id)
	# v3
	var v3_p: DialogueLine = DialogueLine.new()
	v3_p.line_id = base + "_v3_prompt"
	v3_p.speaker_name = "齐夏"
	v3_p.text = "[color=#aaaaaa]你刚才说……「创造一个神」——[/color]\n[color=#ffd93d]这也是「故事」吗？[/color]"
	v3_p.auto_next_line_id = base + "_v3_reply"
	var v3_r: DialogueLine = DialogueLine.new()
	v3_r.line_id = base + "_v3_reply"
	v3_r.speaker_name = "人羊"
	v3_r.text = "（面具背后的目光在你脸上停了几秒）\n[color=#b71c1c]规则[/color]是绝对的。\n讲故事的人，一定有一个在说谎。\n[color=#888]……至于谁，你自己写。[/color]"
	register(base + "_v3", [v3_p, v3_r], v3_p.line_id)

# === P4 final · 4.8 雨后春笋衔接过场（在同一面试房间内触发）===

func _register_rainy_in_room_intro() -> void:
	var lines: Array[DialogueLine] = []
	lines.append(_narration("rainy_room_01",
		"[color=#888]——枪声还在墙间回荡。[/color]\n人羊倒在桌边，胸口的血迹一点一点向外蔓延。"))
	lines.append(_narration("rainy_room_02",
		"[color=#aaaaaa]你慢慢站起身，发现腿能动了。[/color]\n其他八个人也都活着。但门——还是没有出现。"))
	lines.append(_speaker_line("rainy_room_03", "乔家劲",
		"靓仔，你看……[color=#ffd93d]他的山羊面具内衬好像写着字。[/color]"))
	lines.append(_narration("rainy_room_04",
		"[color=#aaaaaa]（你蹲下，捡起面具翻过来）[/color]\n[color=#888]内衬上用钢笔写着一行小字：[/color]\n[color=#b71c1c]「我是人狗。鱼叉一刻不停。雨后见。」[/color]"))
	lines.append(_narration("rainy_room_05",
		"[color=#888]——远处。[/color]\n[color=#b71c1c]一声狗叫，闷闷的，像隔着一层雨幕。[/color]"))
	lines.append(_narration("rainy_room_06",
		"[color=#aaaaaa]你看了一眼桌子——[/color]\n[color=#ffd93d]这桌子不像普通圆桌，它的边角是多边形，似乎能转动。[/color]\n[color=#888]按 [E] 转动桌子，转够 100 圈，下一关就开始了。[/color]"))

	for i in range(lines.size() - 1):
		lines[i].auto_next_line_id = lines[i + 1].line_id
	register("rainy_in_room_intro", lines, lines[0].line_id)

# === 雨后春笋（人狗）入场过场（沿用 P6） ===

func _register_rainy_field_intro() -> void:
	var lines: Array[DialogueLine] = []
	lines.append(_narration("rainy_intro_01",
		"踩着泥泞的地面，你被一阵雨声拽过来。"))
	lines.append(_narration("rainy_intro_02",
		"[color=#888]雨水砸在皮肤上，每一滴都带着不安。[/color]\n眼前是一块湿漉漉的空地，中央摆着一张古怪的圆桌。"))
	lines.append(_speaker_line("rainy_intro_03", "人狗",
		"[color=#b71c1c]汪——[/color]\n（一只戴着狗面具的人四肢着地，慢慢直起身来）\n欢迎来玩「雨后春笋」。"))
	lines.append(_speaker_line("rainy_intro_04", "人狗",
		"规则简单：[color=#ffd93d]按 [E] 旋转这张桌子[/color]，转够[color=#ffd93d] 100 圈[/color]，「春笋」就会长出来——一种可以挡住天上飞来鱼叉的盾牌。"))
	lines.append(_speaker_line("rainy_intro_05", "人狗",
		"[color=#b71c1c]时间，30 秒。[/color]\n转不够 100 圈，你就会被鱼叉穿透。\n（它咧嘴一笑，露出狗一样的牙齿）"))
	lines.append(_narration("rainy_intro_06",
		"[color=#b71c1c]——头顶传来鱼叉破空的呼啸。[/color]\n你迅速冲到桌子旁——是时候转起来了。"))

	for i in range(lines.size() - 1):
		lines[i].auto_next_line_id = lines[i + 1].line_id
	register("rainy_field_intro", lines, lines[0].line_id)

func _narration_with_speaker(id: String, speaker: String, text: String) -> DialogueLine:
	var l: DialogueLine = DialogueLine.new()
	l.line_id = id
	l.speaker_name = speaker
	l.text = text
	return l
