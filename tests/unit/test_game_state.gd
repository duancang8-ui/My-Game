extends GutTest

# GameState 是 autoload，可直接用名字引用

func before_each() -> void:
    GameState.reset()

func test_default_values() -> void:
    assert_eq(GameState.current_cycle, 1)
    assert_eq(GameState.current_day, 1)
    assert_eq(GameState.player_position, Vector2.ZERO)
    assert_eq(GameState.met_npcs.size(), 0)
    assert_eq(GameState.completed_dialogues.size(), 0)
    assert_eq(GameState.dao_count, 0)

func test_can_set_player_position() -> void:
    GameState.player_position = Vector2(120, 240)
    assert_eq(GameState.player_position, Vector2(120, 240))

func test_can_add_met_npc() -> void:
    GameState.mark_npc_met("chen_junnan")
    assert_true(GameState.met_npcs.has("chen_junnan"))
    GameState.mark_npc_met("chen_junnan")
    assert_eq(GameState.met_npcs.size(), 1, "重复添加不应造成重复")

func test_can_complete_dialogue() -> void:
    GameState.mark_dialogue_completed("chen_junnan_intro")
    assert_true(GameState.completed_dialogues.has("chen_junnan_intro"))

func test_add_dao() -> void:
    GameState.add_dao(5)
    assert_eq(GameState.dao_count, 5)
    GameState.add_dao(3)
    assert_eq(GameState.dao_count, 8)

func test_advance_cycle_resets_day() -> void:
    GameState.current_day = 7
    GameState.advance_cycle()
    assert_eq(GameState.current_cycle, 2)
    assert_eq(GameState.current_day, 1)

func test_to_dict_and_from_dict_roundtrip() -> void:
    GameState.current_cycle = 3
    GameState.current_day = 5
    GameState.player_position = Vector2(100, 200)
    GameState.mark_npc_met("乔家劲")
    GameState.mark_dialogue_completed("test_d_01")
    GameState.add_dao(42)
    var dict: Dictionary = GameState.to_dict()
    GameState.reset()
    assert_eq(GameState.current_cycle, 1)
    GameState.from_dict(dict)
    assert_eq(GameState.current_cycle, 3)
    assert_eq(GameState.current_day, 5)
    assert_eq(GameState.player_position, Vector2(100, 200))
    assert_true(GameState.met_npcs.has("乔家劲"))
    assert_true(GameState.completed_dialogues.has("test_d_01"))
    assert_eq(GameState.dao_count, 42)
