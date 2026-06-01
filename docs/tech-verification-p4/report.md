# P4 技术验证报告

| 项 | 内容 |
|---|---|
| 阶段 | P4 — 第一个生肖游戏关卡「说谎者」（MVS 精简版）|
| 完成日期 | 2026-06-01 |
| 测试 | **43/43** unit tests + 集成验证 PASS |
| 结论 | ✅ 第一个端到端可玩关卡 |

---

## 1. 实现的子系统

### 数据 / 元数据层
- `LiarNpcId`（RefCounted const helper）：5 名囚徒的常量、名字、颜色、对话 id、靶子 id
  - 5 名 NPC：陈俊南、乔家劲、张丽娟、苏闪、林檎
  - 占位策略：用 `player_placeholder.png` + `modulate` 染色区分
  - 靶子硬编码 = 林檎（按原作她是青龙安插的"针"）

### 关卡逻辑层
- `LiarGameController`（Node，纯逻辑）：状态机 PLAYING → SUBMITTED；submit_vote 后判断 WIN/LOSE 并发 signal
- 5 个单元测试覆盖默认状态 / 正确投票 / 错误投票 / 重复投票忽略 / reset

### UI 层
- `VotePanel`（CanvasLayer）：弹出式投票面板
  - 复用 P3.5 的 9-slice 道城风皮肤
  - 标题 + 5 个 NPC 按钮 + 取消按钮
  - 按钮 hover/pressed 视觉反馈

### 场景层
- `interview_room.tscn`：新的 main scene
- `LiarRoomBuilder`（Node + script）：程序化生成所有场景对象
  - 12×8 等距房间地板
  - 中央木桌（StaticBody2D + collision）
  - 5 名 NPC 围桌环坐（CharacterBody2D + collision + Interactable Area2D）
  - 人羊·张强主理人（戴山羊面具，灰白色染色）
  - "提交答案"标记（黄色发光球 + VOTE 类型 Interactable）

### 编排层
- `LiarGameOrchestrator`（Node）：把 4 个子系统串起来
  - 监听场景所有 Interactable
  - VOTE 类型触发 → 弹出 VotePanel
  - VotePanel.vote_picked → Controller.submit_vote
  - Controller.vote_submitted → Toast 反馈 + 失败时锁玩家

### 对话内容
- 5 段占位对话，每段 1 段自我介绍 + 1 段"对其他人的观察"（暗藏指认线索）
- ⚠️ **AI 占位**，等用户提供原作 zip 后用 Ch 1~5 真实台词批量替换

---

## 2. 测试覆盖

| 模块 | 测试数 |
|---|---|
| `test_sanity` | 3 |
| `test_player_input` | 4 |
| `test_player_movement` | 5 |
| `test_dialogue_line` | 4 |
| `test_dialogue_runner` | 7 |
| `test_interactable` | 4 |
| `test_game_state` | 7 |
| `test_save_system` | 4 |
| `test_liar_game_controller` ⭐**新增** | **5** |
| **总计** | **43/43 ✅** |

**集成验证（headless）**：
- 9 个关键节点全部就位
- 5 名 NPC + 主理人 + 桌子 + 提交标记由 builder 程序化生成
- LiarGameController 默认状态 PLAYING + liar_target_id = `lin_qin`

---

## 3. 关键技术决策

| # | 决策 | 选择 | 理由 |
|---|---|---|---|
| 1 | 主场景切换 | 直接改 main_scene 到 interview_room | P4 不做正式场景切换系统（推到后续 plan）|
| 2 | NPC 数量 | 5（精简版）而非原作 10 | MVS 优先；后续 P4.5 可扩到 10 |
| 3 | 场景节点 | 用 `LiarRoomBuilder` 程序化生成 | 比手工拼 .tscn 50 多节点更可控、可参数化 |
| 4 | 靶子选择 | 硬编码林檎 | P4 不做随机性；P5+ 可随机选 |
| 5 | 失败处理 | Toast + 锁玩家 + 染暗 | 简单清晰；后续可加结算屏幕 |
| 6 | Interactable.Type 扩展 | 新增 VOTE | 复用既有交互系统，避免重做 |
| 7 | VotePanel 样式 | 复用 P3.5 9-slice 道城风 | 风格统一 + 资源复用 |
| 8 | 占位 NPC sprite | 同贴图 + modulate 染色 | 不依赖美术、便于区分 |

