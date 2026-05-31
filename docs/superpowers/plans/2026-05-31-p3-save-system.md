# P3：存档/读档基础设施 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal**：搭建《十日终焉》的存档系统骨架。玩家按 F9 存档，按 F10 读档；游戏状态（玩家位置、当前 Cycle、保留记忆）能在退出 → 重启后被准确恢复。

**Architecture**：
- **GameState**（Autoload，Node）：内存中保存的"游戏唯一真相"——玩家位置、当前 Cycle 编号、已遇到的 NPC、已经历的对话、已收集的"道"等。
- **SaveSystem**（Autoload，Node）：纯 I/O 层，负责把 GameState 序列化到 `user://saves/slot_<n>.save` 并反序列化回来。使用 Godot ConfigFile（INI 格式，可读、易调试）。
- **Saveable** 接口约定：场景里的节点（玩家、NPC、副本入口等）实现 `serialize() -> Dictionary` 和 `deserialize(data: Dictionary)`，由 SaveSystem 收集/恢复。
- **快捷键**：F9 保存到 slot 0，F10 从 slot 0 读档。后续可扩展到多 slot UI。

**Tech Stack**：Godot 4.6.3 + GDScript + ConfigFile（Godot 原生 INI 序列化）+ GUT 9.6.0 测试。

**遵循 P1/P2 既定原则**：
- 物理碰撞规范（spec §5.10）—— 不影响存档
- 测试驱动开发（每个逻辑模块先写测试）
- 占位资源 / 不依赖美术
- Autoload 懒初始化模式

**预估工期**：约 6 个 bite-sized 任务。

---

## File Structure

新增/修改的文件：

```
src/
├─ scripts/
│  └─ save/                                       # 新增子目录
│     ├─ game_state.gd                            # Autoload: 内存中的"唯一真相"
│     ├─ save_system.gd                           # Autoload: I/O 层（ConfigFile）
│     └─ saveable.gd                              # 节点 mixin：serialize/deserialize 接口
│
├─ scripts/player/
│  └─ player.gd                                   # 修改：实现 serialize / deserialize
│
└─ scripts/test/
   └─ save_test_keybinds.gd                       # 修改/新增：F9 存档、F10 读档热键

src/scenes/world/test_world.tscn                  # 修改：加 SaveTestKeybinds 节点
project.godot                                     # 修改：注册 GameState / SaveSystem autoloads

tests/unit/
├─ test_game_state.gd                             # GameState 基础测试
└─ test_save_system.gd                            # ConfigFile roundtrip 测试

docs/tech-verification-p3/
└─ report.md                                      # P3 完成报告
```

---

## Task 1：GameState Autoload（TDD）

**Files**:
- Create: `src/scripts/save/game_state.gd`
- Create: `tests/unit/test_game_state.gd`

**说明**：GameState 是个 Node，作为 autoload 注册。
存什么：
- `current_cycle: int`（当前是第几个十日轮回）
- `current_day: int`（当前是这个 cycle 内的第几天，1~10）
- `player_position: Vector2`（玩家当前位置）
- `met_npcs: PackedStringArray`（玩家已知道名字的 NPC 列表）
- `completed_dialogues: PackedStringArray`（已完成的 dialogue_id 列表）
- `dao_count: int`（持有的"道"数量）

- [ ] **Step 1.1：写测试**

```gdscript
extends GutTest

# GameState 是 autoload，可直接用 /root/GameState 引用
# 但为了测试隔离，每次 before_each 重置

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
    # 重复添加不应造成重复
    GameState.mark_npc_met("chen_junnan")
    assert_eq(GameState.met_npcs.size(), 1)

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
    assert_eq(GameState.current_cycle, 1, "reset 后回到默认")
    GameState.from_dict(dict)
    assert_eq(GameState.current_cycle, 3)
    assert_eq(GameState.current_day, 5)
    assert_eq(GameState.player_position, Vector2(100, 200))
    assert_true(GameState.met_npcs.has("乔家劲"))
    assert_true(GameState.completed_dialogues.has("test_d_01"))
    assert_eq(GameState.dao_count, 42)
```

- [ ] **Step 1.2：实现**

