extends Node

# Autoload 单例：根据 dialogue_id 提供对话数据
# 用 lazy 初始化：首次访问时注册内置对话，保证在 _ready 不被调用的环境下也能工作（如 --script 模式）
# 后续扩展：从 res://src/assets/dialogues/*.tres 自动加载、热重载、本地化

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
    register_chen_junnan_intro()
    _register_liar_game_dialogues()
    _register_liar_opening_cutscene()
    _register_liar_sheep_rules()
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

# === 示例对话：Cycle 2 重生后陈俊南不认识齐夏 ===

func register_chen_junnan_intro() -> void:
    # Cycle 2 第 1 天，齐夏在面试房间外见到失忆的陈俊南
    # 这是 P2 的占位对话，用于演示对话系统全流程
    var l1: DialogueLine = DialogueLine.new()
    l1.line_id = "intro_01"
    l1.speaker_name = "陈俊南"
    l1.text = "你是谁？这地方又是哪？"
    var c1: DialogueChoice = DialogueChoice.new()
    c1.label = "（自我介绍）我是齐夏。"
    c1.next_line_id = "intro_02_a"
    var c2: DialogueChoice = DialogueChoice.new()
    c2.label = "你不认识我了？"
    c2.next_line_id = "intro_02_b"
    var c3: DialogueChoice = DialogueChoice.new()
    c3.label = "（沉默）离开。"
    c3.ends_dialogue = true
    l1.choices = [c1, c2, c3] as Array[DialogueChoice]

    var l2a: DialogueLine = DialogueLine.new()
    l2a.line_id = "intro_02_a"
    l2a.speaker_name = "陈俊南"
    l2a.text = "齐夏？没听过。你也是被押来这鬼地方的？"
    l2a.auto_next_line_id = "intro_03"

    var l2b: DialogueLine = DialogueLine.new()
    l2b.line_id = "intro_02_b"
    l2b.speaker_name = "陈俊南"
    l2b.text = "（皱眉）我们见过？我怎么一点印象都没有……"
    l2b.auto_next_line_id = "intro_03_b"

    var l3: DialogueLine = DialogueLine.new()
    l3.line_id = "intro_03"
    l3.speaker_name = "齐夏"
    l3.text = "（看着他失忆的样子，[color=#b71c1c]这又是新一轮的开始[/color]……）"
    l3.auto_next_line_id = ""  # 结束

    var l3b: DialogueLine = DialogueLine.new()
    l3b.line_id = "intro_03_b"
    l3b.speaker_name = "齐夏"
    l3b.text = "（[color=#b71c1c]别提这事[/color]。）算了，可能我认错了。"
    l3b.auto_next_line_id = ""  # 结束

    register("chen_junnan_intro", [l1, l2a, l2b, l3, l3b], "intro_01")

# === P4: 「说谎者」关卡 5 名 NPC 的占位对话 ===
# ⚠️ 这些台词是 AI 占位版，等 docs/source/2789.txt.zip 到位后批量替换为 Ch 1~5 原作摘录

func _register_liar_game_dialogues() -> void:
    # P4.5: NPC 对话改为只做自我介绍 + 一句通用感想（不暗示特定人）
    # 真正指向靶子的"暗示"由人羊在规则讲完后单独给出（运行时根据随机靶子生成）
    _register_one_liar_npc(
        "liar_chen_junnan", "陈俊南",
        "我叫陈俊南，是个警察。被押来这之前我正在追一个贩毒嫌疑人。",
        "我做警察十几年了，[color=#b71c1c]这种诡异的房间和山羊面具的家伙，连噩梦里都没见过[/color]。"
    )
    _register_one_liar_npc(
        "liar_qiao_jiajin", "乔家劲",
        "乔家劲，紫荆城混的。在这鬼地方多说一句都是浪费力气。",
        "[color=#8b8b8b]（沉默了几秒）[/color]……谁是说谎者？老子哪知道。投票就是了。"
    )
    _register_one_liar_npc(
        "liar_zhang_lijuan", "张丽娟",
        "我叫张丽娟，做技术的。被抓来时我正在公司加班。",
        "我看了看每个人……[color=#888]坦白说，我谁都不敢相信[/color]。"
    )
    _register_one_liar_npc(
        "liar_su_shan", "苏闪",
        "苏闪，长沙刑警支队技术员。我刚才在记每个人说话时的微表情。",
        "数据不够。我能告诉你的是：[color=#b71c1c]这里没有人在「表面上」说谎[/color]——也就是说，靶子是被规则指定的。"
    )
    _register_one_liar_npc(
        "liar_lin_qin", "林檎",
        "我叫林檎，心理咨询师。被押来这之前刚做完一个家暴受害人案例。",
        "[color=#888]（轻轻一笑）[/color]我做的是倾听者的工作，不太适合评价别人。\n至于谁是说谎者……[color=#b71c1c]或许人羊说的「规则」本身才是谜底[/color]。"
    )
    _register_one_liar_npc(
        "liar_han_yimo", "韩一墨",
        "韩一墨。",
        "[color=#888]……[/color]"
    )
    _register_one_liar_npc(
        "liar_zhang_chenze", "章晨泽",
        "我是章晨泽，律师。被抓来时我正在准备一个集体诉讼。",
        "「靶子」是规则指定的概念——这意味着任何人都可能是。[color=#b71c1c]我们其实在玩一个无解的游戏[/color]。"
    )
    _register_one_liar_npc(
        "liar_zhao_haibo", "赵海博",
        "赵海博，神经外科医生。我对脑科很专业，但对这种「游戏」是外行。",
        "如果非要我说……[color=#b71c1c]我注意人羊给暗示的时候，他眼神瞟过的方向[/color]。也许那才是关键。"
    )
    _register_one_liar_npc(
        "liar_xiao_ran", "肖冉",
        "肖冉。我是幼儿园老师。被抓来这之前我在……做一些不太能说的事。",
        "[color=#888]（她突然停下，目光转向地面）[/color]……每个人都有秘密，不是吗？"
    )

