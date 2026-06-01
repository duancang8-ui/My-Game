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

func reset() -> void:
    current_cycle = 1
    current_day = 1
    player_position = Vector2.ZERO
    met_npcs = PackedStringArray()
    completed_dialogues = PackedStringArray()
    dao_count = 0
    current_scene_path = ""

func mark_npc_met(npc_id: String) -> void:
    if not met_npcs.has(npc_id):
        met_npcs.append(npc_id)

func mark_dialogue_completed(dialogue_id: String) -> void:
    if not completed_dialogues.has(dialogue_id):
        completed_dialogues.append(dialogue_id)

func add_dao(amount: int) -> void:
    dao_count += amount

func advance_cycle() -> void:
    current_cycle += 1
    current_day = 1

func to_dict() -> Dictionary:
    return {
        "current_cycle": current_cycle,
        "current_day": current_day,
        "player_position": {"x": player_position.x, "y": player_position.y},
        "met_npcs": Array(met_npcs),
        "completed_dialogues": Array(completed_dialogues),
        "dao_count": dao_count,
        "current_scene_path": current_scene_path,
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