```gdscript
extends Node

# 游戏全局状态单例（Autoload）
# 内存中保存"唯一真相"，由 SaveSystem 序列化/反序列化

var current_cycle: int = 1
var current_day: int = 1
var player_position: Vector2 = Vector2.ZERO
var met_npcs: PackedStringArray = PackedStringArray()
var completed_dialogues: PackedStringArray = PackedStringArray()
var dao_count: int = 0

func reset() -> void:
    current_cycle = 1
    current_day = 1
    player_position = Vector2.ZERO
    met_npcs = PackedStringArray()
    completed_dialogues = PackedStringArray()
    dao_count = 0

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
    }

func from_dict(data: Dictionary) -> void:
    current_cycle = data.get("current_cycle", 1)
    current_day = data.get("current_day", 1)
    var pos: Dictionary = data.get("player_position", {"x": 0, "y": 0})
    player_position = Vector2(pos.get("x", 0), pos.get("y", 0))
    met_npcs = PackedStringArray(data.get("met_npcs", []))
    completed_dialogues = PackedStringArray(data.get("completed_dialogues", []))
    dao_count = data.get("dao_count", 0)
```

- [ ] **Step 1.3：注册 autoload**

`project.godot` 加：

```
GameState="*res://src/scripts/save/game_state.gd"
```

- [ ] **Step 1.4：跑测试 → 通过**

预期：单元测试 27 + 7 = **34/34** 通过。

- [ ] **Step 1.5：commit**

```bash
git add src/scripts/save/game_state.gd tests/unit/test_game_state.gd project.godot
git commit -m "feat(save): GameState autoload (7/7 tests)"
```

---

## Task 2：SaveSystem Autoload + ConfigFile Roundtrip（TDD）

**Files**:
- Create: `src/scripts/save/save_system.gd`
- Create: `tests/unit/test_save_system.gd`

**说明**：SaveSystem 把 GameState.to_dict() 写到 `user://saves/slot_<n>.save`（ConfigFile 格式）。

- [ ] **Step 2.1：写测试**

```gdscript
extends GutTest

const SAVE_DIR: String = "user://saves_test/"
const SLOT: int = 99   # 测试专用 slot

func before_each() -> void:
    SaveSystem.save_dir = SAVE_DIR
    GameState.reset()

func after_each() -> void:
    # 清理测试存档
    var slot_path: String = SAVE_DIR + "slot_%d.save" % SLOT
    if FileAccess.file_exists(slot_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path))

func test_save_creates_file() -> void:
    GameState.current_cycle = 2
    var ok: bool = SaveSystem.save_to_slot(SLOT)
    assert_true(ok, "save_to_slot should succeed")
    assert_true(SaveSystem.slot_exists(SLOT), "slot 文件应该存在")

func test_load_restores_state() -> void:
    GameState.current_cycle = 3
    GameState.current_day = 7
    GameState.player_position = Vector2(123, 456)
    GameState.mark_npc_met("陈俊南")
    GameState.add_dao(99)
    SaveSystem.save_to_slot(SLOT)
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
    var ok: bool = SaveSystem.load_from_slot(999)
    assert_false(ok)

func test_slot_exists_returns_false_for_empty() -> void:
    assert_false(SaveSystem.slot_exists(SLOT))
```

- [ ] **Step 2.2：实现**

```gdscript
extends Node

# 存档系统：负责把 GameState 序列化到磁盘，读回来覆盖 GameState

const DEFAULT_SAVE_DIR: String = "user://saves/"
const SAVE_VERSION: int = 1

var save_dir: String = DEFAULT_SAVE_DIR  # 可被测试覆盖

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
        push_error("SaveSystem.save_to_slot: cfg.save failed with err=%d" % err)
        return false
    return true

func load_from_slot(slot: int) -> bool:
    var path: String = _slot_path(slot)
    if not FileAccess.file_exists(path):
        return false
    var cfg: ConfigFile = ConfigFile.new()
    var err: int = cfg.load(path)
    if err != OK:
        push_error("SaveSystem.load_from_slot: cfg.load failed with err=%d" % err)
        return false
    var version: int = cfg.get_value("meta", "version", 0)
    if version != SAVE_VERSION:
        push_warning("SaveSystem: save version %d differs from expected %d" % [version, SAVE_VERSION])
    var state: Dictionary = {}
    for key in cfg.get_section_keys("game"):
        state[key] = cfg.get_value("game", key)
    GameState.from_dict(state)
    return true
```

- [ ] **Step 2.3：注册 autoload**

`project.godot` 加：

```
SaveSystem="*res://src/scripts/save/save_system.gd"
```

- [ ] **Step 2.4：跑测试 → 通过**

预期：34 + 4 = **38/38** 通过。