---

## 4. 用户验证步骤

启动 Godot **F5**：

1. ✅ 进入面试房间（不再是测试沙盒）
2. ✅ 看到中央有圆桌 + 5 名彩色 NPC 围坐 + 上方戴山羊面具的主理人 + 玩家在桌下
3. ✅ 右侧有一个**黄色发光球**（提交标记）
4. ✅ 走近任意 NPC + 按 **E** → 弹出**精致对话框**：
   - 蓝色陈俊南："我叫陈俊南，是个警察…"
   - 选 "你怀疑谁是说谎者？" → 陈俊南给出指认线索
5. ✅ 对话期间按 WASD：玩家不动
6. ✅ 把所有 5 名 NPC 都聊一遍，收集线索
7. ✅ 走到黄色球旁 + **按 E** → 弹出**投票面板**（中央，9-slice 道城风）：
   - 5 个 NPC 按钮 + 取消
8. ✅ 点 **"指认 林檎"** → Toast：**"识破了！「说谎者」就是 林檎 ✓"**（绿色）
9. ✅ 点其他人 → Toast：**"失败！XXX 不是说谎者。全员被人羊制裁。"**（红色）+ 玩家变暗不动
10. ✅ F9/F10 存档读档照常工作

---

## 5. 局限性与后续改进

| 项 | 当前 | 后续 |
|---|---|---|
| NPC 数量 | 5 | 扩到 10（原作）|
| 靶子 | 硬编码林檎 | 随机生成 |
| 失败重来 | F10 读档 | 加"重来"按钮 / 自动重置 |
| 投票为"指认"非"全员一致" | 简化判定 | 原作要 10 人一致才赢 |
| 对话只 1 段 | 自我介绍 + 线索 | 多轮对话 / 玩家可追问 |
| 没有时间限制 | 自由探索 | 加倒计时（30 秒 / 60 秒）|
| 没有动画 | 静态 | NPC 思考/紧张动作 |
| 对话台词为 AI 占位 | 待替换 | **用户提供原作 zip 后批量替换 Ch 1~5 真实摘录** |

---

## 6. 产出清单

### 新增脚本
- `src/scripts/liar_game/liar_npc_id.gd`（NPC 元数据）
- `src/scripts/liar_game/liar_game_controller.gd`（关卡状态机）
- `src/scripts/liar_game/liar_room_builder.gd`（场景生成器）
- `src/scripts/liar_game/liar_game_orchestrator.gd`（编排层）
- `src/scripts/ui/vote_panel.gd`（投票 UI）

### 新增场景
- `src/scenes/world/interview_room.tscn`（新 main scene）

### 新增资源
- `src/assets/characters/table_placeholder.png`（128×96 圆桌）
- `src/assets/characters/submit_marker.png`（24×24 黄球）

### 新增测试
- `tests/unit/test_liar_game_controller.gd`（5 个）

### 修改
- `src/scripts/dialogue/dialogue_database.gd`：注册 5 段说谎者关卡对话
- `src/scripts/interaction/interactable.gd`：枚举加 `VOTE` 类型
- `project.godot`：main_scene 切到 interview_room
- `README.md`：标记 P4 完成

### 保留
- `src/scenes/world/test_world.tscn`：保留作 sandbox 测试场景（不再是 main scene）

---

## 7. P4 最终结论

✅ **第一个端到端可玩生肖游戏关卡已完成**。所有 P4 假设被验证：

1. 程序化场景生成（避免手工拼大 .tscn）可行 ✅
2. 关卡逻辑可独立单测 ✅
3. P2 对话系统 + P3.5 Toast + P3.5 道城风皮肤在真实关卡中工作 ✅
4. Interactable.VOTE 扩展不破坏既有 DIALOGUE 流程 ✅

---

## 8. 下一步候选

- **P4.5**：把 5 NPC 扩到 10 + 加随机靶子 + 全员一致投票判定（更接近原作）
- **P5**：场景切换系统（让 InterviewRoom → DaoCheng 等多场景）
- **P6**：第二个生肖游戏（建议 "雨后春笋" — 时间反应类，验证不同游戏机制）
- **批量任务**：用户提供原作 zip 后，把所有 dialogue 替换为原作摘录

待用户回来选方向。
