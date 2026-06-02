# AGENTS.md — 这份给"下一个进来的你"

> 任何 AI 助手 / 任何换电脑后第一次打开此项目的 session，**先读这一份**（< 10 分钟）。
> 它不是流水账，是浓缩的**项目身份 + 关键决策 + 写作纪律 + 常见坑**。
> 配合 `docs/status-overview.md`（仪表盘）+ `docs/handoff-2026-06-02.md`（最近一次 hand-off）食用。

---

## 1. 项目身份（30 秒 grok）

```
名字     ：MyGame —《十日终焉》改编同人游戏
原作     ：杀虫队队员《十日终焉》（番茄小说 2022.12 – 2024.10 完结 1496 章）
改编范围 ：第 1 章 ~ 第 110 章（齐夏觉醒弧）
模式     ：同人 · 非商业 · 为爱发电（itch.io / B 站 / GitHub Pages）
引擎     ：Godot 4.6.3 stable LTS · GDScript · 启用静态类型
视角     ：2.5D 等距（TileMap Diamond Down + Y-sort）
平台     ：PC 首发，移动端二期（spec 提过，触屏未实现）
```

**项目根目录**：`~/Desktop/MyGame`。
**当前 tag**：`v0.12-main-menu-tutorial`（截至 2026-06-02）。

---

## 2. 核心约束（违反 = 大事故）

### 2.1 IP / 版权（**最重要**）

原作《十日终焉》是已出版的版权小说。本项目改编为同人作品时遵守：

```
✅ 可以原样保留（事实参考数据）：
   - 人物姓名（齐夏、人羊、人鼠、地牛、朱雀、郑英雄、顾禹、思维、聂北、
     甜甜、乔家劲、韩一墨、章晨泽、李尚武、林檎、赵海博、肖冉 等）
   - 地名（玉城、涡城、道城、面试房间）
   - 概念（清香 / 灵闻 / 「道」/ 十日终焉 / 圣兽 / 制裁）
   - 游戏机制（说谎者投人羊 / 雨后春笋转桌 / 仓鼠藏颊袋 / 黑熊咆哮 等
     — 这些是规则/事实，不是受版权保护的"表达"）
   - 关键剧情节点（齐夏抽到说谎者卡 / 人羊自杀 / 面具内衬有字 / 
     朱雀飞临处决 等 — 作为事实参考）

❌ 严格禁止：
   - 复制原作任何具体段落、台词、内心独白
   - 「微调几个字 / 替换同义词」式的伪改写也算复制
   - 把原作 txt 文件入 git（已在 .gitignore：`docs/source/`）

✅ 做对的方式：
   - 读原作 → 理解人物 / 机制 / 节奏
   - 用**自己的笔触从头写**对话、叙述、内心独白
   - 让读过原作的人感觉"对，是这一场戏"
   - 但每一句话都是新写的（句式 / 措辞 / 节奏 / 意象）

历史背景：P4.7 阶段（commit d715ae8）就是因为发现说谎者关卡机制
跟原作完全相反才做的大重构。当时用户明确指示"按原作来，不用担心
侵权"——但 AI 仍要拒绝"复制具体文字"，因为版权方不是用户。
```

### 2.2 GDScript 字符串引号

```
❌ 绝对不要在字符串里用英文双引号 "xxx"
✅ 全部用中文角括号 「xxx」 或 『xxx』

教训：曾因为 dialogue_database.gd 里 "我是说谎者" 触发 parse error，
导致 5 个文件连锁编译失败 + Godot 崩溃（截图见 chat history）
```

### 2.3 Autoload 与 main_scene

```
当前 9 个 autoload，顺序敏感（GameState 必须最先加载）：
  GameState / SaveSystem / SceneManager / DialogueDatabase /
  Toast / Notebook / QuestState / AudioManager / TutorialHints

main_scene = uid://bmainmenu1（main_menu.tscn）
改之前请确认主菜单的"新游戏"/"继续"流程还能跑通
```

---

## 3. 架构速览（30 秒地图）

```
玩法循环：
  [主菜单] → 新游戏/继续 → 
  [面试房间] 说谎者 → 同房间 → 雨后春笋 → 
  [玉城枢纽] → 商店 / 任务 / 4 关入口 →
  [人鼠仓库] 或 [黑熊地下室] 或 (回面试房 +1 day) →
  [玉城] 攒道币 → 美术 sprint 后会有更多内容

4 个关卡 = 4 个模板：
  说谎者     = 状态机 + 投票 + 多轮对话         社交推理类
  雨后春笋   = 状态机 + 限时 + 按 E 重复操作     反应/动作类
  人鼠仓库   = 状态机 + 限时 + 谜题解锁 + 赌命   解谜/欺骗类
  黑熊地下室 = 状态机 + 限时 + 周期事件 + 安全锚 节奏/生存类

抄板路径：写新关卡时，挑最近的模板复用。所有关卡都有：
  - XGameController（纯逻辑，可测）
  - XGameOrchestrator（流程，挂场景）
  - XLairBuilder / XRoomBuilder（程序化场景）
  - XGameHud（关卡级 HUD）
  - 对话注册到 dialogue_database
  - 入口在玉城（NPC + action_id 触发场景切换）
```

