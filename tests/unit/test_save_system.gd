extends GutTest

const SAVE_DIR_TEST: String = "user://saves_test/"
const SLOT: int = 99

func before_each() -> void:
    SaveSystem.save_dir = SAVE_DIR_TEST
    GameState.reset()
    _cleanup_slot()

func after_each() -> void:
    _cleanup_slot()
    SaveSystem.save_dir = SaveSystem.DEFAULT_SAVE_DIR

func _cleanup_slot() -> void:
    var path: String = SAVE_DIR_TEST + "slot_%d.save" % SLOT
    if FileAccess.file_exists(path):
        var abs: String = ProjectSettings.globalize_path(path)
        DirAccess.remove_absolute(abs)

func test_save_creates_file() -> void:
    GameState.current_cycle = 2
    var ok: bool = SaveSystem.save_to_slot(SLOT)
    assert_true(ok, "save_to_slot 应成功")
    assert_true(SaveSystem.slot_exists(SLOT), "slot 文件应存在")

func test_load_restores_state() -> void:
    GameState.current_cycle = 3
    GameState.current_day = 7
    GameState.player_position = Vector2(123, 456)
    GameState.mark_npc_met("陈俊南")
    GameState.add_dao(99)
    assert_true(SaveSystem.save_to_slot(SLOT))
    GameState.reset()
    assert_eq(GameState.current_cycle, 1, "reset 后默认")
    var ok: bool = SaveSystem.load_from_slot(SLOT)
    assert_true(ok)
    assert_eq(GameState.current_cycle, 3)
    assert_eq(GameState.current_day, 7)
    assert_eq(GameState.player_position, Vector2(123, 456))
    assert_true(GameState.met_npcs.has("陈俊南"))
    assert_eq(GameState.dao_count, 99)

func test_load_nonexistent_slot_returns_false() -> void:
    var ok: bool = SaveSystem.load_from_slot(99999)
    assert_false(ok)

func test_slot_exists_returns_false_when_empty() -> void:
    assert_false(SaveSystem.slot_exists(SLOT))
