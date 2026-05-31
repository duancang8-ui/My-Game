class_name SaveTestKeybinds
extends Node

# P3 调试热键：F9 存档到 slot 0，F10 从 slot 0 读档
# 后续 P4+ 会换成正式的 UI 存档菜单

const QUICK_SLOT: int = 0

@export var player_path: NodePath = NodePath("../YSortContainer/Player")

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("quick_save"):
        _capture_state_and_save()
    elif event.is_action_pressed("quick_load"):
        _load_and_apply_state()

func _capture_state_and_save() -> void:
    var player: Node = get_node_or_null(player_path)
    if player != null:
        GameState.player_position = player.position
    var ok: bool = SaveSystem.save_to_slot(QUICK_SLOT)
    if ok:
        print("[SaveSystem] Quick-saved to slot %d (cycle=%d day=%d pos=%s dao=%d)" % [
            QUICK_SLOT, GameState.current_cycle, GameState.current_day,
            GameState.player_position, GameState.dao_count
        ])
    else:
        push_error("[SaveSystem] Quick-save failed")

func _load_and_apply_state() -> void:
    var ok: bool = SaveSystem.load_from_slot(QUICK_SLOT)
    if not ok:
        push_warning("[SaveSystem] No save in slot %d" % QUICK_SLOT)
        return
    var player: Node = get_node_or_null(player_path)
    if player != null:
        player.position = GameState.player_position
    print("[SaveSystem] Quick-loaded from slot %d (cycle=%d day=%d pos=%s dao=%d)" % [
        QUICK_SLOT, GameState.current_cycle, GameState.current_day,
        GameState.player_position, GameState.dao_count
    ])
