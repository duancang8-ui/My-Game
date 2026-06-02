# P7 · 玉城主场景骨架（full 版）

**目标**：把当前的占位玉城（24×16 街区 + 1 个返回门 + 1 个雨地门）升级为真正的"探索枢纽"，让玩家在面试房-玉城-雨地之间形成有意义的循环。

**Scope**：full 版 = 街景 + 8 NPC + 信息板 + 日夜推进 + 商店 + 任务系统骨架。

---

## 设计

### 5 块视觉分区（用 tile atlas 区分）

```
+----------+----------+----------+
|  北区     |          |   东区   |
|  休息区   | 中央街道  |   废墟   |
|          |          |          |
+----------+ ★ 信息员  +----------+
|          |          |          |
|  南区     |   出口    |   西区   |
|  天堂口   |          |   商店   |
+----------+----------+----------+
```

- **中央街道**：地砖（默认 TILE_GROUND），信息员站桩
- **北区·休息区**：草地（TILE_GRASS），路人 A 站桩
- **东区·废墟**：危险红区（TILE_DANGER 视觉，但不真伤害），路人 B、顾禹站桩
- **南区·天堂口**：水（TILE_WATER 蓝色），思维姐 + 聂北
- **西区·商店**：地砖偏色 / mod tint，商店老板 + 郑英雄
- 中央南侧：**面试房入口**门（任务标记，闪烁）

### 8 NPC（站位 + 简短身份）

| ID | 位置 | 身份 | 用途 |
|---|---|---|---|
| `yu_passer_a` | 北区 | 茫然女路人 | 提示"这地方很怪" |
| `yu_passer_b` | 东区废墟 | 受惊男路人 | 提示"东区有怪东西" |
| `yu_gu_yu` | 东区废墟 | 顾禹（云游者） | 暗示"我在三座城之间走来走去" |
| `yu_si_wei` | 南区天堂口 | 思维姐 | 暗示"玉、涡、道" |
| `yu_nie_bei` | 南区天堂口 | 聂北（玉城首领） | 给玩家**任务感**（"去面试房，活下来才能见我"） |
| `yu_shopkeeper` | 西区商店 | 商店老板 | 触发 ShopPanel |
| `yu_zheng_yingxiong` | 西区商店旁 | 郑英雄（清香者） | 关键人物 · 暗示"灵闻"系统 |
| `yu_info_board` | 中央 | 信息员/告示牌 | 解释规则、显示当前 Cycle Day |

### 信息板 HUD（YuchengHud）

右上角 PanelContainer：
```
┌──────────────────┐
│ Cycle 1 · Day 3   │
│ 🪙 8 道           │
│ 任务：找郑英雄    │
└──────────────────┘
```

### 日夜推进

- 玩家从 yucheng → interview_room（说谎者）→ 回 yucheng（春笋胜利）= **+1 day**
- `current_day > 10` → `advance_cycle()`（自动 +1 cycle，day 重置）
- 日夜由 `SceneManager.scene_change_finished` 信号触发：当**目的场景** == interview_room.tscn 且来自 yucheng 时 +1
- 简化实施：在 yucheng_main 的 `_ready` 检测 `GameState.last_scene_was_interview` flag

实施 trick：避免多次推进，加 GameState 一个 flag `_pending_day_advance: bool`，进面试房时设 true，回玉城时检查并清零。

### 商店

- `ItemRegistry`（const Dictionary）定义 4 个道具：
  - `item_smell_note` · 「灵闻笔记」 · 5 道 · 提示下一关概率较高的"安全"操作（占位 buff）
  - `item_defense_charm` · 「桃木防御符」 · 8 道 · 死亡时复活一次（占位）
  - `item_rest_ticket` · 「休息券」 · 3 道 · 跳过 1 个回合不推进 day
  - `item_clue_bag` · 「线索袋」 · 6 道 · 立刻揭示当前关卡的 1 个隐藏线索
- `GameState.inventory: Dictionary[String, int]`
- `ShopPanel` CanvasLayer：显示道具网格、价格、玩家道币、购买按钮
- 购买逻辑：`GameState.dao_count -= price` + `inventory[item_id] += 1`
- 道具实际效果暂不实现（只完成"能买"流程），留为 future hook

### 任务系统

- 新 autoload `QuestState`（轻量）
- 字段：
  - `current_quest_id: String`
  - `current_quest_title: String`
  - `current_quest_hint: String`
  - 进度：`current_quest_progress: int / target: int`
- 初始任务 `find_zheng_yingxiong`：「找到郑英雄，和他聊聊」
- 玩家完成与郑英雄的对话 → 任务完成，自动推进到第二个：「去面试房接受测试」
- QuestHud（也在 YuchengHud 里）：底部 Label 显示当前任务

### 自创笔触保证
8 NPC × 2 行对话 + 4 个道具描述 + 2 个任务文案，**全部用我自己的笔触写**，仅保留原作"人物姓名 + 身份关键词"（顾禹/思维/聂北/郑英雄）作为事实参考数据。

---

## 5 个阶段（每段 lint，最后一次 commit）

1. **GameState 扩展**（inventory + day/cycle helpers + 序列化）+ 测试
2. **ItemRegistry + ShopPanel** + 测试
3. **QuestState autoload** + 测试
4. **YuchengBuilder 重写**（5 分区、8 NPC、商店、任务标记）+ NPC 对话注册到 dialogue_database
5. **YuchengHud**（信息板 + 任务提示）+ 日夜推进钩子（接 SceneManager 信号）

完成后：
- 全套 lint
- 写 P7 报告
- commit + tag `v0.7-yucheng-full`

---

## 风险

- 8 NPC 站位 + 5 区域 → builder 代码超 300 行，要分子函数清晰
- ShopPanel 用现有 BTN_/PANEL_ 9-slice 资源
- QuestState 是新 autoload，要在 project.godot 注册
- 日夜推进可能在 retry 时被误触发 → 用 flag 防重
