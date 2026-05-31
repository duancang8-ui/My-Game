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
