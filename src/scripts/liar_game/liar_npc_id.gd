class_name LiarNpcId
extends RefCounted

# 「说谎者」关卡的 5 名其他囚徒（不含主理人张强）
# 占位元数据；对话内容存于 DialogueDatabase；台词为 AI 占位待 P3.5③ 完成后用原作 Ch 1~5 真实摘录批量替换

const CHEN_JUNNAN: String = "chen_junnan"
const QIAO_JIAJIN: String = "qiao_jiajin"
const ZHANG_LIJUAN: String = "zhang_lijuan"
const SU_SHAN: String = "su_shan"
const LIN_QIN: String = "lin_qin"

const ALL: Array = [CHEN_JUNNAN, QIAO_JIAJIN, ZHANG_LIJUAN, SU_SHAN, LIN_QIN]

const NAMES: Dictionary = {
    CHEN_JUNNAN: "陈俊南",
    QIAO_JIAJIN: "乔家劲",
    ZHANG_LIJUAN: "张丽娟",
    SU_SHAN: "苏闪",
    LIN_QIN: "林檎",
}

# 用 modulate 颜色区分 5 名占位 sprite
const COLORS: Dictionary = {
    CHEN_JUNNAN: Color(0.45, 0.75, 1.0),
    QIAO_JIAJIN: Color(0.95, 0.45, 0.30),
    ZHANG_LIJUAN: Color(0.85, 0.65, 0.95),
    SU_SHAN: Color(0.45, 0.95, 0.55),
    LIN_QIN: Color(0.95, 0.55, 0.75),
}

# 关卡的"靶子"——按原作设定林檎是青龙安插的"针"
# P4 占位硬编码；P5+ 可由 LiarGameController 改为随机生成或场景配置
const LIAR_ID: String = LIN_QIN

# 每个 NPC 对应的 dialogue_id（用于 Interactable.dialogue_id）
const DIALOGUE_IDS: Dictionary = {
    CHEN_JUNNAN: "liar_chen_junnan",
    QIAO_JIAJIN: "liar_qiao_jiajin",
    ZHANG_LIJUAN: "liar_zhang_lijuan",
    SU_SHAN: "liar_su_shan",
    LIN_QIN: "liar_lin_qin",
}

static func name_of(npc_id: String) -> String:
    return NAMES.get(npc_id, npc_id)

static func dialogue_id_of(npc_id: String) -> String:
    return DIALOGUE_IDS.get(npc_id, "")
