# P4.6 · 说谎者关卡深化（第一波）

**目标**：把「说谎者」从"按 E 跟 9 人聊一遍 → 看人羊暗示 → 投票"的纯流水关卡，升级为真正有**博弈感**的关卡。
**Scope**：a1（暗示真假博弈）+ a2（多轮对话）+ a3（限时）+ b2（失败演出）+ b3（胜利演出）。
**Out of scope**（留给后续 wave）：a4 笔记本、b1 微表情、c1 seed、d1 原作台词。

---

## 设计概览

| 子项 | 现状 | 目标 |
|---|---|---|
| **a1 暗示真假博弈** | 人羊给的暗示 100% 指向真正的靶子 | 人羊有 **20% 概率给错误暗示**；玩家要靠对口供自己判断 |
| **a2 多轮对话** | 每个 NPC 一次聊完所有信息（自介 + 感想） | 第 1 次只自介；玩家"再次拜访"才解锁"反应/破绽" |
| **a3 限时** | 无限时间 | 关卡开始 → 10 分钟倒计时；超时自动 LOSE |
| **b2 失败演出** | 直接弹 ResultScreen | 先全屏血红 fade（1s）+ 人羊 1 句关门台词（2s）→ 再弹 ResultScreen |
| **b3 胜利演出** | spawn 一个蓝色光球 + 标签 | 同上节奏：人羊摘面具 1 句台词 → 墙裂开 fade → 出口生成 |

---

## 设计细节

### a1 · 暗示真假博弈

**规则**：
- 人羊暗示的目标 `hint_target_id` 与真正靶子 `liar_target_id` **解耦**。
- 默认 **80% 真**：rng < 0.8 → hint == liar；否则 → hint 从其他 8 人随机选一个。
- 在 `LiarGameController` 内做这件事（保持 UI 无关，纯逻辑可测）。
- 暴露 `@export var hint_truth_probability: float = 0.8`，方便测试覆盖为 0.0/1.0。

**新增 API**：
```gdscript
class_name LiarGameController
@export var hint_truth_probability: float = 0.8
var hint_target_id: String = ""   ## 人羊暗示的目标（可能 != liar_target_id）
var hint_is_truth: bool = true    ## 这次暗示是否真实（用于测试）
```

**在 `_ready` 末尾**：
```gdscript
_roll_hint_target()

func _roll_hint_target(rng: RandomNumberGenerator = null) -> void:
    if rng == null:
        rng = RandomNumberGenerator.new()
        rng.randomize()
    if rng.randf() < hint_truth_probability:
        hint_target_id = liar_target_id
        hint_is_truth = true
    else:
        # 随机选一个非靶子
        var pool: Array = []
        for id in LiarNpcId.ALL:
            if id != liar_target_id:
                pool.append(id)
        hint_target_id = pool[rng.randi() % pool.size()]
        hint_is_truth = false
```

**Orchestrator 改动**：`_show_sheep_hint` 改用 `hint_target_id` 而不是 `liar_target_id`。
- 不告诉玩家"暗示可能是假的"——这个不确定性就是博弈感。
- 唯一暴露的提示：人羊台词偶尔加一句模糊修饰（"我也只是揣测"），保持紧张。

---

### a2 · 多轮对话（按 NPC 拜访次数，**3 轮**）

**规则**：
- `GameState` 增加 `npc_visit_count: Dictionary[String, int]`，key 是 dialogue_id。
- `DialogueController._on_dialogue_ended` 时给对应 npc +1。
- 每个 NPC 注册 **3 套** dialogue lines (v1/v2/v3)，由 **Selector** 在交互瞬间根据 visit_count 决定走哪套：
  - `visit_count == 0` → v1（自介 · 沿用现状）
  - `visit_count == 1` → v2（玩家**追问职业**，NPC 给出 1 个"职业关键信息"）
  - `visit_count >= 2` → v3（玩家**追问昨晚动向**，NPC 给出"昨晚做了什么"）

**博弈核心**：靠 v2 + v3 的口供**互相印证**找说谎者。
- **真说谎者的 v3** 会**与 v2 矛盾**：例如 v2 说"医生晚上值班"，v3 却说"昨晚刚下班回家"。
- **其他 NPC 的 v3** 给出**旁观信息**（"我注意到 X 在 Y 时候做了 Z"），偶有干扰。
- 玩家于是能用**3 重验证**：人羊暗示（80% 准）+ NPC v2 + NPC v3 → 锁定靶子。

**实现方式**（最少改动）：
- 新增 `LiarNpcDialogueSelector`（普通 Node），监听场景里所有 Interactable（DIALOGUE 类型且 dialogue_id 以 `liar_` 开头）的 `interaction_triggered`。
- **优先级**比 DialogueController 高（注册顺序在前）—— 但 DialogueController 是用 `_interactor.interacted` 信号触发，不是 `Interactable.interaction_triggered`。所以两者不冲突，但 Selector 不能"拦截"。
- 改用**装饰器模式**：Selector 直接改写 Interactable 节点上的 `dialogue_id` 属性（运行时根据 visit_count 切到 `liar_xxx_v2`）。这就让 DialogueController 自然读到 v2。

