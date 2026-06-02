# P4 final · 验证报告

> 阶段：P4 收尾（v0.4-final）
> 完成日期：2026-06-02
> 关联 plan：`docs/superpowers/plans/2026-06-02-p4-final.md`

## TL;DR

P4 阶段完整收尾。「说谎者」关卡现在：
- 9 个原作参与者 + 唯一正解「人羊」
- 3 个环境观察点 + 灵光闪现内省
- NPC 头顶随机微表情、走近时主体加亮、玩家头顶浮动 prompt
- 按 N 打开笔记本（自动汇总玩家收集的所有事实）
- 胜利不出门 → **同房间**直接接「雨后春笋」转桌玩法（原作 Ch 11-13 一致）
- 道币奖励：说谎者通关 +5，雨后春笋通关 +3，HUD 右下角实时显示

## 完成清单（全 9 项）

### c1 Seed-based（调试可复现）
- `LiarGameController` 增加 `@export random_seed: int = 0`（0 = 随机；非零 = 复现）
- 提供 `get_rng()` 统一随机源
- `LiarGameOrchestrator._show_environment_clue` 改用 controller 的 rng

### c3 道币奖励
- `LiarGameController` 胜利 → `GameState.add_dao(+5)` + Toast 提示
- `RotateGameController` 胜利 → `+3 道`（无论独立场景还是同房间 phase 2）
- `LevelHUD` / `RotateGameHud` 右下角加 `🪙 X 道` 实时显示

### b4 NPC 走近反馈
- `PlayerInteractor` 加 `_highlight`：走近 Interactable 时给目标父节点的 Sprite2D `modulate * 1.35`
- `PlayerInteractor` 加 `_prompt_label`：玩家头顶悬浮显示 `prompt_text`，离开自动消失

### b1 NPC 微表情气泡
- 新增 `npc_mood_bubble.gd`（Node2D + Label）
- 每 5~15 秒随机显示一个符号（···/?/👀/💭）0.8 秒
- `LiarRoomBuilder._spawn_seated_npcs` 给每个 NPC 挂一个 bubble

### P4.9 3 个环境观察点 + 灵光闪现
- `GameState` 增加 `observed_clues: PackedStringArray` + `mark_observed()` / `has_observed()` / `observed_clue_count()`
- `LiarRoomBuilder._spawn_observation_clues` 在房间布置 3 个发光小点：
  - 墙边方格（左侧）→ `observe_wall_grid` → 齐夏数出 48 立方米
  - 桌上座钟（中央）→ `observe_clock` → 齐夏察觉时间不对
  - 桌上尸体（左偏）→ `observe_corpse` → 齐夏摸到温度异常
- `DialogueController._on_dialogue_ended` 自动 `mark_observed` + 当满 3 个时 `call_deferred("_start_dialogue", "liar_insight")` 触发**齐夏自我推理**的内省对话（4 行）

### a4 笔记本系统
- 新增 autoload `Notebook`（CanvasLayer，layer=70）
- 内置 dialogue_id → 摘要 映射表（v1/v2/v3/observe_*/insight 共 22 条）
- 玩家与 NPC 对话结束时，`DialogueController` 调 `Notebook.record(dialogue_id)` 自动写入
- 按 `N` 切换显示（CanvasLayer 自己处理 _unhandled_input）
- 显示按 NPC 分组的全部"事实摘要"，"★关键"行高亮

### P4.8 雨后春笋同房间重接
- `LiarGameOrchestrator` 加 `_phase: int = 1`（1 = 说谎者，2 = 雨后春笋）
- 胜利后 `_on_win_cinematic_done` → `_start_phase2`：
  1. `_cleanup_phase1_interactables`：把所有 NPC / 观察点 / 提交标记 / 人羊的 Interactable queue_free（保留 sprite 不变）
  2. 隐藏 LevelHUD
  3. 播放 `RainyInRoomCutscene`（dialogue_id = `rainy_in_room_intro`，6 行衔接过场，包含面具内衬提示、远处狗叫、桌子可转）
  4. 过场结束 → 显示 `RotateGameHud` + 启动 `RotateGameController.start_game()` + 解锁玩家
- `LiarGameOrchestrator._unhandled_input`：phase 2 时按 E 调 `_rotate_ctrl.add_rotation()`
- `_on_rotate_ended` 处理 phase 2 结果：
  - WIN → `+3 道` + ResultScreen + `_spawn_exit_to_yucheng`
  - LOSE → ResultScreen（"鱼叉穿透"）
- 老的独立 `rainy_field.tscn` 不删除，作为"独立测试场景"保留

### P4.10 收尾
- 全部 lint 通过 ✓
- 新增 2 个测试文件：`test_observation_clues.gd`（7 case）、`test_notebook.gd`（6 case）
- 修改 5 个文件，新增 4 个文件，删除 0 个
- 注册 1 个新 autoload：`Notebook`

