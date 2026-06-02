# P9 · 道具效果填实 · 验证报告

> 阶段：P9 · v0.9-items-live
> 完成日期：2026-06-02
> 关联 plan：`docs/superpowers/plans/2026-06-02-p9-items-live.md`

## TL;DR

P7 商店买的 4 件道具全部生效，玩家终于有"攒道→ 买道具→ 关键时刻消耗"的完整经济决策环：

| 道具 | 入口 | 效果 |
|---|---|---|
| 桃木防御符 | 说谎者关 LOSE 时**自动** | 消耗 1 → 不进失败演出 → 关卡 retry |
| 休息券 | 玉城里**按 R** | 抵消"今日 +1 day"推进，HUD 自动提示按 R |
| 线索袋 | 说谎者关**按 C** | 随机揭示 1 个未观察的环境线索点 |
| 灵闻笔记 | 说谎者关**按 X** | 随机闻 1 个未灵闻 NPC → Toast 显示「清香摘要」，含点向人羊的关键提示 |

## 实施清单

### 1. 桃木防御符
- `LiarGameOrchestrator._on_vote_submitted` LOSE 分支前增加 `_try_consume_defense_charm()`
- 适用：投错 + 超时；不适用 phase 2（雨后春笋）

### 2. 休息券
- `YuchengHud` 加 `_rest_hint_label` —— pending_day_advance + has_item 时自动可见
- `_unhandled_input` 监听 KEY_R → 消耗 1 + 清 pending flag + Toast

### 3. 线索袋
- `LiarGameOrchestrator._unhandled_input` 监听 KEY_C
- 找一个 `_CLUE_LABELS` 里未观察的（wall/clock/corpse）→ 消耗 + mark_observed + Toast
- 自动触发 liar_insight 灵光闪现（满 3 个）

### 4. 灵闻笔记
- `GameState.sniffed_npcs: PackedStringArray` 新字段 + helpers (mark_sniffed / has_sniffed) + 序列化
- `LiarGameOrchestrator._unhandled_input` 监听 KEY_X
- 找一个未灵闻的（含人羊共 9 个）→ 消耗 + mark_sniffed + Toast 显示 1 句"清香摘要"
- **人羊的描述明确点向"答案的方向"**，让带灵闻笔记的玩家有"作弊器"般快感

## 9 段清香摘要（全部本项目自创笔触）

每段都是简短 1 句话描述：人羊那段强调"不属于人的味道"作为关键提示，其他 8 个 NPC 都是"普通人"+ 一个个人化的味道线索，原创风格。

## 文件改动

```
新增
├── docs/superpowers/plans/2026-06-02-p9-items-live.md
├── docs/tech-verification-p9/report.md
└── tests/unit/test_items_live.gd

修改
├── src/scripts/save/game_state.gd                    (+ sniffed_npcs + mark/has_sniffed + 序列化)
├── src/scripts/ui/yucheng_hud.gd                     (+ rest hint Label + R 键处理)
└── src/scripts/liar_game/liar_game_orchestrator.gd   (+ 桃木符截胡 + C/X 键处理 + 9 段清香摘要)
```

## 玩家体验升级

| 道具 | 没买之前 | 买了之后 |
|---|---|---|
| 桃木防御符 | 投错 = 必须 retry 整套（含开场过场） | 投错 = 关卡瞬间重置（保留当前 day/进度） |
| 休息券 | 进面试房 = 必 +1 day → 加速 cycle 推进 | 想慢慢练习时可冻结时间 |
| 线索袋 | 必须自己跑遍 3 个观察点 | 直接坐着按 C 揭示，加速通关 |
| 灵闻笔记 | 推理只能靠对照 NPC 对话 | 多一条"嗅觉线索"路径，闻到人羊就知道答案 |

## 用户验证步骤

1. **Godot → 项目 → 重新加载当前项目**
2. **GUT → Run All**：预期 120+ case 全过
3. F5 完整跑：
   - 玉城里**先攒道**（说谎者 +5、春笋 +3、人鼠 +2 = 10 道）
   - 去西区商店 → 买 1 个桃木防御符（8 道）+ 1 张休息券（3 道）→ 等等，10 道只够买防御符
   - 也可以买线索袋（6 道）+ 灵闻笔记（5 道）
4. **桃木防御符测试**：进面试房 → 故意投错 → 应该看到 Toast "桃木符替你挡了一次" + 关卡自动 retry（不弹失败演出）
5. **线索袋测试**：进面试房后立刻按 **C** → Toast 显示 "线索袋打开了 ✓ 你「看到」了：墙上的方格"（或其他）
6. **灵闻笔记测试**：进面试房后按 **X** → Toast 显示某 NPC 的"清香摘要"。多按几次 → 不同 NPC 轮流出。**特别注意闻到人羊那次，提示「不属于人的味道」**
7. **休息券测试**：从面试房回玉城后，HUD 应该多了一行 "📜 按 R 用休息券抵消今日" → 按 R → Toast "撕掉一张休息券 ✓ 今日不算"，Day 不变

## 已知遗留 / 后续

- 道具效果只覆盖说谎者关卡和玉城；雨后春笋 phase 2 / 人鼠仓库暂时不生效（留 P9.5）
- 灵闻笔记目前用 Toast 显示摘要，长文字可能截断 —— 后续可换专门的"灵闻面板" UI
- 桃木符在雨后春笋失败时不生效（设计上避免 phase 2 状态混乱）—— 留 P9.5
- 商店道具种类没扩展 —— 可在 P10+ 增加新道具

## 写作纪律

P9 新增的 9 段清香摘要 + Toast 文案 + 休息券提示文本均为本项目自创笔触。
- 保留：人物姓名（人羊/甜甜/乔家劲/韩一墨/章晨泽/李尚武/林檎/赵海博/肖冉）、原作概念（清香/灵闻/道）作为事实参考
- 改写：所有具体描述、句式、措辞均原创
- 原作《十日终焉》全文仅供开发期校对，不入 build
