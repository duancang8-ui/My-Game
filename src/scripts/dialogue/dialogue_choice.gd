class_name DialogueChoice
extends Resource

# 对话选项：玩家可点击的一个分支选择
# 设计为 Resource，可在 Inspector 编辑、可作为 .tres 保存

@export var label: String = ""              ## 显示给玩家的选项文字
@export var next_line_id: String = ""       ## 选择后跳转到的下一段对话 id（空 = 结束）
@export var ends_dialogue: bool = false     ## 是否结束整个对话（例如「离开」按钮）
@export var action_id: String = ""          ## P8: 选项的「副作用」标记，由 Orchestrator 钩子处理
                                             ## 例：付 1 道入场 → action_id = "enter_rat_warehouse"
