class_name LiarNpcId
extends RefCounted

# 「说谎者」关卡的 9 名其他囚徒（齐夏 + 9 = 10，符合原作）
# P4.5 扩展自 P4 的 5 名版本

const CHEN_JUNNAN: String = "chen_junnan"
const QIAO_JIAJIN: String = "qiao_jiajin"
const ZHANG_LIJUAN: String = "zhang_lijuan"
const SU_SHAN: String = "su_shan"
const LIN_QIN: String = "lin_qin"
const HAN_YIMO: String = "han_yimo"
const ZHANG_CHENZE: String = "zhang_chenze"
const ZHAO_HAIBO: String = "zhao_haibo"
const XIAO_RAN: String = "xiao_ran"

const ALL: Array = [
    CHEN_JUNNAN, QIAO_JIAJIN, ZHANG_LIJUAN, SU_SHAN, LIN_QIN,
    HAN_YIMO, ZHANG_CHENZE, ZHAO_HAIBO, XIAO_RAN,
]

const NAMES: Dictionary = {
    CHEN_JUNNAN: "陈俊南",
    QIAO_JIAJIN: "乔家劲",
    ZHANG_LIJUAN: "张丽娟",
    SU_SHAN: "苏闪",
    LIN_QIN: "林檎",
    HAN_YIMO: "韩一墨",
    ZHANG_CHENZE: "章晨泽",
    ZHAO_HAIBO: "赵海博",
    XIAO_RAN: "肖冉",
}

const COLORS: Dictionary = {
    CHEN_JUNNAN: Color(0.45, 0.75, 1.0),    ## 蓝
    QIAO_JIAJIN: Color(0.95, 0.45, 0.30),   ## 橙
    ZHANG_LIJUAN: Color(0.85, 0.65, 0.95),  ## 紫
    SU_SHAN: Color(0.45, 0.95, 0.55),       ## 绿
    LIN_QIN: Color(0.95, 0.55, 0.75),       ## 粉
    HAN_YIMO: Color(0.95, 0.85, 0.30),      ## 金
    ZHANG_CHENZE: Color(0.45, 0.95, 0.95),  ## 青
    ZHAO_HAIBO: Color(0.65, 0.30, 0.30),    ## 暗红
    XIAO_RAN: Color(0.85, 0.85, 0.80),      ## 白灰
}

# 每个 NPC 的"颜色名字描述"（用于人羊暗示模板里：靶子的衣服颜色）
const COLOR_NAMES: Dictionary = {
    CHEN_JUNNAN: "蓝色",
    QIAO_JIAJIN: "橙色",
    ZHANG_LIJUAN: "紫色",
    SU_SHAN: "绿色",
    LIN_QIN: "粉色",
    HAN_YIMO: "金色",
    ZHANG_CHENZE: "青色",
    ZHAO_HAIBO: "暗红色",
    XIAO_RAN: "灰白色",
}

# 每个 NPC 的"特征描述"（用于人羊暗示模板）
const TRAITS: Dictionary = {
    CHEN_JUNNAN: "看起来像个警察的男人",
    QIAO_JIAJIN: "一脸混不吝的江湖气",
    ZHANG_LIJUAN: "戴眼镜的技术员气质",
    SU_SHAN: "一直在观察别人的男人",
    LIN_QIN: "气质平静的年轻女人",
    HAN_YIMO: "话很少的一墨",
    ZHANG_CHENZE: "穿着律师装束的男人",
    ZHAO_HAIBO: "目光锐利的男人",
    XIAO_RAN: "面相温和的女人",
}

# 每个 NPC 对应的 dialogue_id
const DIALOGUE_IDS: Dictionary = {
    CHEN_JUNNAN: "liar_chen_junnan",
    QIAO_JIAJIN: "liar_qiao_jiajin",
    ZHANG_LIJUAN: "liar_zhang_lijuan",
    SU_SHAN: "liar_su_shan",
    LIN_QIN: "liar_lin_qin",
    HAN_YIMO: "liar_han_yimo",
    ZHANG_CHENZE: "liar_zhang_chenze",
    ZHAO_HAIBO: "liar_zhao_haibo",
    XIAO_RAN: "liar_xiao_ran",
}

# 关卡的"靶子" —— P4.5 改为运行时随机生成（不再硬编码）
# 测试时可通过 LiarGameController.liar_target_id 覆盖固定值
static func random_target(rng: RandomNumberGenerator = null) -> String:
    if rng == null:
        rng = RandomNumberGenerator.new()
        rng.randomize()
    return ALL[rng.randi() % ALL.size()]

static func name_of(npc_id: String) -> String:
    return NAMES.get(npc_id, npc_id)

static func color_name_of(npc_id: String) -> String:
    return COLOR_NAMES.get(npc_id, "未知颜色")

static func trait_of(npc_id: String) -> String:
    return TRAITS.get(npc_id, "未知")

static func dialogue_id_of(npc_id: String) -> String:
    return DIALOGUE_IDS.get(npc_id, "")
