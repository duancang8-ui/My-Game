# P5.5 · 跨场景玩家状态持久化

**触发**：P4 完结后，玩家在 面试房间 / 玉城 / 雨地 之间频繁穿梭，目前每次切场都从场景默认位置重生 —— 进度（道币、笔记本、观察点等）已自动保存，但**位置**会重置，玩家体验割裂。

**目标**：玩家无论怎么进出场景，回到同一场景时回到上次离开的位置。

**Scope**：纯工程改造，无新对话/玩法。

---

## 设计

### 数据
`GameState` 新增：
```gdscript
var scene_positions: Dictionary = {}   # scene_file_path → Vector2
```

helpers：
- `set_scene_position(scene_path, pos)` — 写入并去重
- `get_scene_position(scene_path) -> Vector2` — 返回 `Vector2.ZERO` 表示没记录
- `has_scene_position(scene_path) -> bool`
- 序列化：to_dict/from_dict 把 dict 转成 `{path: [x, y]}` 二级结构

### 写入时机（SceneManager）
`change_to(scene_path)` 在 fade_out 完成、调 `change_scene_to_file` **之前**：
```gdscript
var current_scene := get_tree().current_scene.scene_file_path
var p := get_tree().get_first_node_in_group("player")
if p != null and current_scene != "":
    GameState.set_scene_position(current_scene, p.position)
```

### 读出时机（Player）
`Player.gd._ready()` 加：
```gdscript
add_to_group("player")
var scene_path := get_tree().current_scene.scene_file_path
if GameState != null and GameState.has_scene_position(scene_path):
    position = GameState.get_scene_position(scene_path)
```

注意：场景的 .tscn 文件里 Player 节点本来配置了 `position = Vector2(...)`。我们只在**有存档位置时才覆盖**，没有存档的首次进入仍按 .tscn 默认位置。

### 与 SaveSystem 的关系
- scene_positions 已经被 to_dict/from_dict 处理 → F9 / F10 自动包含
- GameState.player_position（已存在）继续保留作"最后位置"摘要

### 已知 corner case
- 玩家在面试房间死亡 retry → orchestrator 主动 `player.position = _player_initial_position`，会覆盖存档位置 → 在 retry 后下次切场又会被存进去（正确行为）
- 玩家首次进入新场景 → has_scene_position == false → 用 .tscn 默认位置（正确）
- 删除/重命名场景文件 → 旧 key 留在 dict 里但不影响（无害垃圾，可日后清理）

---

## Tasks

1. **GameState** 扩展（小工，5 行代码）+ 序列化
2. **Player.gd** _ready 加 add_to_group + 读位置
3. **SceneManager.change_to** 调用前快照
4. **测试**：3 个新 case
   - `test_scene_position_set_get`
   - `test_scene_position_round_trip_in_dict`
   - `test_player_restores_from_game_state_on_ready`（需要场景化模拟，可暂时跳过运行时部分）
5. **Smoke playtest**：玩家 InterviewRoom → 雨后春笋（同房间不算，那是 phase 2）→ 玉城 → 雨地 → 玉城 → 位置应该回到上次离开
6. commit + tag v0.5.5

## 风险

- 玩家位置如果在 `set_physics_process(false)` 下被 orchestrator 改了，再切场时存的是改后位置 —— OK 这就是我们想要的
- Player 节点必须能正确加入 "player" group。Player.tscn 也可以在节点配置里 `groups = ["player"]`，但用代码 add_to_group 更稳（无需改 .tscn）

## 工作量
约 30 分钟净开发，含测试。
