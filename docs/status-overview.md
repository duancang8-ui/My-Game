# 项目状态总览

> 最后更新：2026-06-02（v0.9-items-live 之后）
>
> 这是项目的"驾驶舱仪表盘"。每完成一个 tag 来更新一次。
> 看完这一份你就知道：做完了什么 / 在做什么 / 还差什么 / 下一步是什么。

---

## 一句话定位

基于《十日终焉》改编的 2.5D 等距 · 规则怪谈轮回 · 半开放探索 · 推理解谜 · 同人单机游戏。Godot 4 / GDScript / 非商业。

## 当前可玩内容（5 个里程碑 tag）

```
v0.4-final            说谎者关卡（完整，含同房间春笋衔接）
v0.5.5                跨场景位置持久化
v0.7-yucheng-full     玉城枢纽（8 NPC + 商店 + 任务 + 日夜）
v0.8-rat-warehouse    人鼠仓库（第 3 关）
v0.9-items-live       4 件道具全部生效
```

## 数据快照

| 项 | 数量 |
|---|---|
| Git tag | 13（含历史小 tag） |
| `.gd` 脚本 | 44 |
| 单元测试文件 | 23 / ~120+ case |
| 代码总行数 | 5449 |
| 设计文档（spec / plan / report） | 27 份 |
| 占位美术资源 | 11 张 |
| 关卡场景 | 3（说谎者+春笋 / 雨地 / 人鼠仓库）+ 1 主场景（玉城） |
| 注册 NPC 对话 id | 30+（开场 / 规则 / 8 玉城 + 人鼠关 + 8 说谎者 NPC × 3 轮 + 人羊 × 3 轮 + 3 观察点 + 灵光闪现） |

## 完整玩法循环

```
[玉城枢纽]
   ↓ 走中央南门
[面试房间 · 说谎者]
   投人羊 → 同房间衔接 [雨后春笋]（按 E 转 100 圈）
   赢 → 蓝光门回玉城（+5 + +3 道）
   输 → ResultScreen → retry（道币不变）
   ↓ 走东区门
[人鼠仓库]
   付 1 道入场 → 5 分钟翻箱 → 看贴纸 → 摸人鼠口袋 → 赢（+2 净奖励）
   输 / 走 → 回玉城（损失 1 道）
   ↓ 西区
[商店]
   4 件道具：灵闻笔记 5 / 桃木防御符 8 / 休息券 3 / 线索袋 6
   全部生效，全部有专门快捷键（X / 自动 / R / C）
```

## 框架就位的系统

```
✅ 对话系统          DialogueDatabase / Runner / Box / Controller
                    + choice action_id + dialogue_ended_with_id signal
✅ 交互系统          PlayerInteractor + Interactable（4 类型：DIALOGUE/PICKUP/SCENE_CHANGE/VOTE）
                    + 走近高亮 + 浮动 prompt
✅ 场景切换          SceneManager 黑屏 fade + 自动连 SCENE_CHANGE Interactable
✅ 跨场持久化        scene_positions + day/cycle 自动推进
✅ 存档              SaveSystem ConfigFile · F9/F10 · 包含全部 GameState
✅ 任务系统          QuestState 3 步线性链 + 钩子（dialogue/scene）
✅ 道具/经济         inventory + try_purchase + 4 道具 4 入口
✅ HUD 矩阵          LevelHUD / RotateGameHud / RatGameHud / YuchengHud / Notebook / VotePanel / ShopPanel / ResultScreen
✅ 演出系统          CutsceneController 复用 + LiarCinematic fade（可跳过）
✅ NPC 微表情        每个 NPC 随机 ···/?/👀/💭 气泡
✅ 笔记本            Notebook autoload · 按 N · 22 条事实自动汇总
✅ 任务系统钩子      DialogueController.choice_picked_action 让 Orchestrator 拦截副作用
```

## 尚未做的事（按优先级）

### 🔴 P10+ 内容深度
- 再做 2-3 个生肖关（人鸡/人猴/人虎...原作 12 生肖目前只 3 个）
- 「Cycle 2 重生 / 其他人失忆」原作核心反转机制
- 齐夏作为玩家的「灵闻」永久能力（不只是道具）
- 朱雀 / 青龙 / 白虎 / 玄武 圣兽层 boss
- 道城 / 涡城 其他两座城市

### 🟡 系统/UX
- 主菜单 / 设置面板（项目直接进面试房）
- 教学引导（玩家不知道按 N/C/X/R）
- 多存档槽 UI
- 音乐 / 音效（完全空白）

### 🟢 美术
- 11 张占位资源（人物/桌子/建筑/UI 9-slice/提交标记/灯）等待替换
- 详见 [art-guidelines.md](./art-guidelines.md) 的资源清单
- **推荐时机**：再做 3 关 + 主菜单 + 教学之后（6 关稳定后一次性铺）

### ⚪ 后期/可选
- 本地化（中→英）
- 手柄支持
- 移动端触屏适配
- 项目 README 翻新 + itch.io 发布准备

## 推荐推进路线

```
Step A（小工，1-2 小时）：
  S2 音频骨架 + S3 道具覆盖其他关 + S1 朱雀演出（P8.5）

Step B（中大工，5-10 小时分多 session）：
  M1 再做 3 个生肖关

Step C（小工，2-3 小时）：
  M2 主菜单 + M3 教学引导

🎨 美术 sprint 介入（一次性出 80+ 资源，重做率 < 10%）

Step D（大工）：
  原作 Cycle 2 重生 + 灵闻能力 + 后期角色支线
```

## 已知技术债

- `_start_dialogue` 是 private 但被外部 call（QuestState / item hooks）
- `RotateGameController.random_seed` 字段没真用上（保留接口）
- 道具效果只覆盖说谎者关；雨后春笋 / 人鼠关道具不生效（S3 已计划修）
- 旧 tag `v0.4-p4-complete` / `v0.4.5-...` / `v0.5-p5-complete` / `v0.6-p6-complete` 是历史里程碑，已被 v0.4-final 等覆盖（不删除以保留 history）
- 存档不兼容跨 P 阶段（每加新字段都默认 0 / 空，玩家旧档不会 crash 但可能字段缺失）

## 项目里的关键文档

```
docs/
├── status-overview.md                  ← 本文件
├── art-guidelines.md                   美术产出规范
├── art-reference/README.md             风格视觉参考
├── source/shiri_zhongyan.txt           原作全文（gitignore，不入 build）
├── superpowers/
│   ├── specs/                          顶层设计文档（含 P4.7 校正注脚）
│   └── plans/                          14 份 plan
└── tech-verification-pX/               12 份验证报告
```