func _register_one_liar_npc(dialogue_id: String, speaker_name: String, intro_text: String, hint_text: String) -> void:
    var l1: DialogueLine = DialogueLine.new()
    l1.line_id = dialogue_id + "_01"
    l1.speaker_name = speaker_name
    l1.text = intro_text
    var c_ask: DialogueChoice = DialogueChoice.new()
    c_ask.label = "你怀疑谁是说谎者？"
    c_ask.next_line_id = dialogue_id + "_02"
    var c_leave: DialogueChoice = DialogueChoice.new()
    c_leave.label = "（先去问问别人）"
    c_leave.ends_dialogue = true
    l1.choices = [c_ask, c_leave] as Array[DialogueChoice]

    var l2: DialogueLine = DialogueLine.new()
    l2.line_id = dialogue_id + "_02"
    l2.speaker_name = speaker_name
    l2.text = hint_text
    l2.auto_next_line_id = ""

    register(dialogue_id, [l1, l2], dialogue_id + "_01")

# === P4.1: 开场过场（叙述性，让没读过原作的玩家上手）===

func _register_liar_opening_cutscene() -> void:
    var lines: Array[DialogueLine] = []

    lines.append(_narration("liar_open_01",
        "你叫齐夏，刚下班回家。地铁车厢摇晃，你在低头刷手机。"))
    lines.append(_narration("liar_open_02",
        "下一秒——[color=#b71c1c]脚下一空[/color]。"))
    lines.append(_narration("liar_open_03",
        "再睁开眼，你坐在一个陌生的房间里。\n围着一张破旧的圆桌，对面坐着 5 个同样茫然的陌生人。"))
    lines.append(_narration("liar_open_04",
        "[color=#888]——这是哪？这些人是谁？——[/color]"))
    lines.append(_narration("liar_open_05",
        "你脑海中只有这一个问题，[color=#b71c1c]直到看见站在桌子上方的「他」[/color]。"))
    lines.append(_narration_with_speaker("liar_open_06", "?",
        "[color=#b71c1c]一个戴着白色山羊面具的人，正歪着头看着你们。[/color]"))
    lines.append(_narration("liar_open_07",
        "[color=#888]他没有立刻说话。空气安静得能听见自己的心跳。[/color]\n[color=#b71c1c]你意识到——你大概，正身处某种「游戏」之中。[/color]"))

    # 串联 auto_next
    for i in range(lines.size() - 1):
        lines[i].auto_next_line_id = lines[i + 1].line_id

    register("liar_opening_cutscene", lines, lines[0].line_id)

# === P4.1: 人羊·张强宣布游戏规则 ===

func _register_liar_sheep_rules() -> void:
    var lines: Array[DialogueLine] = []

    lines.append(_speaker_line("liar_rules_01", "人羊·张强",
        "（戴着山羊面具的男人慢慢摘下面具半边，露出半张笑脸）\n[color=#b71c1c]欢迎来到「面试房间」。我叫张强，你们叫我「人羊」就好。[/color]"))
    lines.append(_speaker_line("liar_rules_02", "人羊·张强",
        "你们 6 人之中——包括坐在那边发愣的[color=#ffd93d]你[/color]——\n[color=#b71c1c]有 1 个人，是规则指定的「说谎者」。[/color]"))
    lines.append(_speaker_line("liar_rules_03", "人羊·张强",
        "[color=#888]注意听好了：[/color]\n「说谎者」不一定真的撒过谎。[color=#b71c1c]TA 只是「被规则选中的那个人」。[/color]"))
    lines.append(_speaker_line("liar_rules_04", "人羊·张强",
        "你需要做的事很简单：[color=#ffd93d]和每个人都聊聊[/color]——\n然后到这张桌子前，[color=#ffd93d]提交你认为是「说谎者」的那个人[/color]。"))
    lines.append(_speaker_line("liar_rules_05", "人羊·张强",
        "[color=#b71c1c]猜对了，你们都活；猜错了……[/color]\n（他把面具戴回去）……让你们尝尝「制裁」的滋味。"))
    lines.append(_narration("liar_rules_06",
        "[color=#888]——人羊重新戴上面具，安静地退到房间一角。\n房间里其他 5 个人开始小声交头接耳。是时候去和每个人都谈谈了。[/color]"))

    for i in range(lines.size() - 1):
        lines[i].auto_next_line_id = lines[i + 1].line_id

    register("liar_sheep_rules", lines, lines[0].line_id)

func _narration(id: String, text: String) -> DialogueLine:
    var l: DialogueLine = DialogueLine.new()
    l.line_id = id
    l.speaker_name = "旁白"
    l.text = text
    return l

func _narration_with_speaker(id: String, speaker: String, text: String) -> DialogueLine:
    var l: DialogueLine = DialogueLine.new()
    l.line_id = id
    l.speaker_name = speaker
    l.text = text
    return l

func _speaker_line(id: String, speaker: String, text: String) -> DialogueLine:
    var l: DialogueLine = DialogueLine.new()
    l.line_id = id
    l.speaker_name = speaker
    l.text = text
    return l

# === P6: 雨后春笋（人狗）入场过场 ===

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
