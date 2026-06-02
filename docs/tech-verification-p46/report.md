# P4.6 「说谎者」深化 · 验证报告

> 阶段：P4.6 第一波（a1 暗示真假博弈 + a2 多轮对话 + a3 限时 + b2 失败演出 + b3 胜利演出）
> 完成日期：2026-06-02
> 关联 plan：`docs/superpowers/plans/2026-06-02-p46-liar-deepening.md`

## TL;DR
说谎者关卡从纯流水任务升级为**三重验证**博弈：
1. 人羊暗示有 20% 概率为假（不告诉玩家）
2. NPC 三轮拜访（v1 自介 → v2 职业细节 → v3 互相观察）
3. 10 分钟限时倒计时（< 60s 闪烁红色）

胜负都有 ≈3s fade-overlay 演出，按 E 可跳过。

## 完成清单

### a1 · 暗示真假博弈 ✅
- `LiarGameController` 新增 `hint_target_id` / `hint_is_truth` / `hint_truth_probability` (默认 0.8) / `_roll_hint_target()`
- `LiarGameOrchestrator._show_sheep_hint` 改读 `hint_target_id`，台词加"似乎/也许"模糊词
- 测试 `tests/unit/test_liar_hint_targeting.gd` —— 6 个 case：
  - 真实率 1.0 → hint 必等真靶子
  - 真实率 0.0 → hint 必不等真靶子且在剩余 8 人中
  - 100 次抽样 hint 覆盖多个非靶子（避免 RNG 退化）
  - 默认 0.8
  - hint_target_id 非空
  - 同 seed 下确定性

### a2 · 多轮对话 ✅
- `GameState` 增加 `npc_visit_count: Dictionary` + `increment_visit_count()` + `get_visit_count()` + `to_dict/from_dict` 持久化
- `DialogueController._on_dialogue_ended` 钩子调用 `GameState.increment_visit_count(dialogue_id)`
- 9 NPC × 2 个新版本（v2 追问职业、v3 追问昨晚）= 18 段新对话写入 `dialogue_database.gd`
- 新增 `LiarNpcDialogueSelector` 节点：每帧根据 visit_count 把 `Interactable.dialogue_id` 在 `base / base_v2 / base_v3` 之间切换
- 测试：
  - `test_game_state_visit_count.gd` —— 8 case
  - `test_liar_dialogue_selector.gd` —— 5 case

### a3 · 限时机制 ✅
- `LiarGameController` 新增 `time_limit` (默认 600s)、`time_left`、`auto_tick`、`time_changed` / `time_expired` 信号、`advance_time()` / `force_lose()` / `lose_reason`
- `Orchestrator._enable_gameplay` 在过场结束后开启 `auto_tick`；`_on_vote_submitted` 中关闭
- `LevelHUD` 增加右上角 `⏳ MM:SS` 计时器：> 60s 黄色；≤ 60s 红色 + 闪烁
- 超时 → `force_lose("time_up")` → 触发 lose cinematic
- 测试 `test_liar_timer.gd` —— 7 case

### b2 · 失败演出 ✅
- 新增 `LiarCinematic`（CanvasLayer，layer=90，PROCESS_MODE_ALWAYS）
- 3 段 Tween：fade_in(0.6s) → hold(2s) → fade_out(0.4s)；按 E 可跳过
- LoseCinematic 节点配置：暗红 overlay (0.6, 0.05, 0.05, 0.85)
- 文案按 `lose_reason` 分流：
  - `wrong_vote`：「不是这个……可惜了。」
  - `time_up`：「还是太慢了，下一波。」
- 演出结束后才 `_result_screen.show_lose(...)`
- 测试 `test_liar_cinematic.gd` —— 4 case（缩短时长加速验证）

### b3 · 胜利演出 ✅
- 复用 `LiarCinematic`，WinCinematic 节点配置：蓝金 overlay (0.2, 0.55, 0.95, 0.55)
- 文案：「人羊摘下了面具 / 有意思的小齐夏……」
- 演出结束才 `show_win(...)` + `_spawn_exit_to_daocheng()`

## 修改文件

