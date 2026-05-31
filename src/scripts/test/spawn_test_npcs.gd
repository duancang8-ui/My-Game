class_name SpawnTestNPCs
extends Node

# P1 性能基线测试：生成 N 个静态 NPC，用于 FPS 测试 + Y-sort 验证
# 启用方式：在 Inspector 把 enabled 改为 true，或在脚本中改默认值

@export var enabled: bool = true                                ## P1 阶段默认开启，测完可关闭
@export var npc_count: int = 30
@export var spawn_radius: float = 400.0
@export var spawn_center: Vector2 = Vector2(320, 320)           ## 围绕玩家初始位置
@export var ysort_container_path: NodePath = NodePath("../YSortContainer")

const NPC_TEXTURE: Texture2D = preload("res://src/assets/characters/player_placeholder.png")

func _ready() -> void:
    if not enabled:
        return
    var container: Node2D = get_node_or_null(ysort_container_path) as Node2D
    if container == null:
        push_error("SpawnTestNPCs: YSortContainer not found at " + str(ysort_container_path))
        return
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.randomize()
    for i in range(npc_count):
        var npc: Sprite2D = Sprite2D.new()
        npc.texture = NPC_TEXTURE
        npc.name = "PerfNPC_%d" % i
        var angle: float = (float(i) / float(npc_count)) * TAU
        # 椭圆排列（长轴横向，短轴 50% 高度），契合等距视觉
        npc.position = spawn_center + Vector2(cos(angle), sin(angle) * 0.5) * spawn_radius
        npc.modulate = Color(rng.randf(), rng.randf(), rng.randf(), 1.0)
        container.add_child(npc)
    print("SpawnTestNPCs: spawned ", npc_count, " perf NPCs around ", spawn_center)
