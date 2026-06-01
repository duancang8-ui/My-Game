# P6 技术验证报告

| 项 | 内容 |
|---|---|
| 阶段 | P6 — 「雨后春笋」生肖游戏关卡（人狗·时间反应类）|
| 完成日期 | 2026-06-01 |
| 测试 | **55/55** unit tests + E2E PASS |
| 结论 | ✅ 第二个生肖关卡，验证系统对**不同玩法机制**的通用性 |

---

## 1. 设计目的

P6 不仅是"第二个关卡"，更是**系统通用性的关键验证**：
- P4 "说谎者" = 社交推理（按钮投票）
- P6 "雨后春笋" = **时间反应**（连按 E + 倒计时）

证明：项目的 SceneManager / ResultScreen / Toast / CutsceneController / DialogueBox / Interactable / GameState 等基础设施**确实通用**，新关卡只需写**关卡特有逻辑**即可。

---

## 2. 复用 vs 新增

### 🟢 复用（不写一行代码）
- `SceneManager` autoload（场景切换 + fade）
- `ResultScreen` CanvasLayer（WIN/LOSE 屏）
- `Toast` autoload（通知）
- `CutsceneController`（入场过场，复用 P4.1 的）
- `DialogueBox` UI（道城风皮肤）
- `DialogueDatabase` autoload（只追加新对话注册）
- `Interactable.SCENE_CHANGE` 触发（自动连接）
- `GameState`（current_scene_path 自动更新）

### 🆕 新增（关卡特有）
- `RotateGameController`（状态机：READY/PLAYING/ENDED + WIN/LOSE）
- `RotateGameOrchestrator`（编排：过场 → 启动 → 玩家输入 → 结算 → 返回门）
- `RotateGameHud` CanvasLayer（进度条 + 倒计时 + 临界变红）
- `RainyFieldBuilder`（程序化生成场景：地板/桌子/人狗）
- `rainy_field_intro` 对话（6 段人狗讲规则）
- DaoCheng 新增"雨地"入口门

---

## 3. 玩法机制

| 维度 | 说谎者（P4/P4.5）| 雨后春笋（P6）|
|---|---|---|
| 类型 | 社交推理 + 投票 | **时间反应 + 连点** |
| 输入 | 走 + E 触发对话 + 投票点击 | **E 键连按 100 次** |
| 时间压力 | 无（玩家可慢慢推理）| **30 秒倒计时** |
| 决策密度 | 1 次（投票）| 100 次（每次按 E）|
| 失败感 | 偏概率（10 选 1）| 偏技能（手速 + 节奏） |

---

## 4. 测试覆盖

| 模块 | 测试数 |
|---|---|
| (之前已有) | 48 |
| **test_rotate_game_controller** ⭐ 新增 | **7** |
| **总计** | **55/55 ✅** |

新测试覆盖：
- 初始 READY 状态
- start_game → PLAYING
- READY 状态下 add_rotation 被忽略
- add_rotation 累加 + signal
- 达到 target → WIN
- 胜利后 add_rotation 被忽略
- reset

**E2E 验证**：
- 6 段对话注册 ✅
- rainy_field.tscn 11 个关键节点齐全 ✅
- 桌子 + 人狗主理人 spawn ✅
- DaoCheng 新增 RainyFieldDoor 指向 rainy_field ✅

---

## 5. 关键技术决策

| # | 决策 | 选择 | 理由 |
|---|---|---|---|
| 1 | 目标圈数 | **100** | 30 秒内 100 圈 = 每秒 3.3 次按键，正常人手速可达 |
| 2 | 时间限制 | **30.0 秒** | 有压力但不至于不可能 |
| 3 | 输入键 | **interact (E)** | 复用既有 InputMap，无需新增 action |
| 4 | UI 风格 | 复用 9-slice 道城风 | 视觉统一 |
| 5 | 倒计时变红阈值 | 5 秒 | 5 秒时玩家应该明确"快撑不住了" |
| 6 | 胜利反馈 | ResultScreen + Toast + 自动 spawn 返回门 | 复用 P4 模式 |
| 7 | 失败反馈 | ResultScreen + 锁玩家 + 染暗 | 复用 P4 模式 |
| 8 | 入场过场 | 复用 CutsceneController | 6 段人狗规则讲解，BBCode 高亮关键字 |
| 9 | 场景入口 | 在 DaoCheng 加新门 | 既保留双向门，又验证 SceneManager 多场景路由 |