### 关键 autoload 接口

```gdscript
GameState               # 全部跨场状态 + 序列化
  .dao_count           # 道币（货币）
  .inventory           # Dictionary[item_id, count]
  .observed_clues      # 说谎者关 3 个观察点
  .sniffed_npcs        # 灵闻笔记用过的 NPC
  .pending_day_advance # 日夜推进 flag（防多次）
  .rat_bet_mode        # 人鼠关赌命模式（transient）
  .tutorial_seen       # 教学提示已显示的场景
  .scene_positions     # 跨场玩家位置
  .npc_visit_count     # 多轮对话 visit_count
  .completed_dialogues # 已完成对话集合
  .to_dict() / .from_dict() — SaveSystem 用
  .add_dao(n) / .add_item(id, n) / .remove_item / .try_purchase 等

SceneManager.change_to(path)        # 黑屏 fade + 切场
SaveSystem.save_to_slot(0/1) / .load_from_slot(0/1)
Toast.show_info(msg) / .show_success / .show_error
Notebook.record(dialogue_id)        # 写笔记，按 N 玩家看
QuestState.current_quest_id         # 3 步任务链
AudioManager.play_sfx("win_chime")  # 占位无声，Output 出日志
```

### 玩家快捷键（全局）

```
WASD     移动
E        交互
N        打开/关闭笔记本
X        说谎者/人鼠关：用灵闻笔记
C        说谎者/人鼠关：用线索袋
R        玉城里：用休息券（条件触发）
F9 / F10 快速存档/读档
ESC      关 ShopPanel / 关笔记本
```

---

## 4. 关键设计决策（按时间，含 why）

| 时间 | 决策 | 当时为什么 |
|---|---|---|
| brainstorming | 同人 + 非商业 + Godot + 2.5D 等距 + Disco Elysium 风 | 用户明确要求"按原作 + 半开放探索 + 中式怪诞氛围" |
| P1 | 屏幕方向移动而非等距对齐 | 用户反馈"还是在斜着走"两次；统一为 WASD 直接映射屏幕坐标 |
| P3 → P3.5 | 对话期间锁玩家 + Toast UI + 9-slice 对话框 | 玩家体验割裂；用户要求"道城风" |
| **P4.7** | **说谎者机制颠覆**：原本"找 1 个说谎者"，校正为"所有人都是说谎者，唯一答案是人羊" | 读了原作 Ch 1-15 才发现机制做反了；用户拍板「重度修复」 |
| P4.7 | 删除 hint truth probability 系统 | 原作没有"人羊给暗示" |
| P4.7 | 道城 → 玉城全局重命名 | 道城是后期才到的另一座城；原作前期是玉城 |
| P5.5 | scene_positions dict + Player._ready 复位 | 玩家进出场景体验割裂；小工程大回报 |
| P7 | 玉城 = 真正枢纽（不只是 spawn 出口） | 内容稳定后必须做"家"才能撑住循环 |
| P8 | 人鼠关 dialogue choice 加 action_id | 玩家选项要触发副作用（扣道币 + 切场景）；之前只能 emit dialogue id |
| P8.5 | 朱雀演出复用 LiarCinematic 红色 fade | 不为单个关卡新写 cinematic 节点 |
| P9 | 4 件道具的 4 个不同入口（X / C / 自动 / R） | 每件道具有自己的"使用语境" |
| P10 | 黑熊关 controller 用同步信号 roar_judgement_needed | 让 orchestrator 在判定瞬间精确插入逻辑，避免 race |
| M2 | 主菜单"继续"按钮直接 change_scene_to_file，绕开 SceneManager | 避免双层 fade；副作用是没过渡感 |
| M3 | tutorial_seen 持久化到存档 | 玩家重启后不会被提示 spam |

---

## 5. 写作纪律 cheat-sheet

写新对话时检查清单：

```
[ ] 这段对话里有英文双引号 "..." 吗？→ 必须改成 「...」
[ ] 我是否在脑子里"翻译/微调"原作某段？→ 关闭原作 txt，从头自己写
[ ] 这段台词的句式 / 节奏 / 比喻 是不是我原创的？
[ ] 人物姓名 / 籍贯 / 职业 / 关键剧情节点 — 保留为事实参考是 OK 的
[ ] 长段心理独白 / 角色具体台词 — 永远从零写，不参考原文具体段落
```

写完用这条命令扫单引号问题：
```bash
awk 'BEGIN{FS=""} {n=0; for(i=1;i<=NF;i++) if($i=="\"") n++; if(n%2!=0) print NR": "n" quotes"}' src/scripts/dialogue/dialogue_database.gd
# 输出空 = 所有引号成对，安全
```

