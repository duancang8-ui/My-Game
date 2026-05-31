# P1 技术验证报告

| 项目 | 内容 |
|---|---|
| 阶段 | P1 — Godot 项目骨架 + 2.5D 等距技术验证 |
| 完成日期 | 2026-05-31 |
| 开发环境 | macOS（Apple Silicon）+ Godot 4.6.3 stable Universal |
| 仓库 | `~/Desktop/MyGame`（git 本地仓库，未推送）|
| 测试 | GUT 9.6.0，**12/12 单元测试通过** |
| 结论 | ✅ **P1 核心目标全部达成**，可进入 P2 |

---

## 1. 验证项与结果

| # | 验证项 | 结果 | 证据 |
|---|---|---|---|
| 1 | Godot 4.6.3 项目创建 + headless `--import` 无 error | ✅ | 多次 `--import` 退出码 0 |
| 2 | 2.5D 等距 `TileMapLayer` 渲染（64×32 菱形）| ✅ | `screenshot-task7-isomap.png` |
| 3 | 程序化生成 20×20 等距地图（含中央 4×4 危险区） | ✅ | 同上 |
| 4 | 玩家 `CharacterBody2D` + WASD 移动 | ✅ | 用户截图 + 12/12 单元测试 |
| 5 | 屏幕方向直觉式移动（D=屏幕右，W=屏幕上）| ✅ | 用户确认 |
| 6 | 等距相机 `IsoCamera` 跟随（平滑度 5，zoom 1.5×）| ✅ | 视觉验证 |
| 7 | Y-sort 自动遮挡（3 栋小屋测试）| ✅ | 用户截图，遮挡正常 |
| 8 | 建筑物物理碰撞（`StaticBody2D` + 矩形 36×28）| ✅ | 用户确认撞墙正常 |
| 9 | NPC 物理碰撞（`CharacterBody2D` + 圆形 r=8） | ✅ | 用户确认 |
| 10 | 30 个 NPC 同屏（性能基线）| ✅ 视觉无卡顿 | 用户截图 |
| 11 | GUT 9.6.0 测试框架 + TDD 工作流 | ✅ | `addons/gut/`，12/12 通过 |
| 12 | 项目结构（`src/{scenes,scripts,assets}` + `tests/unit`）| ✅ | git tree |

---

## 2. 关键技术决策（已固化）

| # | 决策 | 数值 / 选择 |
|---|---|---|
| 1 | 等距瓦片尺寸 | **64×32**（标准 2:1） |
| 2 | 等距投影 | TileSet `tile_shape=Isometric` + `tile_layout=Diamond Down` |
| 3 | 玩家屏幕速度 | **200 px/s**（无等距坐标变换；CharacterBody2D position 直接是屏幕坐标） |
| 4 | 相机 | `Camera2D` + 平滑度 5.0 + zoom 1.5× |
| 5 | 测试框架 | GUT 9.6.0（git clone 安装，非 AssetLib） |
| 6 | 像素艺术 filter | 全局 `default_texture_filter=0`（Nearest） |
| 7 | 渲染器（PC）| Forward+（暂时；P2 移动端适配时改为 fallback：PC=Forward+, mobile=Mobile）|
| 8 | 输入抽象 | `PlayerInput` 类隔离 `Input.is_action_pressed`，便于测试+移动端摇杆替换 |
| 9 | NPC 碰撞 | 圆形 r=8，offset y=14（sprite 脚部）|
| 10 | 建筑物碰撞 | 矩形 36×28，offset y=26（小屋足迹）|

---

## 3. 用户驱动的设计修正

执行 P1 过程中，用户提出的修正已**全部反映在 spec 中**：

| 修正 | 处理 |
|---|---|
| 主场景应是多层枢纽（非单一面试房间）| spec §3 |
| 覆盖范围扩到 Ch 1~110（A2）| spec §1 + §2 |
| 加半开放探索（B+C 混合 / P5 模式）| spec §5.1 |
| 美术为"赛博中式都市怪诞"（非纸嫁衣）| spec §6 |
| 同人模式发行 | spec §1.3 |
| 严格遵循原作 | spec §5.8 |
| 第二轮回完全尊重原作 | spec §5.9 |
| **所有可见实体必须有物理碰撞** | spec §5.10（新增）|
| 玩家 WASD 屏幕方向直觉式（非沿菱形）| Task 12 重做 |
| 引擎 Godot 4.6.3（用户实装版本，非原计划 4.3 LTS）| 兼容，无影响 |

