class_name DialogueLine
extends Resource

# 一段对话：包含说话人、文本、和零或多个选项
# 一个完整对话由多个 DialogueLine 通过 next_line_id 串联组成

@export var line_id: String = ""                   ## 唯一标识，DialogueRunner 用此跳转
@export var speaker_name: String = ""              ## 角色名（齐夏 / 陈俊南 / 乔家劲...）
@export var text: String = ""                      ## 对话内容
@export var choices: Array[DialogueChoice] = []    ## 选项列表；空表示纯陈述（点任意键继续）
@export var auto_next_line_id: String = ""         ## 无选项时，点任意键后跳转的 id；空表示结束
