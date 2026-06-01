# P5：场景切换系统 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans.

**Goal**：让玩家能从一个场景切换到另一个（面试房间 ↔ 道城），切换时有黑屏淡入淡出过渡，并且 GameState 在切换中保持持久化。这是后续多关卡 / 多场景叙事的基础设施。

**Scope**：
- ✅ `SceneManager` autoload + 黑屏 fade UI
- ✅ `GameState.current_scene_path` 字段
- ✅ `Interactable.Type.SCENE_CHANGE` 实装（target_scene_path 字段 + 触发后调 SceneManager）
- ✅ 简易 `daocheng_main.tscn` 占位场景（不是完整道城，只是"能进能出"验证切换）
- ✅ 双向"门"：InterviewRoom ⇄ DaoCheng
- ✅ 玩家位置在切换中保留（场景内部位置，不跨场景）

**Architecture**：
- **SceneManager autoload**：单例，管理切换状态机（IDLE / FADING_OUT / LOADING / FADING_IN）
- **FadeOverlay**：内置黑色 ColorRect，控制 alpha 实现淡入淡出
- **Interactable SCENE_CHANGE**：携带 `target_scene_path`，触发后调 `SceneManager.change_to(...)`
- **场景树切换**：用 `get_tree().change_scene_to_packed()`，不重启项目

**Tech Stack**：复用既有 Toast / GameState / Interactable / Tween。

**预估**：4-5 个 task。

---

## File Structure

```
src/
├─ scripts/
│  └─ scene/
│     └─ scene_manager.gd                  # autoload
└─ scenes/
   └─ world/
      └─ daocheng_main.tscn               # 占位道城场景

src/scripts/save/game_state.gd            # 修改：加 current_scene_path 字段
src/scripts/interaction/interactable.gd   # 修改：scene_path 字段
src/scripts/dialogue/dialogue_controller.gd 或新 SceneTriggerController  # 处理 SCENE_CHANGE 触发
project.godot                             # 注册 SceneManager autoload

tests/unit/
└─ test_scene_manager.gd                  # 基础测试（API 调用 + 状态切换）
```

---

## Task 1：SceneManager autoload + Fade UI

**Files**:
- Create: `src/scripts/scene/scene_manager.gd`
- Create: `tests/unit/test_scene_manager.gd`
- Modify: `project.godot`（注册 autoload）

**说明**：
- SceneManager 是 Node（autoload），自带一个 CanvasLayer 子节点用于全屏黑色 overlay
- API：`change_to(scene_path: String, fade_duration: float = 0.4) -> void`
- 状态机：IDLE → FADING_OUT (0.4s 黑屏淡入) → LOADING (切换场景) → FADING_IN (黑屏淡出) → IDLE
- 发信号：`scene_change_started(target_path)` / `scene_change_finished()`

- [ ] 1.1 创建 scene_manager.gd
- [ ] 1.2 写测试（不真实切换，仅测 API 状态）
- [ ] 1.3 注册 autoload
- [ ] 1.4 commit

---

## Task 2：GameState.current_scene_path + 测试

**Files**:
- Modify: `src/scripts/save/game_state.gd`
- Modify: `tests/unit/test_game_state.gd`

- [ ] 2.1 加字段 + to_dict/from_dict + reset 处理
- [ ] 2.2 测试 roundtrip
- [ ] 2.3 commit

---

## Task 3：Interactable SCENE_CHANGE 实装

**Files**:
- Modify: `src/scripts/interaction/interactable.gd`（已有 SCENE_CHANGE 枚举值，加 scene_path 字段）

**说明**：
- 加 `@export var scene_path: String = ""` 字段
- 一个独立的 `SceneTriggerController`（或在某个 orchestrator 处理）监听 Interactable.interaction_triggered，type==SCENE_CHANGE 时调 SceneManager.change_to(scene_path)

为减少耦合，我新建一个 `SceneTriggerController` autoload-like 节点，每个有 Interactable 触发场景切换的关卡都引用它（或它自己 connect_all）。

实际更简单：让 SceneManager 自身在场景里**自动 connect** 所有 SCENE_CHANGE Interactable。

- [ ] 3.1 加 scene_path 字段
- [ ] 3.2 SceneManager._ready 监听 scene tree 节点添加，扫描 Interactable
- [ ] 3.3 commit

---

## Task 4：DaoCheng 占位场景

**Files**:
- Create: `src/scenes/world/daocheng_main.tscn`

**说明**：
- 简单的 20×20 等距地图（复用 WorldBuilder）
- 玩家 + 一扇返回门（Interactable SCENE_CHANGE，target = interview_room.tscn）
- 加一些视觉差异（红色危险区在不同位置）让玩家明确"我在不同场景"

- [ ] 4.1 创建 daocheng_main.tscn
- [ ] 4.2 commit

---

## Task 5：interview_room 加出口门 + 集成测试

**Files**:
- Modify: `src/scenes/world/interview_room.tscn`
- 写 E2E 验证脚本

**说明**：
- 在 interview_room 的某个角落（比如左下）加一扇"门"Interactable
- 但只在玩家**胜利后**或"过场已完成"后才显示？P5 简化：胜利后才出现（手动设置初始隐藏）

更简单的处理：**胜利后** 自动显示一扇门。失败状态下没有门。

- [ ] 5.1 加门节点（默认隐藏）
- [ ] 5.2 LiarGameOrchestrator WIN 处理时显示门
- [ ] 5.3 E2E 验证：玩家 vote 对 → 门出现 → 互动 → 切到 daocheng → 互动门 → 回 interview_room
- [ ] 5.4 commit

---

## Task 6：报告 + tag

- [ ] 6.1 写 P5 报告
- [ ] 6.2 更新 README
- [ ] 6.3 commit + tag v0.5-p5-complete

---

## Self-Review

### Spec 覆盖
对应 spec 中"多层枢纽"（§3）和"周期重置房"（§3.1）。P5 完成后，玩家可以真正在"面试房间"和"道城"之间穿梭。

### Type consistency
- `SceneManager.change_to(scene_path: String, fade_duration: float)` ✅
- `GameState.current_scene_path: String` ✅
- `Interactable.scene_path: String` ✅
