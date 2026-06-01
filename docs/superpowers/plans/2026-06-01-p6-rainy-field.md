# P6：「雨后春笋」生肖游戏关卡 实施计划

> 对应 spec §3.3 / 附录 D.4：人狗游戏，Ch 13~16 出现。
> 这是项目的**第二个**生肖游戏关卡，用于验证系统对**不同关卡机制**的支持。

**Goal**：实现一个**时间反应类**关卡（区别于说谎者的"社交推理类"），证明项目架构对多种玩法的通用性。玩家在限定时间内按 E **旋转桌面**累积进度，达到目标即可"长出盾牌"防御鱼叉攻击。

**Architecture（MVS 精简版）**：
- 核心循环：按 E → 计数 +1 → 满 100 胜利 / 时间到失败
- 复用：ResultScreen、Toast、SceneManager、Interactable、对话系统
- **不复用**：LiarGameController（说谎者特有），新写 `RotateGameController`
- 新场景 `rainy_field.tscn`，从 DaoCheng 进入

**Scope（精简）**：
- ✅ 新场景：雨地 + 一张桌子 + 玩家
- ✅ 核心机制：按 E 旋转桌面（节奏点击）
- ✅ 倒计时 + 计数 HUD
- ✅ 胜利 / 失败 ResultScreen
- ✅ 入口：在 DaoCheng 加一扇"通往雨地"的蓝色门
- ❌ **不做**：原作的"团队分工""鱼叉飞射特效"（需美术）
- ❌ **不做**：QTE 节奏点判定（"踩节奏"）—— P6.5 升级再考虑

**预估**：约 6 个 task。

---

## File Structure

```
src/
├─ scenes/
│  └─ world/
│     └─ rainy_field.tscn                    # 新主场景
├─ scripts/
│  ├─ rotate_game/                           # 新子目录
│  │  ├─ rotate_game_controller.gd          # 关卡核心（无 UI 依赖）
│  │  ├─ rotate_game_orchestrator.gd        # 编排：玩家输入 + UI + 结算
│  │  └─ rainy_field_builder.gd             # 场景生成器
│  └─ ui/
│     └─ rotate_game_hud.gd                 # 关卡专用 HUD（进度条+倒计时）

src/scripts/test/daocheng_builder.gd       # 修改：加"进入雨地"门
project.godot                              # 不改

tests/unit/
└─ test_rotate_game_controller.gd          # 关卡逻辑测试
```

---

## Task 1：RotateGameController + 测试

**Files**:
- Create: `src/scripts/rotate_game/rotate_game_controller.gd`
- Create: `tests/unit/test_rotate_game_controller.gd`

**核心 API**：
```gdscript
@export var target_rotations: int = 100    ## 需要的旋转次数
@export var time_limit: float = 30.0       ## 限定时间（秒）

enum State { READY, PLAYING, WIN, LOSE }
enum Result { NONE, WIN, LOSE }

var state: int = State.READY
var rotations: int = 0
var time_left: float = 30.0
var last_result: int = Result.NONE

signal rotated(current: int, target: int)
signal time_changed(time_left: float)
signal game_ended(result: int)

func start_game() -> void
func add_rotation() -> void   ## 玩家按 E 触发
func _process(delta: float) -> void   ## 自动 tick 倒计时
```

**测试覆盖**：
1. 初始状态 READY
2. start_game → PLAYING
3. add_rotation 累加 + emit signal
4. 达到 target → WIN + game_ended emit
5. 时间归零 → LOSE
6. 已结束时 add_rotation 无效
7. reset

- [ ] 1.1 写测试（7 个）
- [ ] 1.2 实现
- [ ] 1.3 跑测试 → 通过
- [ ] 1.4 commit

---

## Task 2：RotateGameHud — 进度条 + 倒计时

**Files**:
- Create: `src/scripts/ui/rotate_game_hud.gd`

**说明**：
- CanvasLayer 顶部 / 中部
- 一个进度条（Godot ProgressBar）+ "X / 100" 文字
- 一个倒计时数字（大字，剩 5 秒变红）
- 复用 P3.5 9-slice 风格

- [ ] 2.1 实现
- [ ] 2.2 commit

---

## Task 3：RotateGameOrchestrator + 入场过场

**Files**:
- Create: `src/scripts/rotate_game/rotate_game_orchestrator.gd`
- Modify: `src/scripts/dialogue/dialogue_database.gd`（加 1 段人狗规则讲解）

**说明**：
- 玩家进入雨地 → 自动播放过场（人狗"汪汪叫"出场宣布规则）
- 规则讲完后：解锁玩家 + 启动 RotateGameController + 显示 HUD
- 玩家按 E（interact）触发 add_rotation
- WIN → 胜利 ResultScreen + spawn 返回门（回 DaoCheng）
- LOSE → 失败 ResultScreen + "重新开始 / 读档"

- [ ] 3.1 写 1 段人狗规则对话
- [ ] 3.2 实现 orchestrator
- [ ] 3.3 commit

---

## Task 4：RainyFieldBuilder + 场景

**Files**:
- Create: `src/scripts/rotate_game/rainy_field_builder.gd`
- Create: `src/scenes/world/rainy_field.tscn`

**说明**：
- 12×8 等距地图（用 TILE_WATER 蓝色瓦片代表"湿地"）
- 中央一张大桌子（占位贴图）+ 一个"旋转标记"（黄球作为玩家交互点）
- 玩家初始位置：桌子附近
- 一只人狗（戴狗面具，棕色小人占位）
- 返回门（暂时隐藏，胜利后 spawn）

- [ ] 4.1 创建 builder
- [ ] 4.2 创建 tscn
- [ ] 4.3 commit

---

## Task 5：从 DaoCheng 进入雨地的入口

**Files**:
- Modify: `src/scripts/test/daocheng_builder.gd`（加第二扇门：通往雨地）

**说明**：
- DaoCheng 已有"返回面试房间"门
- 现在加一扇"通往雨地"门（红色光球，target = rainy_field.tscn）
- 这样玩家可以：interview → daocheng → rainy → daocheng → interview

- [ ] 5.1 加门
- [ ] 5.2 测试场景间穿梭
- [ ] 5.3 commit

---

## Task 6：P6 完成报告 + Tag

- [ ] 6.1 写报告（spec 覆盖 / 决策 / 测试 / 局限）
- [ ] 6.2 更新 README
- [ ] 6.3 commit + tag v0.6-p6-complete

---

## Self-Review

### Spec 覆盖
- ✅ 雨后春笋核心机制（按 E 旋转累积，时间限制）
- ⏳ 原作"团队分工"留作 P6.5（需要 NPC AI）
- ⏳ 鱼叉特效留作美术 sprint
- ⏳ 真实台词留作原作 zip 到位

### 通用性验证
P6 同时也是**关键测试**：验证 P1-P5 系统能否支撑"完全不同机制"的关卡。
- ResultScreen / Toast / SceneManager / Interactable / CutsceneController / DialogueDatabase 都被复用
- 新增的只有：RotateGameController + RotateGameHud + RainyFieldBuilder + RotateGameOrchestrator（即关卡特有逻辑）

### Type consistency
- `RotateGameController.target_rotations: int = 100` ✅
- `RotateGameController.add_rotation()` ✅
- `RotateGameController.game_ended(result: int)` signal ✅
- 与 `LiarGameController` API 风格一致（reset, state machine, signal）
