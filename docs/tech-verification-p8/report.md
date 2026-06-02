# P8 · 人鼠 · 仓库寻道（基础版）· 验证报告

> 阶段：P8 · v0.8-rat-warehouse
> 完成日期：2026-06-02
> 关联 plan：`docs/superpowers/plans/2026-06-02-p8-rat-warehouse.md`

## TL;DR

第 3 个生肖关卡上线，玉城 → 仓库 → 玉城的循环范式正式跑通：
- 玉城东区出现新 NPC「人鼠」，付 1 道入场
- 仓库内 5 分钟限时，6 个箱子可翻（都是诱饵）
- 真破解：观察"仓鼠协会"贴纸 → 内省提示 → 走到门口跟人鼠对话 → 选「（伸手摸她口袋）」获胜
- WIN +2 道净奖励 / 超时失败 / 玩家可中途离开（门票不退）

## 完成清单

### 控制器
- `RatGameController` 状态机：READY → PLAYING → ENDED；reveal_win/give_up/timeout 三条结束路径

### UI
- `RatGameHud` 顶部居中倒计时（<60s 红色闪烁）+ 右下道币显示

### 场景生成
- `RatWarehouseBuilder` 程序化：14×10 仓库 + 4 面墙碰撞 + 6 个箱子 + 灯开关 + 仓鼠协会贴纸 + 人鼠 NPC + 离开门 + 全屏黑暗 ColorRect

### 流程编排
- `RatGameOrchestrator`：
  - 进场→ IntroCutscene → start_game + 计时
  - 玩家观察贴纸（`rat_hamster_note`）→ 切换人鼠 dialogue_id 到 v2（含「摸口袋」选项）
  - 玩家选「摸口袋」→ reveal_win → +2 道 → ending cutscene → 切回玉城
  - 超时 → ending cutscene（lose 文案）→ 切回玉城（门票已扣，不再追加）

### 玉城接入
- `YuchengBuilder.NPCS` 加东区"人鼠"项（special="game"，prompt 提示"听听她的考验"）
- `YuchengOrchestrator` 监听 `DialogueController.choice_picked_action`，当 `action_id == "enter_rat_warehouse"` 时扣 1 道并切场景

### 框架小改
- `DialogueChoice` 增加 `action_id` 字段（可选副作用标记）
- `DialogueController` 增加 `choice_picked_action(action_id)` signal，在 `_on_choice_picked` 中根据当前 line 的 choice 配置 emit

### 对话（全部原创笔触）
共 14 段：
- `rat_npc_yucheng`：玉城门口的拉客（3 行 + 4 选项 + action_id 入场）
- `rat_warehouse_intro`：进仓库后人鼠宣布规则（3 行，重点强调"现在"）
- `rat_box_1 ~ rat_box_6`：每箱 1 行齐夏旁白
- `rat_hamster_note`：仓鼠协会贴纸 + 齐夏 3 行内省（关键线索）
- `rat_door_talk`（v1）/ `rat_door_talk_v2`（含赢取选项）
- `rat_win` / `rat_lose_timeout` / `rat_giveup`

### 测试
- `test_rat_game_controller.gd` · 10 个新 case

## 文件改动

```
新增
├── docs/superpowers/plans/2026-06-02-p8-rat-warehouse.md
├── docs/tech-verification-p8/report.md
├── src/scenes/world/rat_warehouse.tscn
├── src/scripts/rat_game/rat_game_controller.gd
├── src/scripts/rat_game/rat_game_orchestrator.gd
├── src/scripts/rat_game/rat_warehouse_builder.gd
├── src/scripts/ui/rat_game_hud.gd
└── tests/unit/test_rat_game_controller.gd

修改
├── src/scripts/dialogue/dialogue_choice.gd        (+ action_id 字段)
├── src/scripts/dialogue/dialogue_controller.gd    (+ choice_picked_action signal)
├── src/scripts/dialogue/dialogue_database.gd      (+ 人鼠关 14 段对话)
├── src/scripts/test/yucheng_builder.gd            (+ 人鼠 NPC, "game" special)
└── src/scripts/test/yucheng_orchestrator.gd       (+ choice_action 钩子, 入场扣道币)
```

## 用户验证步骤

1. **Godot → 项目 → 重新加载当前项目**
2. **GUT → Run All**：预期 110+ 个 case 全过
3. F5 完整跑：
   - 玩说谎者 + 同房间春笋（赢 +5 道，赢 +3 道）→ 出玉城
   - 玉城右上 HUD 显示 `🪙 8 道`
   - 走东区废墟附近，找到**灰色人鼠 NPC**（在 (320, -60) 附近）
   - 按 E 跟人鼠聊：选"找不到呢？"或"什么规则？"听完，再选「付 1 道入场」
   - 入场 → 仓库小房间，顶部 5:00 倒计时开始
   - 试翻 6 个箱子（都没找到道），按"💡 灯开关"切换灯光
   - **关键**：找到右上门框的「（旧贴纸）」按 E → 齐夏 3 行内省揭示线索
   - 走到门口跟人鼠按 E → 这次选项里多了「（伸手摸她口袋）」 → 选它 → 胜利演出 → +2 道 → 自动回玉城
4. 另一遍试：故意拖到时间归零 → 失败演出 → 回玉城（道币 -1，不追加）
5. 再一遍试：进仓库后立刻走"离开门" → 直接回玉城（门票不退）

## 玩家体验亮点

| 阶段 | 设计意图 |
|---|---|
| 拉客 | 让玩家"觉得能赢"（"找不到只损失 1 道"听起来风险低） |
| 翻箱 | 让玩家走一遍诱饵路径，体验"真的没有" |
| 仓鼠协会贴纸 | 关键转折，用语义双关引出真破解 |
| 摸口袋选项 | 玩家会有"原来这才是题"的拍大腿感 |
| 经济激励 | +2 道净奖励 +1 道，鼓励玩家反复回玉城 |

## 已知遗留 / 后续

- **P8.5（强烈建议）**：赌命模式（+5 道但输了死）+ 朱雀处决违规人鼠的演出（原作 Ch 32-33 的精彩片段）
- 道具尚未在仓库内生效（线索袋本可在仓库自动揭示线索袋触发 rat_hamster_note）— P8.5 一并填实
- 中途离开门没演出 — 可加 1 行 `rat_giveup` 对话（dialogue 已注册，只是没被 orchestrator 挂上）
- 任务系统目前没加 try_rat_warehouse 任务（QuestState 还停在 P7 的 3 步链）— P8.5 一并加入

## 写作纪律

P8 新增 14 段对话全部为本项目自创笔触。
- 保留：人物身份（人鼠 / 朱雀 / 仓库 / 「道」/ 5 分钟时限 / 仓鼠破绽）等事实参考
- 改写：所有句式、措辞、节奏、内心独白均原创
- 原作《十日终焉》全文仅供开发期机制校对，不入 build
