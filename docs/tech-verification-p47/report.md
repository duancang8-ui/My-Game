# P4.7「说谎者」原作校正 · 验证报告

> 阶段：P4.7 重度校正（机制反转 + 8 NPC 改名 + 玉城重命名 + 对话重写）
> 完成日期：2026-06-02
> 关联 plan：`docs/superpowers/plans/2026-06-02-p47-canon-correction.md`
> spec 注脚：`docs/superpowers/specs/2026-05-31-shiri-zhongyan-design.md` 头部"P4.7 原作校正注脚"

## TL;DR

按原作《十日终焉》Ch 1-15 重新校正"说谎者"关卡：
- 所有 9 位参与者（玩家 + 8 NPC）都抽到说谎者牌
- 唯一可投赢的是「人羊」
- 8 NPC 按原作姓名（删陈俊南/苏闪，加李尚武/甜甜）
- 主城从「道城」改为「玉城」
- 所有对话**用自创笔触重写**，保留原作人物设定（姓名/籍贯/职业/关键剧情节点）但不复制原作具体段落

## 完成清单

### 机制层
- ✅ `LiarGameController` 移除 hint 系统（`hint_target_id` / `hint_truth_probability` / `_roll_hint_target` / `liar_target_id` 全部删除）
- ✅ 投票判定反转：`target == SHEEP_MASTER → WIN`，否则 `LOSE (reason="wrong_vote")`
- ✅ 超时仍是 `force_lose("time_up")`
- ✅ 倒计时 / 信号 / reset 保留 P4.6 行为

### NPC ID 层
- ✅ `LiarNpcId` 重写：8 位参与者 + `SHEEP_MASTER` 常量
- ✅ 新增 `ALL_VOTE_TARGETS`（8 NPC + 人羊）
- ✅ 加 `ORIGINS` / `PROFESSIONS` / `is_sheep_master()` helper
- ✅ 旧名字 chen_junnan / su_shan / zhang_lijuan 删除（zhang_lijuan 作为甜甜本名留在剧情里）

### VotePanel
- ✅ "人羊"按钮单独渲染、暗红高对比色、放在 NPC 名单底部
- ✅ 标题改为"你要在纸上写下谁的名字？"（呼应原作"写在纸上"）

### Orchestrator
- ✅ 删 `_show_sheep_hint`，新增 `_show_environment_clue`（暗示玩家观察房间方格、座钟、"九位"措辞）
- ✅ WIN 文案改为：纸上 9 张「人羊」一致 → 人羊自杀
- ✅ LOSE 文案分流：`time_up` / `wrong_vote` 各有不同台词
- ✅ 胜利后 spawn 通往**玉城**的门

### LiarRoomBuilder
- ✅ 8 NPC 围坐（自动用 `LiarNpcId.ALL.size()`）
- ✅ 人羊作为可对话 NPC（dialogue_id = "liar_sheep_master"）
- ✅ 提交标记 `submit_marker` 保留，作为"在纸上写下名字"的触发点

### 对话数据
全部用自创笔触重写：
- ✅ 开场过场 11 行：齐夏醒来、十人围桌、座钟、方格墙、人羊登场、当场杀献祭品让大家安静
- ✅ 规则过场 9 行：人羊宣布"说谎者"规则、发卡、齐夏自己抽到说谎者
- ✅ 8 NPC × 3 套对话（v1 自介 / v2 讲故事 / v3 互相观察）
- ✅ 人羊 NPC × 3 套对话（v1 嘟囔 / v2 讲"创造神" / v3 含糊回避）
- ✅ 每个 NPC v3 都暗含**指向人羊**的线索（呼吸节奏、空气不足、"叙述者"不可靠、单手碎头骨等）

### 全局重命名 道城 → 玉城
- ✅ `daocheng_main.tscn` → `yucheng_main.tscn`
- ✅ `daocheng_builder.gd` → `yucheng_builder.gd`
- ✅ `rotate_game_orchestrator.gd` 雨地返回门指向 yucheng
- ✅ `toast.gd` 注释、`test_game_state.gd` 字符串
- ✅ Toast/HUD/标签文案

### 测试
- ✅ 删 `test_liar_hint_targeting.gd`（hint 系统不存在）
- ✅ 重写 `test_liar_game_controller.gd`（9 个新 case：投人羊=赢、投每个参与者=输等）
- ✅ 修 `test_liar_timer.gd`（去掉 `liar_target_id` 依赖）
- ✅ 修 `test_game_state_visit_count.gd`（用 `liar_li_shangwu` 替换 `liar_chen_junnan`）
- ✅ 修 `test_liar_dialogue_selector.gd`（用新名字）
- ✅ 修 `test_game_state.gd`（路径 daocheng → yucheng）