---

## 4. 暴露的非阻塞问题（延后处理）

| 问题 | 影响 | 处理时机 |
|---|---|---|
| **Task 15 跨平台导出**未完成（export templates 未下载）| 不影响开发，影响发布 | P1 后期 / 发布前 |
| FPS 数值未量化（用户未打开 Profiler）| 视觉无卡顿，但缺数据 | P2 性能测试时补 |
| 渲染器未切到 fallback 写法（PC=Forward+, mobile=Mobile） | PC 上无影响；移动端导出时会出错 | P2 移动端适配阶段 |
| 30 NPC sprite 全部用同一张 `player_placeholder.png` 染色 | 视觉占位，不真实 | P2 美术 sprint |
| 所有 sprite 中心对齐而非脚部对齐（除 collision 外）| Y-sort 比较中心点而非脚部，视觉精度损失 | P2 polish |

---

## 5. P1 阶段产出清单

### 代码
- `src/scripts/player/player.gd`（Player 移动逻辑）
- `src/scripts/player/player_input.gd`（输入抽象层）
- `src/scripts/camera/iso_camera.gd`（等距相机）
- `src/scripts/test/world_builder.gd`（程序化生成 20×20 地图）
- `src/scripts/test/spawn_test_npcs.gd`(30 NPC 生成器)

### 场景
- `src/scenes/player/player.tscn`
- `src/scenes/world/test_world.tscn`

### 资源
- `src/assets/tiles/iso_tiles_placeholder.png`（256×32，4 色菱形瓦片）
- `src/assets/tiles/iso_tileset_placeholder.tres`（TileSet 等距配置）
- `src/assets/characters/player_placeholder.png`（32×48，小黄人）
- `src/assets/characters/building_placeholder.png`（48×80，小屋）

### 测试
- `tests/unit/test_sanity.gd`（3 个 GUT 配置测试）
- `tests/unit/test_player_input.gd`（4 个 PlayerInput 测试）
- `tests/unit/test_player_movement.gd`（5 个 Player 移动测试）

### 文档
- `docs/superpowers/specs/2026-05-31-shiri-zhongyan-design.md`（spec，760+ 行）
- `docs/superpowers/plans/2026-05-31-p1-godot-foundation.md`（P1 plan，1152 行）
- `docs/tech-verification-p1/report.md`（本报告）
- `docs/tech-verification-p1/screenshot-task7-isomap.png`
- `docs/tech-verification-p1/screenshot-task7-editor.png`

### Git 历史（main 分支）
约 18 个 commits（plan/spec → 项目骨架 → 测试 → 碰撞 → P1 总结）

---

## 6. P1 最终结论

✅ **Godot 4.x + GDScript + 2.5D 等距 技术栈完全可行**，所有 P1 假设被验证。

P1 验证了以下核心假设：
1. Godot 4 的 `TileMapLayer` 能稳定支撑等距渲染 ✅
2. `CharacterBody2D` 移动 + Y-sort + 物理碰撞 三者协同工作 ✅
3. 程序化地图生成 + 静态/动态实体混合场景能跑通 ✅
4. GUT 9.6.0 TDD 工作流在 Godot 4.6 上稳定 ✅
5. 项目结构、命名规范、git workflow 已成型 ✅

---

## 7. 下一步：进入 P2

按总体 plan 拆分（详见 spec 附录 C）：
- **P2 — 对话系统框架**（对话框 + 选项 + 检定）

P2 将基于 P1 的骨架，**复用 PlayerInput 抽象、IsoCamera、物理碰撞规范**，新增对话系统所需的 UI 节点和数据结构。

预估工期：6-8 周（约 15-20 个 bite-sized 任务）。