---

## 6. 已知技术债 & 常见坑

```
🐛 DialogueController._start_dialogue 是 private (_前缀) 但被外部 call
   (QuestState item hooks / 灵光闪现触发)。重构时小心。

🐛 RotateGameController.random_seed 字段没真用上，留接口

🐛 黑熊关道具效果只接了桃木防御符，X/C 暂未实现（留 P10.5）

🐛 旧 tag (v0.4-p4-complete / v0.4.5-... / v0.5-p5-complete / 
   v0.6-p6-complete) 是历史里程碑，被 v0.4-final 等覆盖。
   不删除以保留 history。

🐛 跨 P 阶段存档不兼容（每加新 GameState 字段都 default 空，
   旧档不 crash 但字段缺失）。

🐛 主菜单"继续"走 change_scene_to_file（绕 SceneManager），
   失去 fade 过渡感。

⚠️ Godot 头一次打开项目会自动重建 .godot/ 缓存（10-30s）。
   首次启动若报"can't find uid"，重启编辑器一般解决。

⚠️ Cursor sandbox 跑 godot --headless 会 SIGABRT（exit 134）。
   测试只能在 Godot IDE 内的 GUT 面板跑。
```

---

## 7. 美术 / 音频 sprint 触发条件

```
当前美术资源：11 张占位（程序化生成）
当前音频资源：0（AudioManager 仅日志）

美术 sprint 触发清单（满足 5/7 项即可启动）：
  [x] 对话系统稳定（无大改）
  [x] 存档读档稳定
  [x] 主场景枢纽（玉城）完成
  [x] 道具/经济系统就位
  [x] 主菜单 + 教学引导
  [ ] 5+ 个生肖关卡（当前 4 个，差 1 个）
  [ ] 玩家做完一个完整 cycle 的 playtest

差 1 关 + 1 次 playtest。
详见 docs/art-guidelines.md §11（含 ~84 张资源清单）。
```

---

## 8. 推荐下一步（如果你是接手的 AI 或 future me）

按 ROI 排序：

```
1. 黑熊关参数调（5/12s/60px → 根据 playtest）        30 min
2. P10.5 黑熊关道具效果（X/C）                        1-2 h
3. M2.5 设置面板（音量 / 全屏 / 难度）                1-2 h
4. M1 第 5 个生肖关（候选：人鸡推理 · 原作 Ch 40+）    3-4 h
5. 美术 sprint（独立 2-3 周）                          ⏰
```

接手前先做：
```
1. 读 docs/status-overview.md（5 min）
2. 读 docs/handoff-2026-06-02.md（5 min）
3. 用 Godot 打开项目 + GUT Run All（应 150+ case 全过）
4. F5 完整 playtest 一次（30 min，重点感受黑熊关节奏）
```

---

## 9. 项目交互习惯

用户的工作风格（从过往 session 提炼）：

```
- 表达简洁，直接给数字选项（"1+3"、"按你的推荐"）
- 一旦验证通过会说"OK"/"可以了"/"通过"，期待 agent 直接进下一步
- 倾向"全权委托"风格（"按你自己的顺序"、"剩下你自己完成"），
  期待 agent 自己拍板 + 在合理停止点 hand-off
- 决策快，不犹豫，错了再回滚
- 重视"原作忠诚度"——P4.7 重构就是 ta 主动要求的
- 不喜欢冗长 ；选项给到 6 条就够了
```

工作流期待：

```
- 大改前先 plan + 让用户拍板（除非 ta 已经全权委托）
- 每个 milestone commit + tag + 报告
- 报告里要给"用户验证步骤"
- 大 session 末尾要写 hand-off 文档
- 多关卡 / 多里程碑用 TodoWrite 跟踪
```

---

## 10. 与 transcript 历史的关系

```
本文件 = "如果 transcript 完全丢失，从这里也能接上"

transcript 物理位置：
  ~/.cursor/projects/var-folders-*/agent-transcripts/<uuid>.jsonl
  不跟 git 走，不跟项目文件夹走。换电脑大概率丢。

continual-learning 插件：
  会从 transcript 提炼"高信号"自动追加到本文件。
  路径：~/.cursor/plugins/cache/cursor-public/continual-learning/.../
  当前为零次有效追加（用户操作一直顺畅，没有反复纠正模式）。

本文件应该**手动维护**：
  每完成大里程碑（M1 第 5 关 / M2 设置 / 美术 sprint…），
  来更新一次第 3/4/8 节，保持新鲜。
```

---

*由 Claude 在 2026-06-02 撰写。所有内容为本项目自创笔触，仅保留原作的事实参考数据（人物姓名 / 地名 / 概念 / 游戏机制）。如有疑问，先读 docs/status-overview.md 再读 docs/handoff-2026-06-02.md。*
