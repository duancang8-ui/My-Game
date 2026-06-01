class_name Interactable
extends Area2D

# 可交互对象基类，挂在 NPC、规则牌、副本入口等节点上
# 玩家的 PlayerInteractor 探测到 + 按 E 时触发 interaction_triggered 信号

signal interaction_triggered(interactable: Interactable)

enum Type {
    NONE,
    DIALOGUE,       ## 触发对话（携带 dialogue_id）
    PICKUP,         ## 拾取物品（后续 plan 实装）
    SCENE_CHANGE,   ## 切换场景（后续 plan 实装）
    VOTE,           ## 触发关卡投票面板（用于「说谎者」等）
}

@export var interaction_type: Type = Type.NONE
@export var dialogue_id: String = ""              ## type == DIALOGUE 时使用
@export var prompt_text: String = "[E] 互动"       ## 玩家附近提示文字（P2 占位用）

func interact() -> void:
    interaction_triggered.emit(self)
