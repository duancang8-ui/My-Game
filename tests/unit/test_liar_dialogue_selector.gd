extends GutTest

# P4.6 · a2 多轮对话切换 selector

const SelectorScript = preload("res://src/scripts/liar_game/liar_npc_dialogue_selector.gd")
const InteractableScript = preload("res://src/scripts/interaction/interactable.gd")

var sel: Node
var inter: Interactable

func before_each() -> void:
	GameState.reset()
	sel = SelectorScript.new()
	add_child_autofree(sel)
	inter = InteractableScript.new()
	inter.interaction_type = Interactable.Type.DIALOGUE
	inter.dialogue_id = "liar_lin_qin"
	add_child_autofree(inter)
	sel.register_interactable_for_test(inter, "liar_lin_qin")

func test_zero_visits_uses_base_dialogue_id() -> void:
	assert_eq(inter.dialogue_id, "liar_lin_qin")

func test_one_visit_switches_to_v2() -> void:
	GameState.increment_visit_count("liar_lin_qin")
	sel.register_interactable_for_test(inter, "liar_lin_qin")
	assert_eq(inter.dialogue_id, "liar_lin_qin_v2")

func test_two_visits_switches_to_v3() -> void:
	GameState.increment_visit_count("liar_lin_qin")
	GameState.increment_visit_count("liar_lin_qin")
	sel.register_interactable_for_test(inter, "liar_lin_qin")
	assert_eq(inter.dialogue_id, "liar_lin_qin_v3")

func test_many_visits_stays_at_v3() -> void:
	for i in range(10):
		GameState.increment_visit_count("liar_lin_qin")
	sel.register_interactable_for_test(inter, "liar_lin_qin")
	assert_eq(inter.dialogue_id, "liar_lin_qin_v3")

func test_strip_version_suffix_correctly() -> void:
	assert_eq(sel._strip_version_suffix("liar_li_shangwu"), "liar_li_shangwu")
	assert_eq(sel._strip_version_suffix("liar_li_shangwu_v2"), "liar_li_shangwu")
	assert_eq(sel._strip_version_suffix("liar_li_shangwu_v3"), "liar_li_shangwu")
