class_name WorldBuilder
extends Node

# 程序化生成 20x20 测试地图：默认灰色路面 + 中心 4x4 暗红危险区
# 替代 GUI 手动铺图，方便重复构建和测试
# 仅 P1 技术验证用，后续真实地图由 LevelDesigner 系统处理

@export var tilemap_layer_path: NodePath = NodePath("../Ground")
@export var map_size: Vector2i = Vector2i(20, 20)
@export var danger_zone_min: Vector2i = Vector2i(8, 8)
@export var danger_zone_max: Vector2i = Vector2i(12, 12)

# atlas 列对应瓦片含义（详见 iso_tiles_placeholder.png）
const ATLAS_GROUND: Vector2i = Vector2i(0, 0)   # 灰路面
const ATLAS_DANGER: Vector2i = Vector2i(1, 0)   # 暗红危险
const ATLAS_GRASS: Vector2i  = Vector2i(2, 0)   # 暗绿草地（暂未使用）
const ATLAS_WATER: Vector2i  = Vector2i(3, 0)   # 暗蓝水（暂未使用）
const SOURCE_ID: int = 0

func _ready() -> void:
    var layer: TileMapLayer = get_node_or_null(tilemap_layer_path) as TileMapLayer
    if layer == null:
        push_error("WorldBuilder: TileMapLayer not found at " + str(tilemap_layer_path))
        return
    _build_test_map(layer)

func _build_test_map(layer: TileMapLayer) -> void:
    for x in range(map_size.x):
        for y in range(map_size.y):
            var atlas: Vector2i = ATLAS_GROUND
            if _is_in_danger_zone(x, y):
                atlas = ATLAS_DANGER
            layer.set_cell(Vector2i(x, y), SOURCE_ID, atlas)

func _is_in_danger_zone(x: int, y: int) -> bool:
    return x >= danger_zone_min.x and x < danger_zone_max.x \
        and y >= danger_zone_min.y and y < danger_zone_max.y
