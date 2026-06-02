# P7 · 玉城主场景骨架（full）· 验证报告

> 阶段：P7 full · v0.7-yucheng-full
> 完成日期：2026-06-02
> 关联 plan：`docs/superpowers/plans/2026-06-02-p7-yucheng-full.md`

## TL;DR

玉城从「24×16 占位空地 + 2 扇门」升级为真正的探索枢纽：
- 30×20 街区，5 块视觉分区（中央街道 / 北休息 / 东废墟 / 南天堂口 / 西商店）
- 8 个站桩 NPC（含原作关键人物：郑英雄 · 顾禹 · 思维 · 聂北）
- 商店：4 个道具，可用「道」购买
- 日夜推进：进面试房间 = +1 day，满 10 天 = +1 cycle
- 任务系统：3 步任务链引导新玩家（找郑英雄 → 进面试房 → 活着回玉城）
- 信息板 HUD：右上角实时显示 Cycle/Day/道币/当前任务

## 5 阶段完成清单

### 阶段 1 · GameState 扩展
- `inventory: Dictionary[String, int]` + add/remove/has/get_item_count
- `try_purchase(item_id, price)` 原子扣款 + 入库
- `pending_day_advance: bool` + mark/consume helpers（防多次触发）
- 序列化全套接入 to_dict/from_dict
- 8 case 测试

### 阶段 2 · ItemRegistry + ShopPanel
- 4 件道具（灵闻笔记 / 桃木防御符 / 休息券 / 线索袋）
- 占位实现（购买流程跑通，效果留作后续 hook）
- ShopPanel CanvasLayer：列表 + 道币显示 + 按钮动态启用/禁用 + ESC 关闭

### 阶段 3 · QuestState autoload
- 静态任务表（3 个内置任务，单线链）
- 钩子：on_dialogue_ended / on_scene_entered
- signal quest_changed 让 HUD 自动刷新
- 6 case 测试

### 阶段 4 · YuchengBuilder 重写 + 8 NPC 对话
- 30×20 街区 + 4 块视觉分区
- 4 个建筑摆设（含碰撞）
- 8 NPC 程序化生成 + 微表情气泡复用 P4 b1
- 中央南侧通往面试房间的暗红光门
- 8 段对话（5 段 v1 + 3 段 v1+v2）写在 dialogue_database
- YuchengOrchestrator：监听 dialogue_ended_with_id → 商店老板对话结束 → 自动弹 ShopPanel

### 阶段 5 · YuchengHud + 日夜推进
- YuchengHud：右上角 Cycle/Day/🪙 + 当前任务
- SceneManager.change_to 在场景切到 interview_room 时 mark_pending_day_advance，切回 yucheng 时 consume
- DialogueController 加 `dialogue_ended_with_id` signal（给 Orchestrator 用）

## 文件改动

```
新增
├── docs/superpowers/plans/2026-06-02-p7-yucheng-full.md
├── docs/tech-verification-p7/report.md
├── src/scripts/items/item_registry.gd
├── src/scripts/quest/quest_state.gd
├── src/scripts/test/yucheng_orchestrator.gd
├── src/scripts/ui/shop_panel.gd
├── src/scripts/ui/yucheng_hud.gd
├── tests/unit/test_inventory.gd
├── tests/unit/test_day_cycle.gd
└── tests/unit/test_quest_state.gd

修改
├── project.godot                                       (+ QuestState autoload)
├── src/scenes/world/yucheng_main.tscn                  (+ ShopPanel/Orchestrator/Hud)
├── src/scripts/save/game_state.gd                      (+ inventory + day-cycle helpers)
├── src/scripts/scene/scene_manager.gd                  (+ day-advance hook + quest hook)
├── src/scripts/dialogue/dialogue_controller.gd         (+ dialogue_ended_with_id signal + quest hook)
├── src/scripts/dialogue/dialogue_database.gd           (+ 8 玉城 NPC 对话)
└── src/scripts/test/yucheng_builder.gd                 (整体重写)
```

## 玩家体验升级

| 维度 | P5.5 之前 | P7 |
|---|---|---|
| 玉城街景 | 24×16 一块红色危险区 | 30×20，5 块视觉分区，4 个建筑 |
| NPC | 0 个 | 8 个，含 4 个原作关键人物 |
| 任务感 | 无 | 顶部任务条 + 3 步引导链 |
| 时间推进 | 无 | 进面试房 = +1 day，10 天 = +1 cycle |
| 经济循环 | 道币只能赚 | 道币可在西区货摊换 4 件道具 |
| 信息透明度 | 隐藏在内部 | HUD 右上角持续显示 Cycle/Day/道币 |

## 用户验证步骤

1. **Godot → 项目 → 重新加载当前项目**（让新 autoload QuestState 加载）
2. **GUT → Run All**：预期 100+ case 全过
3. F5 试玩说谎者 + 雨后春笋 → 走进玉城出口
4. 进入玉城后重点观察：
   - 右上角 HUD：`Cycle 1 · Day 1` + `🪙 8 道`（如果上面胜利了）+ 任务「找到郑英雄」
   - 城市分 5 块视觉分区（中央街道、北草地、东红区、南蓝水、西蓝水）
   - 数得到 8 个 NPC，每个头顶偶尔有 ···/? 等气泡
   - 走近 NPC：整体加亮 + 玩家头顶冒 prompt
   - 跟**郑英雄**（西区，蓝色）聊一遍 → 任务自动推进为「接受面试」，Toast 提示
   - 跟**商店老板**（西区，橙色）聊一遍 → ShopPanel 弹出，可买道具（按 ESC 关）
   - 走中央南侧暗红光门 → 进入面试房间 → 完成关卡回玉城 → HUD `Day` 应该 +1
5. **F9 存档 → 退出 → 重启 → F10 读档**：所有 inventory / cycle / day / 任务进度 / 位置应完整复位

## 已知遗留 / 后续

- 道具效果（灵闻笔记/防御符/休息券/线索袋）尚未触发任何关卡内变化 — 留作 P8/P9 时为新关卡填实
- 任务链目前 3 步线性，未来可扩为可选支线（QuestState 已留 set_current_quest_for_test hook，便于扩展）
- 信息员、聂北、顾禹、思维等 NPC 二轮对话还可加深（v3、v4 拓展）— 当前已足够支撑探索体验
- 商店打开期间玩家仍可移动 — 后续可加临时锁玩家
- **下一站**：建议 P8（第 3 个生肖关卡，让玩家在玉城 ↔ 关卡 ↔ 玉城循环里积累更多道币和经验），或美术 sprint（替换 50+ 占位资源）

## 写作纪律

P7 新增的所有对话（8 NPC × 共 11 段）、4 个道具描述、3 段任务文案，全部为本项目自创笔触。
- 保留：人物姓名（郑英雄/顾禹/思维/聂北）、地名（玉城/涡城/道城）、概念（清香/灵闻/玉/道）— 这些是事实参考
- 改写：所有句式、措辞、节奏、内心独白 — 均原创
- 原作《十日终焉》全文存于 `docs/source/`（已 gitignore），仅供开发期人物背景校对
