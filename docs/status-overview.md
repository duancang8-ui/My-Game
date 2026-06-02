# 项目状态总览

> 最后更新：2026-06-02（v0.12-main-menu-tutorial 之后）
>
> 这是项目的「驾驶舱仪表盘」。每完成一个 tag 来更新一次。
> 看完这一份你就知道：做完了什么 / 在做什么 / 还差什么 / 下一步是什么。

---

## 一句话定位

基于《十日终焉》改编的 2.5D 等距 · 规则怪谈轮回 · 半开放探索 · 推理解谜 · 同人单机游戏。Godot 4 / GDScript / 非商业。

## 当前可玩内容（10 个里程碑 tag）

```
v0.4-final                说谎者关卡（按原作 Ch1-15 校正，含同房间春笋）
v0.5.5                    跨场景位置持久化
v0.7-yucheng-full         玉城枢纽（8 NPC + 商店 + 任务 + 日夜）
v0.8-rat-warehouse        人鼠仓库（第 3 关 · 解谜）
v0.9-items-live           4 件商店道具全部生效
v0.9.1-audio-skeleton     音频骨架 + 31 个 SFX/BGM id
v0.9.5-items-extended     道具效果覆盖所有 3 关
v0.10-rat-betting         人鼠关赌命模式 + 朱雀飞临处决
v0.11-bear-lair           黑熊地下室（第 4 关 · 节奏/生存）
v0.12-main-menu-tutorial  主菜单 + 5 场景教学引导  ← 当前
```

## 数据快照

| 项 | 数量 |
|---|---|
| Git tag | 24（含历史小 tag） |
| `.gd` 脚本 | 53 |
| 单元测试文件 | 24 / ~150+ case |
| 代码总行数 | 6000+ |
| 设计文档（spec / plan / report） | 32 份 |
| 占位美术资源 | 11 张 |
| 关卡场景 | 4（说谎者+春笋 / 雨地 / 人鼠仓库 / 黑熊地下室）+ 1 主场景（玉城）+ 1 主菜单 |
| 注册 NPC 对话 id | 60+ |
| Autoload 单例 | 9（GameState/SaveSystem/SceneManager/DialogueDatabase/Toast/Notebook/QuestState/AudioManager/TutorialHints） |

## 完整玩法循环

```
🎬 启动 → [主菜单] 新游戏 / 继续上次 / 设置（占位）/ 退出

[面试房间 · 说谎者]
   → 投人羊 → 同房间衔接 [雨后春笋]（按 E 转 100 圈）
   赢 → 蓝光门 → 玉城（+5 +3 道）
   输 → 桃木符自动挡（如有） / ResultScreen retry

[玉城枢纽]
   右上 HUD：Cycle/Day/🪙 / 任务条
   📜 按 R：用休息券抵消今日 day +1
   西区货摊 → 4 件道具（5/8/3/6 道）
   中央南门 → 再回面试房（+1 day）
   东区废墟 → [人鼠仓库] 普通 / 赌命
   南区 → [黑熊地下室]（90s / 5 ❤️）

[人鼠仓库]
   付 1 道入场，5 分钟翻箱 → 摸人鼠口袋 → 赢
   赌命输 → 朱雀飞临红色 fade 处决演出

[黑熊地下室]
   付 1 道入场，90 秒 / 5 ❤️
   每 12 秒咆哮：站铁柱旁安全；否则 -1 ❤️
   赢 +10 道（净 +9）

🔊 所有关键事件自动调 AudioManager.play_sfx（占位无声，Output 面板可见日志）

🎓 教学：首次进每个场景自动弹 1 行短提示（只弹 1 次，存档持久化）
```

## 框架就位的系统

```
✅ 对话系统          DialogueDatabase / Runner / Box / Controller
                    + choice action_id + dialogue_ended_with_id + choice_picked_action signal
✅ 交互系统          PlayerInteractor + Interactable（4 类型）
                    + 走近高亮 + 浮动 prompt
✅ 场景切换          SceneManager 黑屏 fade + 自动连 SCENE_CHANGE Interactable
✅ 跨场持久化        scene_positions + day/cycle 自动推进
✅ 存档              SaveSystem ConfigFile · F9/F10 · 包含全部 GameState
✅ 任务系统          QuestState 3 步线性链 + dialogue/scene hook
✅ 道具/经济         inventory + try_purchase + 4 道具 4 入口（X/C/auto/R）
✅ HUD 矩阵          LevelHUD / RotateGameHud / RatGameHud / BearLairHud / YuchengHud
                    + Notebook / VotePanel / ShopPanel / ResultScreen
✅ 演出系统          CutsceneController 复用 + LiarCinematic fade（可跳过）
✅ NPC 微表情        每个 NPC 随机 ···/?/👀/💭 气泡
✅ 笔记本            Notebook autoload · 按 N · 22 条事实自动汇总
✅ 音频接口          AudioManager · 31 个 SFX/BGM id（仅日志）
✅ 教学引导          TutorialHints · 5 个场景首次提示
✅ 主菜单            新游戏 / 继续 / 设置占位 / 退出
```