---

## 6. 用户验证步骤

1. **F5 启动** → 进开场过场（默认是面试房间，可快速过到完成说谎者关卡）
2. 胜利后通过房间右侧蓝色门 → 进入 **DaoCheng**
3. DaoCheng 中除了"返回面试房间"门，**多了一扇橙红色"[雨地 · 人狗游戏]"门**
4. 走到雨地门 + 按 E → 黑屏切换 → 进入雨地场景
5. 自动播放人狗入场过场（"汪——欢迎来玩雨后春笋……"）6 段
6. 过场结束 → HUD 出现倒计时 + 进度条
7. **连按 E 30 秒内点够 100 次**
   - 每 25 圈 Toast："还差 X 圈！"
   - 剩 5 秒倒计时变红
8. **胜利**：ResultScreen 显示"盾牌长出来了！" + spawn 蓝色返回门
9. **失败**：ResultScreen 显示"鱼叉穿透了你" + 重试 / 读档 按钮
10. 走返回门回到 DaoCheng

---

## 7. 局限性 / 后续改进

| 项 | 当前 | 后续 |
|---|---|---|
| 节奏判定 | 每个 E 都算一次（无节奏要求） | P6.5 加 QTE 节奏点 |
| NPC 协作 | 仅玩家一人转 | 原作是团队分工 |
| 鱼叉特效 | 仅文字描述 | 美术 sprint 后加粒子/动画 |
| 难度曲线 | 固定 100/30s | 后续可加多个难度档 |
| 对话台词 | AI 占位（人狗用拟声词）| 用户提供原作 zip 后替换 |

---

## 8. 系统通用性结论 ✨

P6 实质性证明项目架构对**完全不同玩法**的支持能力：

```
说谎者 (社交推理) ────┐
                     ├─────► 共用基础设施
雨后春笋 (时间反应) ──┘   (SceneManager / ResultScreen / Toast / Cutscene / Dialogue / Interactable / GameState)
```

**对后续 6 个关卡的预判**：
- 仓库寻道（人鼠）：探索 + 找物 → 复用既有，新增物品查找逻辑
- 黑熊狩猎（地牛）：体能/躲避 → 新增碰撞躲避
- 黑白棋（人猪）：概率 + 谎言眼镜 → 复用对话系统 + 新增选择 UI
- 是与非 / 两颗药丸（人蛇）：纯逻辑 → 复用对话系统
- 谍战剧（地狗）：身份扮演 → 大量复用对话 + 新增身份分配
- 天降死亡：反应躲避 → 新增躲避机制

**结论**：系统骨架已足够。后续关卡主要是"关卡特有逻辑 + 内容"，框架不需要大改。

---

## 9. 产出清单

### 新增脚本
- `src/scripts/rotate_game/rotate_game_controller.gd`
- `src/scripts/rotate_game/rotate_game_orchestrator.gd`
- `src/scripts/rotate_game/rainy_field_builder.gd`
- `src/scripts/ui/rotate_game_hud.gd`

### 新增场景
- `src/scenes/world/rainy_field.tscn`

### 新增测试
- `tests/unit/test_rotate_game_controller.gd`（7 个）

### 修改
- `src/scripts/dialogue/dialogue_database.gd`：注册 rainy_field_intro
- `src/scripts/test/daocheng_builder.gd`：加 RainyFieldDoor

---

## 10. 下一步候选

按 "deadline = 4 个关卡后启动美术 sprint" 的节奏：

剩余还可做的"占位美术开发"：
- ✅ P4 说谎者 / ✅ P4.5 升级 / ✅ P5 场景管理 / ✅ P6 雨后春笋
- **P7 道城主场景骨架**（关键：B 风格连续步行 + 多入口）
- **P8 ~ 第三个生肖游戏**（建议黑白棋，概率类）
- **P9 ~ P10 ~ 美术 sprint**

或：
- **P5.5 跨场景持久化**（让玩家在场景间切换时位置/状态保留）
- **直接进美术 sprint**（如果觉得 2 个关卡演示够用，开始升级视觉）
