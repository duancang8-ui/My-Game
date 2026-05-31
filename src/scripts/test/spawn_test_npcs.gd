class_name SpawnTestNPCs
extends Node

# P1 性能基线测试：生成 N 个 NPC（含碰撞体），用于 FPS 测试 + Y-sort + 碰撞验证
# NPC 用 CharacterBody2D（不动但能阻挡），后续 P2 NPC AI 阶段可直接复用此类型加移动逻辑
# 启用方式：在 Inspector 把 enabled 改为 true，或在脚本中改默认值

@export var enabled: bool = true                                ## P1 阶段默认开启，测完可关闭
@export var npc_count: int = 30
@export var spawn_radius: float = 400.0
@export var spawn_center: Vector2 = Vector2(320, 320)           ## 围绕玩家初始位置
@export var ysort_container_path: NodePath = NodePath("../YSortContainer")

const NPC_TEXTURE: Texture2D = preload("res://src/assets/characters/player_placeholder.png")
const NPC_COLLISION_RADIUS: float = 8.0
const NPC_COLLISION_OFFSET: Vector2 = Vector2(0, 14)   ## 圆心放在 sprite 脚部，避免"撞头顶"的怪异感

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
        var npc: CharacterBody2D = CharacterBody2D.new()
        npc.name = "PerfNPC_%d" % i
        var angle: float = (float(i) / float(npc_count)) * TAU
        # 椭圆排列（长轴横向，短轴 50% 高度），契合等距视觉
        npc.position = spawn_center + Vector2(cos(angle), sin(angle) * 0.5) * spawn_radius

        var sprite: Sprite2D = Sprite2D.new()
        sprite.texture = NPC_TEXTURE
        sprite.modulate = Color(rng.randf(), rng.randf(), rng.randf(), 1.0)
        npc.add_child(sprite)

        var collision: CollisionShape2D = CollisionShape2D.new()
        var shape: CircleShape2D = CircleShape2D.new()
        shape.radius = NPC_COLLISION_RADIUS
        collision.shape = shape
        collision.position = NPC_COLLISION_OFFSET
        npc.add_child(collision)

        container.add_child(npc)
    print("SpawnTestNPCs: spawned ", npc_count, " perf NPCs (with collision) around ", spawn_center)
