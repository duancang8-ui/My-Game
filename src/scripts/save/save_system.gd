extends Node

# 存档系统：负责把 GameState 序列化到磁盘，读回来覆盖 GameState
# 使用 Godot ConfigFile（INI 格式：人类可读、易调试、原生支持）

const DEFAULT_SAVE_DIR: String = "user://saves/"
const SAVE_VERSION: int = 1

var save_dir: String = DEFAULT_SAVE_DIR  # 可被测试覆盖以隔离

func _ready() -> void:
    _ensure_dir()

func _ensure_dir() -> void:
    if not DirAccess.dir_exists_absolute(save_dir):
        DirAccess.make_dir_recursive_absolute(save_dir)

func _slot_path(slot: int) -> String:
    return save_dir + "slot_%d.save" % slot

func slot_exists(slot: int) -> bool:
    return FileAccess.file_exists(_slot_path(slot))

func save_to_slot(slot: int) -> bool:
    _ensure_dir()
    var cfg: ConfigFile = ConfigFile.new()
    cfg.set_value("meta", "version", SAVE_VERSION)
    cfg.set_value("meta", "saved_at", Time.get_datetime_string_from_system(false, true))
    var state: Dictionary = GameState.to_dict()
    for key in state.keys():
        cfg.set_value("game", key, state[key])
    var err: int = cfg.save(_slot_path(slot))
    if err != OK:
        push_error("SaveSystem.save_to_slot: cfg.save failed with err=%d (path=%s)" % [err, _slot_path(slot)])
        return false
    return true

func load_from_slot(slot: int) -> bool:
    var path: String = _slot_path(slot)
    if not FileAccess.file_exists(path):
        return false
    var cfg: ConfigFile = ConfigFile.new()
    var err: int = cfg.load(path)
    if err != OK:
        push_error("SaveSystem.load_from_slot: cfg.load failed with err=%d (path=%s)" % [err, path])
        return false
    var version: int = cfg.get_value("meta", "version", 0)
    if version != SAVE_VERSION:
        push_warning("SaveSystem: save version %d differs from expected %d" % [version, SAVE_VERSION])
    var state: Dictionary = {}
    if cfg.has_section("game"):
        for key in cfg.get_section_keys("game"):
            state[key] = cfg.get_value("game", key)
    GameState.from_dict(state)
    return true
