class_name DialogueRunner
extends RefCounted

# 对话状态机（纯逻辑，无 UI 依赖）
# UI 层订阅 line_changed / dialogue_ended 信号来更新显示

signal line_changed(line: DialogueLine)
signal dialogue_ended()

var current_line: DialogueLine = null
var _lines_by_id: Dictionary = {}  # String -> DialogueLine

func is_active() -> bool:
    return current_line != null

func start(lines: Array, start_id: String) -> void:
    _lines_by_id.clear()
    for line in lines:
        if line is DialogueLine:
            _lines_by_id[(line as DialogueLine).line_id] = line
    _go_to(start_id)

func advance() -> void:
    if not is_active():
        return
    if current_line.choices.size() > 0:
        return  # 有选项时等待玩家选择，不能直接 advance
    _go_to(current_line.auto_next_line_id)

func pick_choice(index: int) -> void:
    if not is_active():
        return
    if index < 0 or index >= current_line.choices.size():
        push_warning("DialogueRunner.pick_choice: index %d out of range (0..%d)" % [index, current_line.choices.size() - 1])
        return
    var choice: DialogueChoice = current_line.choices[index]
    if choice.ends_dialogue:
        _end()
        return
    _go_to(choice.next_line_id)

func _go_to(line_id: String) -> void:
    if line_id == "" or not _lines_by_id.has(line_id):
        _end()
        return
    current_line = _lines_by_id[line_id]
    line_changed.emit(current_line)

func _end() -> void:
    current_line = null
    dialogue_ended.emit()
