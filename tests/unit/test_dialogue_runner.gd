extends GutTest

const DialogueRunnerScript = preload("res://src/scripts/dialogue/dialogue_runner.gd")
const DialogueLineScript = preload("res://src/scripts/dialogue/dialogue_line.gd")
const DialogueChoiceScript = preload("res://src/scripts/dialogue/dialogue_choice.gd")

var runner: DialogueRunner

func before_each() -> void:
    runner = DialogueRunnerScript.new()

func _make_line(id: String, text: String, choices: Array = []) -> DialogueLine:
    var line: DialogueLine = DialogueLineScript.new()
    line.line_id = id
    line.speaker_name = "TestSpeaker"
    line.text = text
    if choices.size() > 0:
        var typed_choices: Array[DialogueChoice] = []
        for c in choices:
            typed_choices.append(c)
        line.choices = typed_choices
    return line

func _make_choice(label: String, next_id: String, ends: bool = false) -> DialogueChoice:
    var c: DialogueChoice = DialogueChoiceScript.new()
    c.label = label
    c.next_line_id = next_id
    c.ends_dialogue = ends
    return c

func test_runner_starts_inactive() -> void:
    assert_false(runner.is_active(), "未启动时 inactive")
    assert_null(runner.current_line, "未启动时 current_line 为 null")

func test_runner_starts_a_dialogue() -> void:
    var lines: Array = [_make_line("a", "Hello")]
    runner.start(lines, "a")
    assert_true(runner.is_active(), "启动后 active")
    assert_eq(runner.current_line.text, "Hello")

func test_runner_advances_via_auto_next() -> void:
    var l1: DialogueLine = _make_line("a", "Line 1")
    l1.auto_next_line_id = "b"
    var l2: DialogueLine = _make_line("b", "Line 2")
    runner.start([l1, l2], "a")
    runner.advance()
    assert_eq(runner.current_line.text, "Line 2", "auto_next 推进")

func test_runner_ends_when_no_next() -> void:
    var l1: DialogueLine = _make_line("a", "Solo line")
    runner.start([l1], "a")
    runner.advance()
    assert_false(runner.is_active(), "无 next 时结束")
    assert_null(runner.current_line)

func test_runner_picks_choice() -> void:
    var l1: DialogueLine = _make_line("a", "Pick one", [
        _make_choice("Go A", "a_result"),
        _make_choice("Go B", "b_result"),
    ])
    var l_a: DialogueLine = _make_line("a_result", "You chose A")
    var l_b: DialogueLine = _make_line("b_result", "You chose B")
    runner.start([l1, l_a, l_b], "a")
    runner.pick_choice(1)  # 选第 2 个选项（index 1）
    assert_eq(runner.current_line.text, "You chose B")

func test_choice_with_ends_dialogue_stops() -> void:
    var l1: DialogueLine = _make_line("a", "Final", [
        _make_choice("Leave", "", true),
    ])
    runner.start([l1], "a")
    runner.pick_choice(0)
    assert_false(runner.is_active(), "ends_dialogue 选项结束对话")

func test_advance_does_nothing_when_choices_present() -> void:
    var l1: DialogueLine = _make_line("a", "Has choices", [
        _make_choice("Go", "b"),
    ])
    var l2: DialogueLine = _make_line("b", "Should not reach")
    runner.start([l1, l2], "a")
    runner.advance()  # 应该被忽略，因为 l1 有选项
    assert_eq(runner.current_line.text, "Has choices", "有选项时 advance 不生效")
