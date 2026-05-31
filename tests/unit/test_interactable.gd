extends GutTest

const InteractableScript = preload("res://src/scripts/interaction/interactable.gd")

var interactable: Interactable

func before_each() -> void:
    interactable = InteractableScript.new()

func after_each() -> void:
    if is_instance_valid(interactable):
        interactable.queue_free()

func test_interactable_default_type_is_none() -> void:
    assert_eq(interactable.interaction_type, Interactable.Type.NONE)

func test_interactable_emits_signal_on_interact() -> void:
    interactable.interaction_type = Interactable.Type.DIALOGUE
    interactable.dialogue_id = "test_dialogue_01"
    watch_signals(interactable)
    interactable.interact()
    assert_signal_emitted(interactable, "interaction_triggered")

func test_dialogue_interactable_carries_dialogue_id() -> void:
    interactable.interaction_type = Interactable.Type.DIALOGUE
    interactable.dialogue_id = "chen_junnan_intro"
    assert_eq(interactable.dialogue_id, "chen_junnan_intro")

func test_interactable_has_prompt_text() -> void:
    assert_eq(interactable.prompt_text, "[E] 互动", "默认提示文字")
    interactable.prompt_text = "[E] 与陈俊南交谈"
    assert_eq(interactable.prompt_text, "[E] 与陈俊南交谈")
