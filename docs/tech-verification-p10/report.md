# P10 · 地牛 · 黑熊地下室 · 验证报告

> 阶段：P10 · v0.11-bear-lair · 第 4 个生肖关卡
> 完成日期：2026-06-02
> 关联 plan：`docs/superpowers/plans/2026-06-02-p10-bear-lair.md`

## TL;DR

第 4 个生肖关卡上线，玩法模板再扩一个："**周期性事件 + 安全锚定位**" 模型。

```
入口  玉城南区灰房子门口 · 地牛 NPC（戴干净水牛面具的黑西装）
       门票 1 道
       玉城里有眼镜男 NPC 给前奏（含规则暗示）

场景  暗色地下室 16×10
       中央铁圆板 · 3 根铁柱（玩家躲咆哮的安全锚）
       一只 2m 巨型黑熊 sprite（颈部白月牙）

规则  90 秒倒计时（原作 10 分钟，game-feel 压缩）
       每 12 秒一轮：[0-9s] 自由 → [9-12s] 预警 → 判定
       判定时玩家在铁柱 60 像素内 = 安全；否则 -1 体力
       体力 0 = LOSE；时限到 = WIN

奖励  WIN +10 道 / LOSE 失去门票 1 道
道具  桃木防御符 LOSE 时自动消耗 → 重置体力 + 计时
       灵闻笔记 / 线索袋暂不接入（留 P10.5）
```

## 实施清单

### 控制器（纯逻辑）
- `BearGameController` 状态机 READY → PLAYING → ENDED
- 5 个 signal：time_changed / stamina_changed / roar_warning / **roar_judgement_needed** / roar_impact / game_ended
- 同步信号设计：判定瞬间 emit `roar_judgement_needed`，监听器同步调 `apply_roar_judgement(safe)` 完成扣体力
- 11 个单元测试 case

### 场景生成（视觉）
- `BearLairBuilder`：16×10 暗色地下室 + 4 面墙碰撞 + 中央铁板 + 3 根铁柱 + 黑熊 sprite（含白月牙）+ 离开门
- `is_player_safe(player_pos)` 暴露给 orchestrator 查询
- `play_roar_shake()` 黑熊咆哮时的视觉震动（modulate 红闪 + 复位）

### HUD
- `BearLairHud`：顶部中央时间 + 体力（5 颗心 → 死亡骷髅）
- 中央咆哮预警 banner（闪烁 3 秒）
- 右下道币（自动 polling）

### 流程编排
- `BearGameOrchestrator`：
  - intro cutscene（bear_lair_intro）→ start_game
  - 每帧响应 controller 信号 → 更新 HUD / Toast / SFX
  - 咆哮判定瞬间查 builder.is_player_safe → controller.apply_roar_judgement
  - WIN +10 道 + 演出 → 回玉城
  - LOSE 先试桃木防御符；没有 → 演出 → 回玉城

### 玉城接入
- `YuchengBuilder.NPCS` 加 2 个新 NPC：
  - 眼镜男（拉客，bear_eyeglass_pitch）位于中央街道
  - 地牛（黑西装，bear_earth_cow_pitch，special="game"）位于南区
- `YuchengOrchestrator` 监听 `action_id == "enter_bear_lair"` → 扣 1 道 + 切场景

### 对话（全部原创笔触）
13 段新对话：
- `bear_eyeglass_pitch` 3 段（拉客 + 解释 + 引路）
- `bear_earth_cow_pitch` 3 段（地牛自介 + 规则 + 风险提示）
- `bear_lair_intro` 5 段（下楼 + 地牛闭门 + 黑熊登场 + 玩法暗示）
- `bear_win` / `bear_lose` 各 1-2 段

## 文件改动

```
新增
├── docs/superpowers/plans/2026-06-02-p10-bear-lair.md
├── docs/tech-verification-p10/report.md
├── src/scenes/world/bear_lair.tscn
├── src/scripts/bear_game/bear_game_controller.gd
├── src/scripts/bear_game/bear_game_orchestrator.gd
├── src/scripts/bear_game/bear_lair_builder.gd
├── src/scripts/ui/bear_lair_hud.gd
└── tests/unit/test_bear_game_controller.gd

修改
├── src/scripts/dialogue/dialogue_database.gd      (+ 13 段对话)
├── src/scripts/test/yucheng_builder.gd            (+ 眼镜男 + 地牛 NPC)
└── src/scripts/test/yucheng_orchestrator.gd       (+ enter_bear_lair action)
```

## 关卡模板矩阵（4 关验证完毕）

| 关 | 模板 | 验证的架构能力 |
|---|---|---|
| 说谎者 | 状态机 + 投票 + 多轮对话 + 演出 + 笔记本 | 社交推理类 |
| 雨后春笋 | 状态机 + 限时 + 重复操作（按 E） | 反应/动作类 |
| 人鼠仓库 | 状态机 + 限时 + 谜题解锁 + 赌命分支 | 解谜/欺骗类 |
| **黑熊地下室** | 状态机 + 限时 + 周期事件 + 安全锚定位 + 体力槽 | 生存/节奏类 |

P11+ 任何新关都能从这 4 个模板里挑一个最近的抄起。

## 用户验证步骤

1. **Godot → 项目 → 重新加载当前项目**
2. **GUT → Run All**：预期 **140+ case 全过**（含 11 个 P10 新 case）
3. F5 完整跑：
   - 玉城里走到中央，跟**戴眼镜的良人**（淡蓝色 NPC）聊一遍 → 听完描述往南走
   - **南区**最西侧找一个**黑色 NPC**（地牛）→ 按 E → 听规则 → 选"付 1 道入场"
   - 进地下室 → 看 intro 过场（5 段，按 E 翻完）
   - 顶部 HUD：`⏳ 1:30` + `❤️ ❤️ ❤️ ❤️ ❤️`
   - 每 12 秒：中央会出现红色"⚠️ 黑熊准备咆哮"banner
   - 跑到任意铁柱（左上/右上/下方）旁 60 像素内
   - 咆哮判定：站对 → Toast"躲过去了" + SFX；站错 → -1 体力 + Toast"被冲击波刮中"
   - 撑过 90 秒 → +10 道 + 胜利演出 → 回玉城
   - 体力归零 → LOSE 演出 / 或被桃木符接住自动重置

## 已知遗留 / 后续

- 灵闻笔记 / 线索袋在黑熊关暂不生效（留 P10.5）
- 黑熊不会主动追玩家（只是定时咆哮 sprite），未来可加 AI 巡逻
- 体力槽数值 / 咆哮间隔需 playtest 调（5 体力 + 12 秒间隔是 first pass）

## 写作纪律

P10 新增的 13 段对话 + UI 文案 + 内省旁白全部为本项目自创笔触。
- 保留：人物身份（地牛 / 眼镜男 / 黑熊 / 「良人」/ 「道」/ 通关人数 = 道数 反差）等事实参考
- 改写：所有具体描述、句式、措辞均原创
- 原作《十日终焉》全文存于 `docs/source/`（gitignore），仅供开发期机制校对