### Spec 校正
- ✅ spec 头部加 P4.7 注脚表格，列出所有偏差

## 文件改动统计

```
A  docs/source/shiri_zhongyan.txt          （UTF-8 全文，仅本地参考）
A  docs/superpowers/plans/2026-06-02-p47-canon-correction.md
A  docs/tech-verification-p47/report.md
A  src/scenes/world/yucheng_main.tscn
A  src/scripts/test/yucheng_builder.gd

M  docs/superpowers/specs/2026-05-31-shiri-zhongyan-design.md  (+ P4.7 注脚)
M  src/scripts/dialogue/dialogue_database.gd                   (整体重写)
M  src/scripts/liar_game/liar_npc_id.gd                        (重写：8 NPC + 人羊)
M  src/scripts/liar_game/liar_game_controller.gd               (删 hint + 反转判定)
M  src/scripts/liar_game/liar_game_orchestrator.gd             (文案 + 流程)
M  src/scripts/liar_game/liar_room_builder.gd                  (8 NPC + 人羊可交互)
M  src/scripts/ui/vote_panel.gd                                (人羊按钮)
M  src/scripts/rotate_game/rotate_game_orchestrator.gd         (玉城)
M  src/scripts/ui/toast.gd                                     (注释)
M  src/scenes/world/interview_room.tscn                        (LevelHUD npc 列表)
M  tests/unit/test_liar_game_controller.gd                     (重写)
M  tests/unit/test_liar_timer.gd                               (适配)
M  tests/unit/test_game_state_visit_count.gd                   (新名字)
M  tests/unit/test_liar_dialogue_selector.gd                   (新名字)
M  tests/unit/test_game_state.gd                               (yucheng)

D  src/scenes/world/daocheng_main.tscn
D  src/scripts/test/daocheng_builder.gd
D  tests/unit/test_liar_hint_targeting.gd                       (hint 系统不存在了)
```

## 玩家可感知的变化

| 维度 | P4.6 | P4.7 |
|---|---|---|
| 投票候选 | 9 NPC | **8 NPC + 人羊**（人羊按钮单独显眼） |
| 正解 | 9 个 NPC 中 1 个 | **「人羊」** |
| 人羊暗示 | 顶部红字给出指向某 NPC | 改为玩家自己的"内心观察"（方格、空气、九位措辞） |
| 角色名 | 陈俊南 / 苏闪等 | 李尚武 / 甜甜（原作姓名） |
| 主城名 | 道城 | 玉城 |
| 关卡谜底走向 | 找到说谎者 | 注意到"叙述者"（人羊）才是讲故事的人 |

## 用户验证步骤

1. **Godot 编辑器 → 项目 → 重新加载当前项目** （让所有删/改/新增文件生效）
2. **GUT 面板 → Run All**：所有测试通过
3. **F5 试玩 InterviewRoom**：
   - 看到开场过场新内容（十人围桌、座钟、当场杀献祭品）
   - 规则过场玩家自己看到"说谎者"身份牌
   - 8 NPC 围坐（数一下，确认是 8 个）
   - 走到桌中央按 E → 投票面板底部有醒目的「[ 写下「人羊」 ]」按钮
   - 试投任意 NPC → LOSE 演出
   - 试投人羊 → WIN 演出 + 出现"出口·玉城"光门
   - 走出门 → 进入 玉城（原 daocheng）
4. **重点观察**：跟 NPC 聊 3 轮后，v3 对话里是否有暗示玩家"投人羊"的线索

## 写作纪律声明

P4.7 重写的所有对话内容均为本项目自创笔触：
- **保留**：人物姓名、籍贯、职业、被抓前的事件类型（这些是事实参考信息）
- **改写**：所有具体台词、句式、节奏、内心独白、选项交互均为原创
- 原作《十日终焉》UTF-8 全文存于 `docs/source/shiri_zhongyan.txt`，仅供开发期校对，不进游戏 build

## 已知遗留 / 后续

- **P4.8**：把"雨后春笋"从独立场景移到与说谎者**同一房间**（原作里两个关卡发生在同一房间）
- **P4.9**：加入"房间体积 vs 9 人呼吸"线索的可观察细节（让玩家自己能推出"我们已经死了"）
- **P5.5**：跨场景玩家状态持久化（进雨后春笋再回玉城）
- **P7**：玉城真正的主场景骨架（替代当前占位）
- **存档兼容**：旧存档的 `npc_visit_count` key 仍是旧名字 → 重置一次即可