## 关卡模板矩阵（4 套验证完毕）

| 关 | 模板 | 验证的架构能力 |
|---|---|---|
| 说谎者 | 状态机 + 投票 + 多轮对话 + 演出 + 笔记本 | 社交推理类 |
| 雨后春笋 | 状态机 + 限时 + 重复操作（按 E） | 反应/动作类 |
| 人鼠仓库 | 状态机 + 限时 + 谜题解锁 + 赌命分支 | 解谜/欺骗类 |
| 黑熊地下室 | 状态机 + 限时 + 周期事件 + 安全锚定位 + 体力槽 | 节奏/生存类 |

P11+ 任何新关都能从这 4 个模板里挑最近的抄起。

## 尚未做的事（按优先级）

### 🔴 内容深度（最高 ROI）
- 再做 1-2 个生肖关（候选：人鸡推理 / 人猴 / 人虎，需翻原作 Ch 40+ 找下一波）
- 「Cycle 2 重生 / 其他人失忆」原作核心反转机制（spec 提过但未做）
- 齐夏作为玩家的「灵闻」永久能力（不只是道具）
- 道城 / 涡城 其他两座城市

### 🟡 系统/UX
- 设置面板（音量条 × 3 / 全屏切换 / 难度档）
- 多存档槽 UI（当前 F9/F10 只 slot 0）
- P10.5：黑熊关道具效果（线索袋 / 灵闻笔记暂未接入）

### 🟢 美术
- 11 张占位资源 + 真音频文件
- 详见 [art-guidelines.md](./art-guidelines.md) 美术 sprint 资源清单（~84 张）
- **推荐时机**：再做 1-2 关之后（5-6 关稳定）一次性 sprint

### ⚪ 后期/可选
- 本地化（中→英）
- 手柄 / 移动端触屏
- itch.io / B 站发布准备

## 推荐推进路线

```
A. P10.5（小工 · 1-2 小时）
   - 灵闻笔记在黑熊关：按 X → 暂时延长当前安全区半径
   - 线索袋在黑熊关：按 C → 预警时长 +1 秒

B. M1 第 5 关（中大工 · 3-4 小时）
   候选玩法（待翻原作 Ch 40+ 确认）：人鸡 · 推理找凶手

C. M2.5 设置面板（小工 · 1-2 小时）
   - 音量条 × 3（master/sfx/bgm）
   - 全屏切换
   - 难度档（说谎者 hint 真实率 / 春笋时限 / 黑熊间隔）

🎨 美术 sprint 介入（一次性 ~84 张资源，2-3 周）
   先决条件：5-6 关 + 设置面板 + 简单引导 OK
```

## 已知技术债

- `_start_dialogue` 是 private 但被外部 call（QuestState / item hooks）
- `RotateGameController.random_seed` 字段没真用上（保留接口）
- 灵闻笔记 / 线索袋在黑熊关暂不生效（P10.5 待做）
- 旧 tag `v0.4-p4-complete` / `v0.4.5-...` / `v0.5-p5-complete` / `v0.6-p6-complete` 是历史里程碑（不删除以保留 history）
- 存档不兼容跨 P 阶段（每加新字段都默认 0 / 空，旧档不会 crash 但可能字段缺失）
- 主菜单"继续"按钮在 SaveSystem.load_from_slot 后直接 change_scene_to_file（绕开 SceneManager fade）— 避免 fade 双层，简洁但失去过渡感

## 项目里的关键文档

```
docs/
├── status-overview.md                  ← 本文件
├── art-guidelines.md                   美术产出规范 + 资源清单
├── art-reference/README.md             风格视觉参考
├── source/shiri_zhongyan.txt           原作全文（gitignore，不入 build）
├── superpowers/
│   ├── specs/                          顶层设计文档（含 P4.7 校正注脚）
│   └── plans/                          17+ 份 plan
└── tech-verification-pX/               13+ 份验证报告（含 p10/p4-final/p4.6/p4.7/p7/p8/p9）
```
