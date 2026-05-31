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

⏭️ **下一阶段**：P3 — 存档/读档基础设施

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