**新增 dialogue**：每个 NPC 增加 `liar_xxx_v2`，内容是"反应"：
- 真正的靶子（第 2 次拜访）→ 露出破绽（话题对不上、回答闪烁）。
- 其他 NPC（第 2 次拜访）→ 说出"我注意到了……"开头的旁观信息（轻提示，不一定准）。

**数据量**：9 NPC × 2 新版本(v2+v3) × ≈2 行 ≈ 36 行新对话，写在 `dialogue_database.gd` 里。

---

### a3 · 限时机制

**规则**：
- 关卡过场结束、`_enable_gameplay` 调用时，启动倒计时 **600 秒（10 分钟）**。
- HUD 顶部红色 `MM:SS` 显示。
- 当 `time_left <= 60s` 红色闪烁（用 `modulate` 在 _process 里做正弦淡入淡出）。
- 时间到 → `_ctrl.force_lose("time_up")` → 触发 b2 失败演出，台词替换为 "时间到了 ⌛"。

**实现**：
- `LiarGameController` 加 `@export var time_limit: float = 600.0`、`time_left`、`signal time_changed(left)`、`signal time_expired()`。
- 用 `set_process(true) + _process(delta)` 驱动，**只在 `state == PLAYING` 时计时**（SUBMITTED 后停止）。
- `LevelHUD` 加 `Timer` 显示区。

---

### b2 · 失败演出

**节奏**（总 ≈3 秒）：
1. `_on_vote_submitted(LOSE)` →  
2. 全屏血红 ColorRect fade-in（α 0→0.85），同时 Toast 显示"识错了……"  
3. 中央显示人羊 1 句话（取决于错误类型）：  
   - 投错人：「[人羊冷笑] 不是这个……可惜了。」  
   - 时间到：「[人羊不耐烦] 时间到。下一波。」
4. 1 秒后再 fade-in ResultScreen，把血红 overlay 隐藏。

**实现**：新增 `LiarLoseCinematic`（CanvasLayer + Tween），由 Orchestrator 在 LOSE 时先调用 `.play(reason)`，结束后再 `_result_screen.show_lose(...)`。

---

### b3 · 胜利演出

**节奏**（总 ≈3 秒）：
1. `_on_vote_submitted(WIN)` →  
2. 显示中央人羊台词："[摘面具] 有意思的小齐夏……"  
3. 0.8s 后玩家位置朝向墙体方向，**墙体一处出现裂缝**（用 ColorRect 模拟 "shake + 渐隐"）  
4. 裂缝结束位置 spawn 现有的"通往道城蓝光门" + Toast"墙裂开了，走过去吧"  
5. 同步 fade-in ResultScreen 显示胜利信息。

**实现**：新增 `LiarWinCinematic`（CanvasLayer + Tween），由 Orchestrator 在 WIN 时调用。

---

## Tasks

> **TDD 顺序**：先做 a1（纯逻辑，测试简单）→ a3（半逻辑半 UI）→ a2（数据+触发）→ b2/b3（演出，多用 Tween 集成测试少）。

### Task 1 · a1 暗示真假博弈（TDD）
- [ ] **Test**：`tests/unit/test_liar_hint_targeting.gd`
  - `truth_probability=1.0` → `hint_target_id == liar_target_id`
  - `truth_probability=0.0` → `hint_target_id != liar_target_id`
  - 0.0 时 100 次抽样：hint_target_id 一定在 ALL 中且 != liar
- [ ] **实现**：`LiarGameController` 加 `hint_target_id` / `hint_is_truth` / `_roll_hint_target`
- [ ] **联动**：`LiarGameOrchestrator._show_sheep_hint` 改读 `_ctrl.hint_target_id`

### Task 2 · a3 限时机制（TDD）
- [ ] **Test**：`tests/unit/test_liar_timer.gd`
  - `time_limit=10, advance 5s` → `time_left==5, time_changed emit`
  - `time_limit=10, advance 11s` → `time_expired emit, state==SUBMITTED, last_result==LOSE`
  - `state==SUBMITTED` 后 advance → time_left 不变
- [ ] **实现**：`LiarGameController` 加 `time_limit`/`time_left`/`time_changed`/`time_expired` + `_process` + `force_lose`
- [ ] **HUD**：`LevelHUD` 加红色 MM:SS（< 60s 闪烁），监听 `_ctrl.time_changed`

