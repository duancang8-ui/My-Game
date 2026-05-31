extends GutTest

const DialogueLineScript = preload("res://src/scripts/dialogue/dialogue_line.gd")
const DialogueChoiceScript = preload("res://src/scripts/dialogue/dialogue_choice.gd")

func test_dialogue_line_has_defaults() -> void:
    var line: DialogueLine = DialogueLineScript.new()
    assert_eq(line.line_id, "", "默认 id 为空")
    assert_eq(line.speaker_name, "", "默认说话人为空")
    assert_eq(line.text, "", "默认文本为空")
    assert_eq(line.choices.size(), 0, "默认无选项")

func test_dialogue_line_can_be_built() -> void:
    var line: DialogueLine = DialogueLineScript.new()
    line.line_id = "intro_01"
    line.speaker_name = "陈俊南"
    line.text = "你也是被押送来的？"
    assert_eq(line.line_id, "intro_01")
    assert_eq(line.speaker_name, "陈俊南")
    assert_eq(line.text, "你也是被押送来的？")

func test_dialogue_choice_has_defaults() -> void:
    var choice: DialogueChoice = DialogueChoiceScript.new()
    assert_eq(choice.label, "", "默认标签为空")
    assert_eq(choice.next_line_id, "", "默认下一句 id 为空")
    assert_false(choice.ends_dialogue, "默认不结束对话")

func test_dialogue_choice_ends_dialogue() -> void:
    var choice: DialogueChoice = DialogueChoiceScript.new()
    choice.label = "（沉默）离开"
    choice.ends_dialogue = true
    assert_true(choice.ends_dialogue, "结束选项标记")
