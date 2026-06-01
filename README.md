# MyGame —《十日终焉》改编游戏（同人）

> 基于杀虫队队员《十日终焉》改编的 2.5D 等距规则怪谈轮回叙事游戏。
> **本项目是同人作品，非商业、为爱发电，尊重原作版权。**

## 项目结构

- `docs/superpowers/specs/` — 设计文档（spec）
- `docs/superpowers/plans/` — 实施计划（plan）
- `src/` — 游戏源码（Godot 项目）
- `tests/` — 单元测试（GUT）
- `addons/` — Godot 插件（GUT 等）

## 当前阶段

- ✅ **P1 完成**：Godot 项目骨架 + 2.5D 等距技术验证（[报告](docs/tech-verification-p1/report.md)）
- ✅ **P2 完成**：对话系统框架（数据 + 逻辑 + UI + 交互 + 示例）（[报告](docs/tech-verification-p2/report.md)）
- ✅ **P3 完成**：存档/读档基础设施（GameState + SaveSystem + F9/F10）（[报告](docs/tech-verification-p3/report.md)）
- ✅ **P3.5 完成**：UX Polish（对话锁玩家 + Toast UI + 道城风对话框皮肤）（[报告](docs/tech-verification-p3.5/report.md)）
  - ⏳ 延后：原作台词替换（等用户提供 `docs/source/2789.txt.zip`）
- ✅ **P4 完成**：「说谎者」第一个生肖游戏关卡 MVS（[报告](docs/tech-verification-p4/report.md)）
  - 5 NPC 围桌、对话收集线索、投票指认、胜负结算
- ✅ **P4.1 完成**：叙事铺垫（开场过场 + 张强宣布规则 + 顶部 HUD 进度）
- ✅ **P5 完成**：场景切换系统（SceneManager + 黑屏 fade + 双向门）（[报告](docs/tech-verification-p5/report.md)）
  - 胜利后房间出现"出口 · 道城"门 → 切到 daocheng → 返回门切回
- ✅ **P4.5 完成**：说谎者扩到 10 人 + 随机靶子 + 人羊持久暗示（[报告](docs/tech-verification-p4.5/report.md)）
  - 9 NPC 围桌（齐夏+9=10，符合原作）
  - 每次启动游戏靶子随机
  - 人羊在规则讲完后给一句指向靶子的暗示（HUD 持久显示）

⏭️ **下一阶段**：P5.5（跨场景玩家持久化）/ P6（雨后春笋）/ P4.6（暗示真假博弈）/ 原作对话批量替换 — 由用户选

## 美术策略

本项目采用 **"程序先行 + 占位美术 + 最后统一替换"**（Greybox 工作流）。详见：
- 📚 [美术参考库](docs/art-reference/README.md) —— 对标作品 + AI 生图 prompts
- 📐 [美术规范文档](docs/art-guidelines.md) —— 调色板、尺寸、命名、替换流程

**何时启动美术 sprint**：5+ 关卡完成 + 系统稳定后（详见 art-guidelines §10）

## 测试摘要

```bash
# 跑所有单元测试（应 38/38 通过）
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
```

## 快速开始

```bash
# 跑单元测试（12/12 应该通过）
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit

# 运行游戏（test_world.tscn 是 P1 主场景）
# 在 Godot 编辑器里 F5 启动
```

## 开发环境

- Godot 4.6.3 stable（macOS Universal）
- GDScript（启用静态类型）
- GUT 9.x（测试框架）

## 文档

- [设计文档（spec）](docs/superpowers/specs/2026-05-31-shiri-zhongyan-design.md)
- [P1 实施计划（plan）](docs/superpowers/plans/2026-05-31-p1-godot-foundation.md)