### Task 3 · a2 多轮对话（"二访"）
- [ ] **GameState**：加 `npc_visit_count: Dictionary` + getter/setter + 存档序列化
- [ ] **Test**：`tests/unit/test_game_state_visit_count.gd`：增减/persist
- [ ] **DialogueController 钩子**：对话结束时 `GameState.npc_visit_count[dialogue_id] += 1`
- [ ] **Dialogue 数据**：9 NPC × `liar_xxx_v2` 写到 `dialogue_database.gd`，内容偏"反应+破绽/旁观"
- [ ] **Selector**：新增 `LiarNpcDialogueSelector`（场景中一个 Node），在玩家走近 NPC 触发 `interaction_triggered` **前**，根据 visit_count 改 `Interactable.dialogue_id`
  - 实际方案：**不拦截，改用 Interactable._ready 注册 callback**。或者更简单：`LiarNpcDialogueSelector._process()` 每帧轮询所有 liar_npc 的 Interactable，按 visit_count 切 dialogue_id（开销极小，9 个节点）
- [ ] **Test**：`tests/unit/test_liar_dialogue_selector.gd`：visit==0 → v1；visit≥1 → v2

### Task 4 · b2 失败演出
- [ ] 新建 `src/scripts/liar_game/liar_lose_cinematic.gd` + scene（CanvasLayer + ColorRect overlay + Label）
- [ ] API：`play(reason: String) -> Signal`，返回完成 signal
- [ ] Orchestrator：LOSE 时先 `await cinematic.play(reason)`，再 `_result_screen.show_lose`
- [ ] **Test**：`tests/unit/test_liar_lose_cinematic.gd`：play 后 _ready 完成 → finished 信号在 ~3s 内 emit（使用 SignalWatcher + fake timer）

### Task 5 · b3 胜利演出
- [ ] 新建 `src/scripts/liar_game/liar_win_cinematic.gd`
- [ ] Orchestrator：WIN 时先 cinematic.play，期间 spawn ExitDoor（原有逻辑挪进 cinematic 末尾）
- [ ] **Test**：类似 Task 4

### Task 6 · 集成 + 端到端
- [ ] 跑全套 GUT，确保 P4/P4.5 老测试不破
- [ ] 手动验证：
  - 进游戏 → 倒计时显示 + 暗示提示带不确定感
  - 跟 NPC 聊一次后再聊一次 → 内容变化
  - 故意投错 → 看 b2 演出
  - 投对 → 看 b3 演出
- [ ] 写报告 `docs/tech-verification-p46/report.md`
- [ ] tag `v0.4.6-p46-complete`

---

## 影响面 / 风险

**新增文件**：
- `src/scripts/liar_game/liar_npc_dialogue_selector.gd`
- `src/scripts/liar_game/liar_lose_cinematic.gd` (+ tscn)
- `src/scripts/liar_game/liar_win_cinematic.gd` (+ tscn)
- `tests/unit/test_liar_hint_targeting.gd`
- `tests/unit/test_liar_timer.gd`
- `tests/unit/test_game_state_visit_count.gd`
- `tests/unit/test_liar_dialogue_selector.gd`
- `tests/unit/test_liar_lose_cinematic.gd`、`test_liar_win_cinematic.gd`

**修改文件**：
- `src/scripts/liar_game/liar_game_controller.gd`（+ hint targeting + timer）
- `src/scripts/liar_game/liar_game_orchestrator.gd`（用 hint_target_id；接 cinematic；spawn exit 移入 cinematic）
- `src/scripts/save/game_state.gd`（visit_count）
- `src/scripts/save/save_system.gd`（序列化 visit_count）
- `src/scripts/dialogue/dialogue_controller.gd`（_on_dialogue_ended 时 +1）
- `src/scripts/dialogue/dialogue_database.gd`（+ 9 个 v2 对话）
- `src/scripts/ui/level_hud.gd`（+ 倒计时显示）
- `src/scenes/world/interview_room.tscn`（实例化 selector + 两个 cinematic）

**风险**：
- a2 Selector 的"运行时改 Interactable.dialogue_id" 在 Godot 中是普通属性写入，不会触发 _ready 重跑。OK。
- b2/b3 演出动画用 Tween，需要在 cinematic 节点上有 process_mode = ALWAYS（防 pause）。
- 倒计时与限时演出协调：time_expired 触发的 LOSE 也要走 b2 cinematic（不要重复结算）。
- **存档兼容**：旧存档没 `npc_visit_count`，反序列化时默认空 dict。SaveSystem 已用 ConfigFile.get_value 带 default，OK。

**预估工作量**：6~8 小时（不含手测）。

---

## 用户决策（已锁定）

- **a1 暗示真实率** = **80%**
- **a3 限时** = **10 分钟**
- **a2 对话深度** = **3 轮（v1 自介 / v2 追问职业 / v3 追问昨晚）**
- **演出可按 E 跳过**（首次也可跳）
