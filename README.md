# MyGame —《十日终焉》改编游戏（同人）

> 基于杀虫队队员《十日终焉》改编的 2.5D 等距 · 规则怪谈 · 轮回叙事 · 半开放探索 · 同人单机游戏。
> **本项目是同人作品，非商业、为爱发电，尊重原作版权。**
> Godot 4.6.3 LTS / GDScript / 同人模式

---

## 当前状态（v0.12-main-menu-tutorial）

```
🎮 4 个完整生肖关卡 + 1 个主城枢纽 + 完整经济/任务/教学/主菜单
   说谎者（社交推理）  雨后春笋（反应动作）
   人鼠仓库（解谜+赌命） 黑熊地下室（节奏+生存）

📊 数据：53 .gd 脚本 · 24 测试文件 / 140+ case · 6000+ 行 · 11 占位美术
```

完整状态见 [docs/status-overview.md](docs/status-overview.md)。

### 当前里程碑 tag

| Tag | 内容 |
|---|---|
| v0.4-final | 说谎者关卡按原作 Ch1-15 校正 + 同房间春笋 + 笔记本/观察点/道币/微表情/光环 |
| v0.5.5 | 跨场景玩家位置持久化 |
| v0.7-yucheng-full | 玉城枢纽（8 NPC + 商店 + 任务 + 日夜推进） |
| v0.8-rat-warehouse | 人鼠仓库（第 3 关 · 解谜） |
| v0.9-items-live | 4 件商店道具全部生效 |
| v0.9.1-audio-skeleton | AudioManager 接口 + 31 个 SFX/BGM id |
| v0.9.5-items-extended | 道具效果覆盖所有 3 关 |
| v0.10-rat-betting | 人鼠关赌命模式 + 朱雀飞临处决演出 |
| **v0.11-bear-lair** | **黑熊地下室（第 4 关 · 节奏/生存）** |
| **v0.12-main-menu-tutorial** | **主菜单 + 教学引导（5 场景首次提示）** |

---

## 玩家速览

```
启动 → 主菜单（新游戏 / 继续 / 设置占位 / 退出）

「新游戏」→ 面试房间
  · WASD 移动 · E 交互 · N 看笔记本
  · 说谎者关：投人羊即胜（看人羊微表情 + NPC 故事推理）
  · 春笋关：按 E 转桌 100 圈防鱼叉
  → 出蓝光门 → 玉城

玉城（探索枢纽）
  · 右上 HUD：Cycle/Day/🪙 道币/当前任务
  · 中央南门：再回面试房（推 1 天）
  · 西区货摊：4 件道具 5/8/3/6 道
  · 东区废墟：人鼠仓库（普通 / 赌命）
  · 南区：地牛 → 黑熊地下室（90 秒 / 5 ❤️）
  · 按 R：用休息券抵消今日 +1 day

道具效果（4 件，全部生效）
  · 灵闻笔记 X     →  在说谎者/人鼠关闻 NPC（人羊会被指为答案）
  · 桃木防御符      →  自动消耗 · 任何关 LOSE 时挡一次
  · 休息券 R       →  玉城里抵消今日 day +1
  · 线索袋 C       →  在说谎者/人鼠关揭示 1 个隐藏线索
```

---

## 项目结构

```
docs/
├── status-overview.md             ★ 项目仪表盘（最常看）
├── art-guidelines.md              美术产出规范 + 资源清单
├── art-reference/                 视觉风格参考
├── source/                        原作 txt（gitignore，不入 build）
├── superpowers/
│   ├── specs/                     顶层设计文档
│   └── plans/                     17+ 份阶段 plan
└── tech-verification-pX/          13+ 份验证报告

src/
├── assets/                        11 张占位资源（程序化生成）
├── scenes/                        7 个场景（主菜单 + 4 关 + 玉城 + 雨地）
└── scripts/
    ├── audio/                     AudioManager autoload
    ├── bear_game/                 P10 黑熊关
    ├── camera/                    IsoCamera
    ├── cutscene/                  CutsceneController
    ├── dialogue/                  对话系统（Database/Runner/Box/Controller）
    ├── interaction/               Interactable + PlayerInteractor
    ├── items/                     ItemRegistry
    ├── liar_game/                 P4 说谎者
    ├── player/                    Player + Input
    ├── quest/                     QuestState autoload
    ├── rat_game/                  P8 人鼠
    ├── rotate_game/               P6 雨地
    ├── save/                      GameState + SaveSystem
    ├── scene/                     SceneManager
    ├── test/                      场景 builder（YuchengBuilder 等）
    └── ui/                        所有 HUD/面板/Toast/Notebook/MainMenu

tests/
└── unit/                          24 测试 · 140+ case
```

---

## 已注册 Autoload（9 个）

```
GameState         全局状态 + 序列化
SaveSystem        F9/F10 存读档
SceneManager      场景切换 + fade
DialogueDatabase  对话数据
Toast             右上角通知
Notebook          按 N 弹笔记本（22 条事实自动汇总）
QuestState        3 步任务链
AudioManager      SFX/BGM 接口（占位）
TutorialHints     首次进场景提示（5 个）
```

---

## 美术策略

本项目采用 **「程序先行 + 占位美术 + 最后统一替换」**（Greybox 工作流）。详见：
- 📚 [美术参考库](docs/art-reference/README.md) — 对标作品 + AI 生图 prompts
- 📐 [美术规范文档](docs/art-guidelines.md) — 调色板、尺寸、命名、**完整美术 sprint 资源清单（~84 张）**

**何时启动美术 sprint**：完成 5-6 关 + 主菜单 + 教学之后（详见 art-guidelines §11）。
当前 4 关 + 主菜单 + 教学已就绪 → 距离 sprint 还差 1-2 个生肖关。

---

## 开发命令

```bash
# 跑所有单元测试（应 140+ 通过）
godot --headless --path . -s addons/gut/cli/gut_cli.gd -gdir=res://tests/unit -gexit

# 编辑器打开
godot --path . --editor

# F5 运行游戏（自动从主菜单进入）
```

## 开发环境

- Godot 4.6.3 stable（macOS Universal）
- GDScript（启用静态类型）
- GUT 9.x（测试框架）

## 文档入口

- [📊 项目状态总览](docs/status-overview.md) — 看这里就够了
- [📐 美术规范 + 资源清单](docs/art-guidelines.md)
- [📜 顶层设计 spec](docs/superpowers/specs/2026-05-31-shiri-zhongyan-design.md)（含 P4.7 原作校正注脚）
