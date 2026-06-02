class_name LiarNpcId
extends RefCounted

# 「说谎者」关卡的 8 位其他参与者（玩家齐夏 + 8 NPC = 原作 9 位参与者）
# P4.7 重构：按原作 Ch1-10 校正人物
#   - 删除：苏闪 / 陈俊南（皆为后期道城角色，错放）
#   - 新增：李尚武（刑警，原作里的"健硕年轻人"）/ 甜甜（化名，本名张丽娟）
# P4.7 机制反转：所有人都抽到"说谎者"卡，唯一正确答案是「人羊」
#   故"靶子" 概念消失，但保留 SHEEP_MASTER 常量作为投票候选

const TIANTIAN: String = "tiantian"             # 甜甜（本名张丽娟）· 陕西 · 技术工作者
const QIAO_JIAJIN: String = "qiao_jiajin"       # 乔家劲 · 广东 · 紫荆城放贷
const HAN_YIMO: String = "han_yimo"             # 韩一墨 · 广西 · 网络小说作家
const ZHANG_CHENZE: String = "zhang_chenze"     # 章晨泽 · 四川 · 律师
const LI_SHANGWU: String = "li_shangwu"         # 李尚武 · 内蒙 · 刑警
const LIN_QIN: String = "lin_qin"               # 林檎 · 宁夏 · 心理咨询师
const ZHAO_HAIBO: String = "zhao_haibo"         # 赵海博 · 江苏 · 神经外科医生
const XIAO_RAN: String = "xiao_ran"             # 肖冉 · 云南大理 · 幼师

const SHEEP_MASTER: String = "sheep_master"     # 人羊（非参与者，但唯一正确的投票答案）

const ALL: Array = [
    TIANTIAN, QIAO_JIAJIN, HAN_YIMO, ZHANG_CHENZE,
    LI_SHANGWU, LIN_QIN, ZHAO_HAIBO, XIAO_RAN,
]

# 投票候选 = 8 位参与者 + 人羊
const ALL_VOTE_TARGETS: Array = [
    TIANTIAN, QIAO_JIAJIN, HAN_YIMO, ZHANG_CHENZE,
    LI_SHANGWU, LIN_QIN, ZHAO_HAIBO, XIAO_RAN,
    SHEEP_MASTER,
]

const NAMES: Dictionary = {
    TIANTIAN: "甜甜",
    QIAO_JIAJIN: "乔家劲",
    HAN_YIMO: "韩一墨",
    ZHANG_CHENZE: "章晨泽",
    LI_SHANGWU: "李尚武",
    LIN_QIN: "林檎",
    ZHAO_HAIBO: "赵海博",
    XIAO_RAN: "肖冉",
    SHEEP_MASTER: "人羊",
}

# 简短籍贯/职业（用于线索面板和回顾）
const ORIGINS: Dictionary = {
    TIANTIAN: "陕西",
    QIAO_JIAJIN: "广东",
    HAN_YIMO: "广西",
    ZHANG_CHENZE: "四川（成都）",
    LI_SHANGWU: "内蒙",
    LIN_QIN: "宁夏",
    ZHAO_HAIBO: "江苏",
    XIAO_RAN: "云南大理",
}

const PROFESSIONS: Dictionary = {
    TIANTIAN: "技术工作者",
    QIAO_JIAJIN: "紫荆城放贷",
    HAN_YIMO: "网络小说作家",
    ZHANG_CHENZE: "律师",
    LI_SHANGWU: "刑警",
    LIN_QIN: "心理咨询师",
    ZHAO_HAIBO: "神经外科医生",
    XIAO_RAN: "幼师",
}

const COLORS: Dictionary = {
    TIANTIAN: Color(0.95, 0.55, 0.75),      ## 粉
    QIAO_JIAJIN: Color(0.95, 0.45, 0.30),   ## 橙
    HAN_YIMO: Color(0.45, 0.55, 0.95),      ## 蓝紫
    ZHANG_CHENZE: Color(0.85, 0.85, 0.95),  ## 清冷白
    LI_SHANGWU: Color(0.45, 0.75, 1.0),     ## 警蓝
    LIN_QIN: Color(0.45, 0.95, 0.55),       ## 绿
    ZHAO_HAIBO: Color(0.95, 0.95, 0.95),    ## 白大褂
    XIAO_RAN: Color(0.95, 0.85, 0.55),      ## 暖黄
    SHEEP_MASTER: Color(0.25, 0.20, 0.20),  ## 山羊面具暗色
}

# 每个 NPC 对应的对话 id（v1 为 base，v2/v3 由 LiarNpcDialogueSelector 自动切换）
const DIALOGUE_IDS: Dictionary = {
    TIANTIAN: "liar_tiantian",
    QIAO_JIAJIN: "liar_qiao_jiajin",
    HAN_YIMO: "liar_han_yimo",
    ZHANG_CHENZE: "liar_zhang_chenze",
    LI_SHANGWU: "liar_li_shangwu",
    LIN_QIN: "liar_lin_qin",
    ZHAO_HAIBO: "liar_zhao_haibo",
    XIAO_RAN: "liar_xiao_ran",
    SHEEP_MASTER: "liar_sheep_master",   ## 与人羊也可以聊（v1/v2/v3 内容不同）
}

static func name_of(npc_id: String) -> String:
    return NAMES.get(npc_id, npc_id)

static func origin_of(npc_id: String) -> String:
    return ORIGINS.get(npc_id, "未知")

static func profession_of(npc_id: String) -> String:
    return PROFESSIONS.get(npc_id, "未知")

static func dialogue_id_of(npc_id: String) -> String:
    return DIALOGUE_IDS.get(npc_id, "")

static func is_sheep_master(npc_id: String) -> bool:
    return npc_id == SHEEP_MASTER
