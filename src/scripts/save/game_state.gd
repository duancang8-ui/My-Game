extends Node

# 游戏全局状态单例（Autoload）
# 内存中保存"唯一真相"，由 SaveSystem 序列化/反序列化
# 对应 spec §5.2 十日轮回与记忆系统

var current_cycle: int = 1
var current_day: int = 1
var player_position: Vector2 = Vector2.ZERO
var met_npcs: PackedStringArray = PackedStringArray()
var completed_dialogues: PackedStringArray = PackedStringArray()
var dao_count: int = 0
var current_scene_path: String = ""    ## 当前所在场景（用于存档恢复时跳回正确场景）
var npc_visit_count: Dictionary = {}   ## P4.6 · a2: dialogue_id → 已访问次数
var observed_clues: PackedStringArray = PackedStringArray()   ## P4 final · 4.9: 已观察的环境线索
var scene_positions: Dictionary = {}   ## P5.5: scene_file_path → Vector2，玩家上次离开该场景时的位置

func reset() -> void:
    current_cycle = 1
    current_day = 1
    player_position = Vector2.ZERO
    met_npcs = PackedStringArray()
    completed_dialogues = PackedStringArray()
    dao_count = 0
    current_scene_path = ""
    npc_visit_count = {}
    observed_clues = PackedStringArray()
    scene_positions = {}

func mark_npc_met(npc_id: String) -> void:
    if not met_npcs.has(npc_id):
        met_npcs.append(npc_id)

func mark_dialogue_completed(dialogue_id: String) -> void:
    if not completed_dialogues.has(dialogue_id):
        completed_dialogues.append(dialogue_id)

func increment_visit_count(dialogue_id: String) -> int:
    var cur: int = int(npc_visit_count.get(dialogue_id, 0))
    npc_visit_count[dialogue_id] = cur + 1
    return cur + 1

func get_visit_count(dialogue_id: String) -> int:
    return int(npc_visit_count.get(dialogue_id, 0))

# P4 final · 4.9：环境线索观察
func mark_observed(clue_id: String) -> bool:
    if observed_clues.has(clue_id):
        return false
    observed_clues.append(clue_id)
    return true

func has_observed(clue_id: String) -> bool:
    return observed_clues.has(clue_id)

func observed_clue_count() -> int:
    return observed_clues.size()

# P5.5：跨场景玩家位置持久化
func set_scene_position(scene_path: String, pos: Vector2) -> void:
    if scene_path == "":
        return
    scene_positions[scene_path] = pos

func get_scene_position(scene_path: String) -> Vector2:
    if not scene_positions.has(scene_path):
        return Vector2.ZERO
    return scene_positions[scene_path]

func has_scene_position(scene_path: String) -> bool:
    return scene_positions.has(scene_path)

func add_dao(amount: int) -> void:
    dao_count += amount

func advance_cycle() -> void:
    current_cycle += 1
    current_day = 1

func to_dict() -> Dictionary:
    # scene_positions: 转 {scene_path: {x, y}} 以便 ConfigFile 跨平台序列化
    var sp_serialized: Dictionary = {}
    for k in scene_positions.keys():
        var v: Vector2 = scene_positions[k]
        sp_serialized[k] = {"x": v.x, "y": v.y}
    return {
        "current_cycle": current_cycle,
        "current_day": current_day,
        "player_position": {"x": player_position.x, "y": player_position.y},
        "met_npcs": Array(met_npcs),
        "completed_dialogues": Array(completed_dialogues),
        "dao_count": dao_count,
        "current_scene_path": current_scene_path,
        "npc_visit_count": npc_visit_count.duplicate(),
        "observed_clues": Array(observed_clues),
        "scene_positions": sp_serialized,
    }

func from_dict(data: Dictionary) -> void:
    current_cycle = int(data.get("current_cycle", 1))
    current_day = int(data.get("current_day", 1))
    var pos: Dictionary = data.get("player_position", {"x": 0, "y": 0})
    player_position = Vector2(float(pos.get("x", 0)), float(pos.get("y", 0)))
    met_npcs = PackedStringArray(data.get("met_npcs", []))
    completed_dialogues = PackedStringArray(data.get("completed_dialogues", []))
    dao_count = int(data.get("dao_count", 0))
    current_scene_path = String(data.get("current_scene_path", ""))
    var visit_data = data.get("npc_visit_count", {})
    npc_visit_count = {} if not (visit_data is Dictionary) else (visit_data as Dictionary).duplicate()
    observed_clues = PackedStringArray(data.get("observed_clues", []))
    # scene_positions：从 {scene_path: {x, y}} 还原成 Dictionary[String, Vector2]
    scene_positions = {}
    var sp_data = data.get("scene_positions", {})
    if sp_data is Dictionary:
        for k in (sp_data as Dictionary).keys():
            var entry = sp_data[k]
            if entry is Dictionary:
                scene_positions[k] = Vector2(float(entry.get("x", 0)), float(entry.get("y", 0)))