```
M  src/scripts/liar_game/liar_game_controller.gd         （+ a1/a3 字段 + 信号 + force_lose）
M  src/scripts/liar_game/liar_game_orchestrator.gd       （cinematic 链 + 限时启停 + 文案分流）
M  src/scripts/save/game_state.gd                        （+ npc_visit_count）
M  src/scripts/dialogue/dialogue_controller.gd           （+ increment_visit_count 钩子）
M  src/scripts/dialogue/dialogue_database.gd             （+ 18 段 v2/v3 对话）
M  src/scripts/ui/level_hud.gd                           （+ 倒计时 Label + 闪烁）
M  src/scenes/world/interview_room.tscn                  （+ Selector / Lose/Win Cinematic）

A  src/scripts/liar_game/liar_npc_dialogue_selector.gd
A  src/scripts/liar_game/liar_cinematic.gd
A  tests/unit/test_liar_hint_targeting.gd
A  tests/unit/test_liar_timer.gd
A  tests/unit/test_game_state_visit_count.gd
A  tests/unit/test_liar_dialogue_selector.gd
A  tests/unit/test_liar_cinematic.gd
A  docs/superpowers/plans/2026-06-02-p46-liar-deepening.md
A  docs/tech-verification-p46/report.md
```

## 玩家可感知的变化

| 维度 | P4.5 | P4.6 |
|---|---|---|
| 人羊暗示 | 100% 准 → 投错都怪自己 | 80% 准 → 不能盲信 |
| NPC 对话 | 1 轮聊完所有信息 | 3 轮（v1 自介 / v2 职业细节 / v3 互相观察） |
| 时间压力 | 无 | 10 分钟倒计时，< 60s 红色闪烁 |
| 失败反馈 | 直接弹结算屏幕 | 血红 fade + 人羊台词（≈3s）→ 结算 |
| 胜利反馈 | 直接 spawn 出口 + 结算屏幕 | 蓝金 fade + 摘面具台词 → 出口 + 结算 |

## 决策记录

| 决策点 | 选择 | 理由 |
|---|---|---|
| 暗示真实率 | 80% | 轻不确定感；保留博弈但不让玩家心累 |
| 限时长度 | 10 分钟 | 足够走 27 段对话 + 思考 |
| 对话深度 | 3 轮 | 让玩家有"二次/三次访问"动力 |
| 演出可跳 | 是（含首次） | 重玩友好 |
| v3 矛盾设计 | 通用版本，不区分靶子 | 简化实现；博弈来自 v2 时间细节 + v3 互相指控 |

## 测试覆盖（待用户在 Godot IDE 内运行）

预计 GUT 用例数：
- 老测试：55（P1-P6）
- 新测试：6 + 7 + 8 + 5 + 4 = **30 个新 case**
- 总计：**85 个**

## 用户验证步骤

1. 在 Godot 编辑器 **重新加载脚本**（Ctrl/Cmd+Shift+P 或 项目→重新加载当前项目）
2. **GUT 面板**：跑 res://tests/unit/ → 应 85/85 通过
3. **F5 试玩** InterviewRoom：
   - 开场过场（按 E 跳过）→ 规则过场 → 看到顶部 HUD + 右上 `⏳ 10:00`
   - 跟一个 NPC 聊（v1）→ 走开 → 再走过去（v2 追问职业）→ 走开 → 再来（v3 互相观察）
   - 故意拖时间到 < 60s，看到红色闪烁
   - 故意拖到 0:00，看到血红失败演出 + 结算屏幕
   - 重试 → 倒计时归位 10:00
   - 真投对 → 看到蓝金胜利演出 + 蓝光门生成

## 已知遗留

- a4（笔记本）/ b1（NPC 微表情）/ c1 (seed) / c2 (难度档) / c3 (道币) / d1（原作台词）/ d2/d3（美术）未做
- v3 全部为"通用观察"版，不针对靶子做差异化指认（若日后想做，可在 Selector 里读 `_ctrl.liar_target_id` 切到 `_v3_liar` 版本）
- 暗示真实率 80% 是经验值，未做 playtest 调优

## 下一步选项

| 选项 | 说明 |
|---|---|
| **P5.5** | 跨场景玩家状态持久化（进雨后春笋再回来 / 道城单元铺底） |
| **P7** | 道城主场景骨架（让两个关卡有"枢纽" + 单元/记忆/重生） |
| **P8** | 第 3 个生肖关卡（人鸡推理 / 黑白棋 / 仓库找物） |
| **P4.6 第二波** | a4 笔记本 + b1 微表情 + c3 道币 |
| **美术 sprint** | 9 张占位图全部替换 |