## 文件改动

```
新增
├── docs/superpowers/plans/2026-06-02-p4-final.md
├── docs/tech-verification-p4-final/report.md
├── src/scripts/liar_game/npc_mood_bubble.gd
├── src/scripts/ui/notebook.gd
├── tests/unit/test_observation_clues.gd
└── tests/unit/test_notebook.gd

修改
├── project.godot                                            (+ Notebook autoload)
├── src/scenes/world/interview_room.tscn                     (+ RainyInRoomCutscene / RotateGameController / RotateGameHud)
├── src/scripts/liar_game/liar_game_controller.gd            (+ random_seed / get_rng)
├── src/scripts/liar_game/liar_game_orchestrator.gd          (+ phase 2 全流程 / c3 道币 / 环境观察 hint)
├── src/scripts/liar_game/liar_room_builder.gd               (+ mood bubble / 3 观察点)
├── src/scripts/dialogue/dialogue_database.gd                (+ 3 观察对话 / 灵光闪现 / 同房间衔接过场)
├── src/scripts/dialogue/dialogue_controller.gd              (+ observe 钩子 / notebook 写入)
├── src/scripts/save/game_state.gd                           (+ observed_clues + 序列化)
├── src/scripts/interaction/player_interactor.gd             (+ b4 高亮 / 浮动 prompt)
├── src/scripts/ui/level_hud.gd                              (+ c3 道币 Label)
├── src/scripts/ui/rotate_game_hud.gd                        (+ c3 道币 Label)
└── src/scripts/rotate_game/rotate_game_orchestrator.gd      (+ c3 道币奖励)
```

## 玩家视角的体验升级

| 维度 | P4.7 | P4 final |
|---|---|---|
| 走近 NPC | 没视觉反馈 | NPC 亮 +35%，玩家头顶浮 prompt |
| NPC 静态 | 死木桩 | 头顶随机冒"···/?/👀/💭" |
| 投票决策 | 全凭记忆 | 按 N 看笔记本，所有事实清单 |
| 推理途径 | 只能聊 NPC | + 墙/钟/尸体 3 个环境观察 + 满 3 个触发齐夏内省 |
| 胜利反馈 | 直接出门 | 同房间衔接转桌玩法（原作 Ch 11-13 真实节奏） |
| 经济激励 | 无 | 说谎者 +5 道、雨后春笋 +3 道，HUD 实时显示 |
| 调试 | 一次性 | controller 加 random_seed 字段（保留接口） |

## 用户验证步骤

1. **Godot 编辑器 → 项目 → 重新加载当前项目**（让新 autoload Notebook 加载）
2. **GUT → Run All**：预期 90+ 个 case 全过
3. **F5 试玩**重点观察：
   - 开场过场播完，看到 8 NPC + 桌上 3 个发光小点（墙边/座钟/尸体）
   - 走近任一 NPC，**TA 整体颜色变亮**、玩家头顶冒出黄字 prompt
   - 站在原地等 5-10 秒，看 NPC 头顶有没有冒"···"或"?"
   - 按 **N** 打开笔记本（空 → 提示去聊）
   - 跟 3 个 NPC 各聊 v1+v2+v3，再按 N 查看：笔记应该有人名条目
   - 走到墙边/座钟/尸体各按 E → 满第 3 个时**自动触发齐夏 4 行内省**
   - 走到桌上的提交标记按 E → 投票面板底部有醒目的「写下「人羊」」按钮
   - 投人羊 → 看胜利演出（不再有出口门！）→ 直接接「同房间衔接过场」→ 显示 RotateGameHud → 按 E 转桌 100 圈
   - 转够 100 圈 → 春笋胜利演出 +3 道 → **此时**才出现通往玉城的出口
   - 投错或转桌超时 → 各自的 LOSE 演出
4. **道币显示**：胜利后 HUD 右下角应显示 `🪙 X 道`

## 已知遗留 / 后续

- ✅ P4 阶段彻底告别
- 下一阶段建议 P5.5（跨场景玩家状态持久化）或 P7（玉城真正的骨架），然后 P8+ 新生肖关卡
- **美术 sprint**（d2/d3）独立排期：NPC 像素立绘、房间贴图替换占位

## 写作纪律

P4 final 新增的所有对话内容（22 条 Notebook 摘要 + 3 段观察 + 4 行灵光闪现 + 6 行衔接过场）均为本项目自创笔触：
- **保留**：人物姓名、籍贯、职业、关键剧情节点（事实参考）
- **改写**：所有句式、措辞、节奏、内心独白均原创
- 原作《十日终焉》全文存于 `docs/source/shiri_zhongyan.txt`，仅供开发期校对，不入游戏 build