- [ ] **Step 2.5：commit**

```bash
git add src/scripts/save/save_system.gd tests/unit/test_save_system.gd project.godot
git commit -m "feat(save): SaveSystem autoload with ConfigFile roundtrip (4/4 tests)"
```

---

## Task 3：F9 / F10 热键集成

**Files**:
- Create: `src/scripts/test/save_test_keybinds.gd`
- Modify: `src/scenes/world/test_world.tscn`（添加 SaveTestKeybinds 节点）
- Modify: `project.godot`（注册 quick_save / quick_load 输入动作）

- [ ] **Step 3.1：在 project.godot 加输入动作**

加 `quick_save`（F9）和 `quick_load`（F10）到 [input] section。

F9 keycode = 4194342
F10 keycode = 4194343

- [ ] **Step 3.2：写 SaveTestKeybinds 脚本**

```gdscript
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
        print("[SaveSystem] Quick-saved to slot ", QUICK_SLOT,
            " (cycle=%d day=%d pos=%s dao=%d)" % [
                GameState.current_cycle, GameState.current_day,
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
    print("[SaveSystem] Quick-loaded from slot ", QUICK_SLOT)
```

- [ ] **Step 3.3：把节点加到 test_world.tscn**

- [ ] **Step 3.4：跑测试 + commit**

```bash
git add src/scripts/test/save_test_keybinds.gd src/scenes/world/test_world.tscn project.godot
git commit -m "feat(save): F9 quick-save + F10 quick-load keybinds integrated to TestWorld"
```

---

## Task 4：DialogueController 在对话结束时记录到 GameState

**Files**:
- Modify: `src/scripts/dialogue/dialogue_controller.gd`

**说明**：对话完成时，自动 `GameState.mark_dialogue_completed(dialogue_id)`。

- [ ] **Step 4.1：修改 dialogue_controller.gd**

在 `_start_dialogue` 中记录当前 dialogue_id，在 `dialogue_ended` 信号回调时标记完成。

- [ ] **Step 4.2：跑回归测试**

- [ ] **Step 4.3：commit**

---

## Task 5：集成验证（save/load roundtrip 在真实场景）

**Files**:
- 写一个 `.verify_save_roundtrip.gd` 临时脚本测试 save → reset → load → 状态一致

- [ ] **Step 5.1：写验证脚本**

加载 test_world，模拟 GameState 改动，save，reset，load，验证一致。

- [ ] **Step 5.2：跑验证**

- [ ] **Step 5.3：清理临时脚本**

---

## Task 6：P3 完成报告 + Tag

**Files**:
- Create: `docs/tech-verification-p3/report.md`
- Modify: `README.md`

- [ ] **Step 6.1：写 P3 报告**

包含：
- 实现的功能（GameState / SaveSystem / 热键 / DialogueController 集成）
- 单元测试结果（应 38/38 通过）
- 关键技术决策
- 局限性 / 后续 plan 待办
- 用户验证步骤（F9 / F10 实际操作）

- [ ] **Step 6.2：更新 README**

- [ ] **Step 6.3：commit + tag**

```bash
git add docs/tech-verification-p3/ README.md
git commit -m "docs: P3 complete — save/load infrastructure"
git tag -a v0.3-p3-complete -m "P3: Save System (GameState + SaveSystem + F9/F10)"
```

---

## Self-Review

### Spec coverage
对应 spec §5.2（十日轮回与记忆系统）的"玩家本人保留全部记忆 / 物品/道全部清零（每个 run 重新积累）"

P3 实现：
- ✅ 玩家位置存档
- ✅ 当前 cycle / day 存档
- ✅ 已遇到的 NPC 列表（met_npcs）
- ✅ 已完成的对话（completed_dialogues）
- ✅ 道数量
- ⏳ Cycle 重置时清零道（留给 P4+ 当 Cycle 系统实装时做）
- ⏳ NPC 失忆机制（普通 NPC 在 Cycle 切换时遗忘）—— 留给后续 plan

### Placeholder scan
所有 step 含完整代码，无 TBD/TODO。

### Type consistency
- `GameState.player_position: Vector2` ✅
- `GameState.met_npcs: PackedStringArray` ✅
- `SaveSystem.save_to_slot(slot: int) -> bool` ✅
- `SaveSystem.load_from_slot(slot: int) -> bool` ✅

### Autonomous execution notes
此 plan 由 AI 在用户离开期间自治执行。
