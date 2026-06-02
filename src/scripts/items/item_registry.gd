class_name ItemRegistry
extends RefCounted

# P7：玉城商店可购买的道具（占位实现，效果留作后续 hook）
# 所有道具名/描述均为本项目自创，与原作概念保持精神契合（嗅觉/桃木/休息/线索）

const ITEM_SMELL_NOTE: String = "item_smell_note"
const ITEM_DEFENSE_CHARM: String = "item_defense_charm"
const ITEM_REST_TICKET: String = "item_rest_ticket"
const ITEM_CLUE_BAG: String = "item_clue_bag"

const ALL: Array = [
	ITEM_SMELL_NOTE, ITEM_DEFENSE_CHARM, ITEM_REST_TICKET, ITEM_CLUE_BAG,
]

const NAMES: Dictionary = {
	ITEM_SMELL_NOTE:    "灵闻笔记",
	ITEM_DEFENSE_CHARM: "桃木防御符",
	ITEM_REST_TICKET:   "休息券",
	ITEM_CLUE_BAG:      "线索袋",
}

const PRICES: Dictionary = {
	ITEM_SMELL_NOTE:    5,
	ITEM_DEFENSE_CHARM: 8,
	ITEM_REST_TICKET:   3,
	ITEM_CLUE_BAG:      6,
}

const DESCRIPTIONS: Dictionary = {
	ITEM_SMELL_NOTE:    "据说是某位「清香者」记下的气味习惯。下一关进场时，能让你对一些 NPC 多闻出一句线索。",
	ITEM_DEFENSE_CHARM: "桃木刻成的小符。下一次「制裁」来临时，至少能替你扛一下。",
	ITEM_REST_TICKET:   "撕了它，你这一回合就当没发生。Day 不会向前推进。",
	ITEM_CLUE_BAG:      "里面装着一些零碎的纸条。打开后，会随机点亮当前关卡的一个未观察线索。",
}

static func name_of(item_id: String) -> String:
	return NAMES.get(item_id, item_id)

static func price_of(item_id: String) -> int:
	return int(PRICES.get(item_id, 0))

static func description_of(item_id: String) -> String:
	return DESCRIPTIONS.get(item_id, "")
