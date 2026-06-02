# P9 · 道具效果填实

**目标**：把 P7 商店买的 4 件道具从"占位"变成"真的有用"，给玩家一个**有意义的经济决策**（攒道→ 买什么→ 关键时刻用什么）。

**Scope**：4 件道具全部生效，每件设计一个明确的使用入口和效果。

---

## 4 件道具的生效设计

| 道具 | 价格 | 使用入口 | 效果 |
|---|---|---|---|
| 灵闻笔记 | 5 道 | 说谎者关卡按 X | 随机选 1 个未"灵闻"的 NPC → Toast 显示其「清香描述」（部分指向人羊） |
| 桃木防御符 | 8 道 | 说谎者关卡 LOSE 时自动 | 消耗 1 → 不进入失败演出，直接 retry 整关 |
| 休息券 | 3 道 | 玉城里按 R | 抵消"今日 +1 day"推进；HUD 自动提示"按 R 用休息券" |
| 线索袋 | 6 道 | 说谎者关卡按 C | 自动观察 1 个未观察的线索点（wall/clock/corpse），加速灵光闪现 |

### 共同原则
- 没有道具 → 按键无效（Toast 提示"你没有这件道具"）
- 用完后 inventory[id] - 1
- 灵闻笔记/线索袋按 X/C 触发 → 同一关卡内可多次按（每次消耗 1 个）

---

## 实施细节

### 1. 桃木防御符（最高优先级 · 玩家最有感知）
- `LiarGameOrchestrator._on_vote_submitted` 在 LOSE 分支**前**：
  ```
  if GameState.has_item("item_defense_charm"):
      GameState.remove_item("item_defense_charm", 1)
      Toast.show_success("桃木符替你挡了一次「制裁」 ✓")
      call_deferred("_on_retry")
      return
  ```
- 适用：投错 + 超时 两种 LOSE
- 不适用：雨后春笋 phase 2（简化，避免 phase 2 复杂化）

### 2. 休息券（影响日夜推进）
- 新增 `YuchengHud._unhandled_input`：按 KEY_R 检查
  - 必须 `GameState.pending_day_advance == true` 且 `GameState.has_item("item_rest_ticket")`
  - 满足 → 消耗 1 张 + 重置 pending flag + Toast"今日不算 ✓"
- HUD 加一行小 Label：当条件满足时显示"📜 按 R 用休息券抵消今日"

### 3. 线索袋（最简单的"加速"道具）
- `LiarGameOrchestrator._unhandled_input`：按 KEY_C 检查
  - 必须当前 phase = 1（说谎者）+ `has_item("item_clue_bag")` + 至少 1 个未观察线索
  - 满足 → 消耗 1 个 + 找一个未观察的 → `mark_observed` + Toast"线索袋打开了 · 观察到「方格墙/座钟/尸体」"
  - 自动触发 insight 检查（满 3 → 启动 liar_insight 对话）

### 4. 灵闻笔记（最有原作味道 · 9 个"清香摘要"）
- `GameState` 加 `sniffed_npcs: PackedStringArray` + helpers
- `LiarGameOrchestrator._unhandled_input`：按 KEY_X 检查
  - 必须当前 phase = 1 + `has_item("item_smell_note")` + 至少 1 个 NPC 未被"灵闻"
  - 满足 → 消耗 1 个 + 随机选 1 个未灵闻 NPC → Toast / DialogueBox 显示"清香摘要"
- 9 段清香摘要（包括人羊那段最浓的）：全部用我自己的笔触原创，**含一段隐晦点向人羊**的关键提示

---

## 框架扩展

- `GameState.sniffed_npcs` 字段 + helpers + 序列化

## 测试
- 桃木符消耗 + retry hook
- 休息券消耗 + pending flag 清零
- 线索袋消耗 + observed_clue_count 增加
- 灵闻笔记消耗 + sniffed_npcs 增加 + 不重复

## 工作量
约 2-3 小时净开发。

## 后续 P9.5（不在本范围）
- 道具效果在 RatGame / 雨后春笋也生效（目前只覆盖说谎者）
- 商店道具种类扩展（如"重置 NPC v3"、"延长时限 60s"等）
