# P1：Godot 项目骨架 + 2.5D 等距技术验证 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal**：搭建《十日终焉》改编游戏的 Godot 4 项目骨架，验证 2.5D 等距 + 玩家移动 + Y-sort 遮挡 + 相机跟随四大核心技术，并完成性能基线与导出验证。

**Architecture**：使用 Godot 4.3+ 的 `TileMapLayer`（等距模式）+ `CharacterBody2D` 玩家 + `Camera2D` 跟随 + Y-sort 自动遮挡的标准 2.5D 等距实现。项目结构按 `src/{scenes,scripts,assets,tests}` 分层，资源命名遵循 snake_case，所有 GDScript 类启用静态类型。

**Tech Stack**：Godot 4.3 LTS、GDScript（静态类型）、Git、GUT 9.x（Godot Unit Test 框架，社区标准）。

**前置依赖**：用户已下载 Godot 4.3 LTS Standard 版（**不是 .NET 版**）。

**预估工期**：1-2 周，约 15 个 bite-sized 任务。

---

## File Structure

本 plan 完成后，项目目录如下：

```
~/Desktop/MyGame/
├─ .gitignore                              # Git 忽略规则
├─ project.godot                           # Godot 项目主文件
├─ icon.svg                                # 默认图标（保留 Godot 生成）
├─ README.md                               # 项目说明
│
├─ docs/
│  ├─ superpowers/
│  │  ├─ specs/2026-05-31-shiri-zhongyan-design.md      # 已存在
│  │  └─ plans/2026-05-31-p1-godot-foundation.md        # 本文档
│  └─ tech-verification-p1.md             # P1 完成后的技术验证报告
│
├─ src/
│  ├─ scenes/
│  │  ├─ main.tscn                         # 主场景（程序入口）
│  │  ├─ world/test_world.tscn             # 测试用世界场景（等距地图）
│  │  └─ player/player.tscn                # 玩家场景
│  │
│  ├─ scripts/
│  │  ├─ player/player.gd                  # 玩家控制脚本
│  │  ├─ player/player_input.gd            # 输入抽象层（为移动端做准备）
│  │  └─ camera/iso_camera.gd              # 等距相机跟随脚本
│  │
│  └─ assets/
│     ├─ tiles/iso_tileset_placeholder.tres   # 临时 TileSet（4 色块）
│     ├─ tiles/iso_tiles_placeholder.png      # 临时图块图集
│     └─ characters/player_placeholder.png    # 玩家临时贴图
│
├─ tests/
│  ├─ unit/test_player_input.gd            # 玩家输入单元测试
│  └─ unit/test_player_movement.gd         # 玩家移动单元测试
│
└─ addons/
   └─ gut/                                  # GUT 测试框架（gitignore 之外的依赖）
```

**设计说明**：
- `src/` 与 `docs/`、`tests/` 平级，便于将来扩展（其他游戏内子系统都放 src/）
- `scripts/` 按职责分子目录（player / camera / 后续：dialogue / save / quest 等）
- `assets/` 是占位资源——P1 不做美术，所有视觉用色块/形状代替
- `tests/unit/` 用于逻辑层 GUT 测试；视觉验证靠手动跑场景

---

## Prerequisites（任务开始前需手动完成）

- [ ] **0.1** 下载并安装 Godot 4.3 LTS Standard 版（https://godotengine.org/download/）
- [ ] **0.2** 推荐安装 VSCode/Cursor 的 Godot 扩展（搜 "godot tools"）以便编辑 GDScript
- [ ] **0.3** 验证：在终端运行 `godot --version`，应输出 `4.3.x` 或更高（macOS 上的命令是 `/Applications/Godot.app/Contents/MacOS/Godot --version`）

---

## Task 1：Git 仓库初始化 + .gitignore

**目标**：让 MyGame 目录成为 git 仓库，并配置好 Godot 项目的 .gitignore。

**Files**:
- Create: `~/Desktop/MyGame/.gitignore`
- Create: `~/Desktop/MyGame/README.md`

- [ ] **Step 1.1：初始化 git 仓库**

```bash
cd ~/Desktop/MyGame
git init -b main
```

预期输出：`Initialized empty Git repository in /Users/.../Desktop/MyGame/.git/`

- [ ] **Step 1.2：创建 .gitignore**

写入以下内容到 `~/Desktop/MyGame/.gitignore`：

```gitignore
# Godot 4 .gitignore — 官方推荐
.godot/
.import/
export.cfg
export_presets.cfg

# Mono / .NET （我们不用，但保留以防）
.mono/
data_*/
mono_crash.*.json

# macOS / Windows / Linux 系统垃圾
.DS_Store
Thumbs.db
*~

# IDE
.vscode/
.idea/
*.swp

# 视觉助手会话目录
.superpowers/

# 构建产物
build/
exports/
*.app
*.exe
*.x86_64
*.dmg
*.zip
```

- [ ] **Step 1.3：创建 README.md**

写入以下内容到 `~/Desktop/MyGame/README.md`：

```markdown
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

P1：Godot 项目骨架 + 2.5D 等距技术验证

## 开发环境

- Godot 4.3 LTS（Standard 版）
- GDScript（启用静态类型）
- GUT 9.x（测试框架）
```

- [ ] **Step 1.4：首次提交**

```bash
cd ~/Desktop/MyGame
git add .gitignore README.md docs/
git commit -m "chore: init git repo with .gitignore, README, and design docs"
```

预期：会有一个提交，包含 .gitignore、README.md、以及已有的 `docs/superpowers/specs/2026-05-31-shiri-zhongyan-design.md` 和 `docs/superpowers/plans/2026-05-31-p1-godot-foundation.md`。

---

## Task 2：创建 Godot 项目 + 基础项目设置

**目标**：用 Godot 编辑器在 MyGame 目录创建一个 Godot 项目，配置好基础渲染、分辨率、输入。

**Files**:
- Create: `~/Desktop/MyGame/project.godot`（由 Godot 自动生成）
- Create: `~/Desktop/MyGame/icon.svg`（Godot 默认）

- [ ] **Step 2.1：打开 Godot，导入项目**

1. 启动 Godot 4.3
2. 点击 **Import** 按钮（或菜单：Project → Import）
3. 浏览到 `~/Desktop/MyGame` 目录
4. 点击 **Import & Edit**
5. 如果 Godot 提示"该目录不是 Godot 项目"，点击 **Create New Project**，名称 "MyGame"，路径选 `~/Desktop/MyGame`，渲染器选 **Mobile**（2.5D 等距 + 移动端最优）

- [ ] **Step 2.2：项目设置 — 显示**

1. 菜单：**Project → Project Settings**
2. 切到 **General → Display → Window** 标签
3. 设置：
   - **Viewport Width**: `1920`
   - **Viewport Height**: `1080`
   - **Mode**: `windowed`
   - **Resizable**: `true`
4. 切到 **General → Display → Window → Stretch**
5. 设置：
   - **Mode**: `viewport`
   - **Aspect**: `expand`
   - **Scale Mode**: `fractional`

- [ ] **Step 2.3：项目设置 — 输入映射**

切到 **Input Map** 标签，添加以下动作（点击 "Add" → 输入名称 → 回车 → 点击 "+" 添加按键绑定）：

| 动作名 | 键盘绑定 |
|---|---|
| `move_up` | W |
| `move_down` | S |
| `move_left` | A |
| `move_right` | D |
| `interact` | E |
| `pause` | Escape |

- [ ] **Step 2.4：保存设置并提交**

1. 点击 **Project Settings 窗口右下角的 "Close"** 关闭
2. 在终端：

```bash
cd ~/Desktop/MyGame
git add project.godot icon.svg
git commit -m "chore: init Godot 4.3 project with display + input config"
```

预期：项目根目录出现 `project.godot` 和 `icon.svg`，已被提交。

---

## Task 3：创建目录结构

**目标**：在 Godot 项目内创建 `src/` 子目录结构。

**Files**:
- Create: `~/Desktop/MyGame/src/scenes/`
- Create: `~/Desktop/MyGame/src/scenes/world/`
- Create: `~/Desktop/MyGame/src/scenes/player/`
- Create: `~/Desktop/MyGame/src/scripts/`
- Create: `~/Desktop/MyGame/src/scripts/player/`
- Create: `~/Desktop/MyGame/src/scripts/camera/`
- Create: `~/Desktop/MyGame/src/assets/`
- Create: `~/Desktop/MyGame/src/assets/tiles/`
- Create: `~/Desktop/MyGame/src/assets/characters/`
- Create: `~/Desktop/MyGame/tests/`
- Create: `~/Desktop/MyGame/tests/unit/`

- [ ] **Step 3.1：创建所有目录**

```bash
cd ~/Desktop/MyGame
mkdir -p src/scenes/world src/scenes/player
mkdir -p src/scripts/player src/scripts/camera
mkdir -p src/assets/tiles src/assets/characters
mkdir -p tests/unit
```

- [ ] **Step 3.2：在每个目录放一个 .gitkeep（让 git 跟踪空目录）**

```bash
cd ~/Desktop/MyGame
find src tests -type d -empty -exec touch {}/.gitkeep \;
```

预期：每个空目录里都有一个 `.gitkeep` 文件。

- [ ] **Step 3.3：提交目录结构**

```bash
cd ~/Desktop/MyGame
git add src/ tests/
git commit -m "chore: scaffold project directory structure"
```

---

## Task 4：安装 GUT 测试框架

**目标**：在 Godot 中安装 GUT (Godot Unit Test) 9.x，为后续 TDD 做准备。

**Files**:
- Create: `~/Desktop/MyGame/addons/gut/`（由 AssetLib 自动放置）

- [ ] **Step 4.1：在 Godot 编辑器中打开 AssetLib**

1. Godot 编辑器顶部菜单：**AssetLib** 标签
2. 在搜索框输入 `gut`
3. 找到 **Gut - Godot Unit Test**（作者 bitwes），点击进入详情页
4. 点击 **Download**，下载完成后点击 **Install**
5. 在弹出的窗口中**只勾选 `addons/gut/`**，点击 **Install**

- [ ] **Step 4.2：启用 GUT 插件**

1. 菜单：**Project → Project Settings → Plugins**
2. 找到 **Gut**，把 **Enable** 列勾上
3. 关闭设置窗口
4. 验证：编辑器底部出现 **GUT** 标签页

- [ ] **Step 4.3：提交 GUT**

```bash
cd ~/Desktop/MyGame
git add addons/ project.godot
git commit -m "chore: install GUT (Godot Unit Test) 9.x"
```

---

## Task 5：创建占位贴图资源（4 色等距瓦片 + 玩家小人）

**目标**：用 Godot 内置工具或外部画图，创建 P1 阶段必须的最简占位贴图。**这是占位资源，不是最终美术。**

**Files**:
- Create: `~/Desktop/MyGame/src/assets/tiles/iso_tiles_placeholder.png`
- Create: `~/Desktop/MyGame/src/assets/characters/player_placeholder.png`

**关于等距贴图规格**：标准 2:1 等距，瓦片 **64×32 像素**（宽 64，高 32），4 种颜色对应 4 种地面：
- 灰色（#3a3a3a）— 路面
- 暗红（#4a1a1a）— 危险区/血迹
- 暗绿（#1a3a1a）— 草地/植被
- 暗蓝（#1a1a4a）— 水/虚空

- [ ] **Step 5.1：用任何画图工具（Aseprite / Photoshop / Krita / GIMP / 在线 Piskel）创建 `iso_tiles_placeholder.png`**

- 画布尺寸：**256×32**（横向排 4 个 64×32 的菱形）
- 每个 64×32 区域画一个等距菱形（顶角朝上下，左右是宽 64 的端点）
- 4 个菱形分别填充上述 4 种颜色
- 透明背景（PNG 带 alpha 通道）
- 导出为 `~/Desktop/MyGame/src/assets/tiles/iso_tiles_placeholder.png`

> ⚠️ 如果不熟悉画等距瓦片：菱形的 4 个顶点坐标分别是 (32, 0), (64, 16), (32, 32), (0, 16)。

- [ ] **Step 5.2：创建 `player_placeholder.png`**

- 画布尺寸：**32×48**
- 画一个简单的小人（一个上半圆 + 一个矩形身体）
- 颜色：身体 #ffd93d（黄），头 #ffaa00（橙）
- 透明背景
- 导出为 `~/Desktop/MyGame/src/assets/characters/player_placeholder.png`

- [ ] **Step 5.3：将贴图导入 Godot**

1. 切回 Godot 编辑器
2. FileSystem 面板会自动检测新文件
3. 选中 `iso_tiles_placeholder.png`，在 Inspector 面板：
   - **Filter**: `Nearest`（不模糊）
   - **Mipmaps**: `Off`
   - 点击 **Reimport**
4. 同样设置 `player_placeholder.png`

- [ ] **Step 5.4：提交占位资源**

```bash
cd ~/Desktop/MyGame
git add src/assets/
git commit -m "feat: add P1 placeholder tiles and player sprite"
```

---

## Task 6：创建等距 TileSet 资源

**目标**：基于占位贴图创建一个 Godot TileSet 资源，配置为等距投影。

**Files**:
- Create: `~/Desktop/MyGame/src/assets/tiles/iso_tileset_placeholder.tres`

- [ ] **Step 6.1：在 FileSystem 中右键 `src/assets/tiles/` → New Resource → 选 `TileSet` → 命名 `iso_tileset_placeholder.tres`**

- [ ] **Step 6.2：配置 TileSet 为等距模式**

1. 双击 `iso_tileset_placeholder.tres` 打开 TileSet 编辑器
2. 在 Inspector 面板设置：
   - **Tile Shape**: `Isometric`
   - **Tile Layout**: `Diamond Down`
   - **Tile Offset Axis**: `Horizontal Offset`
   - **Tile Size**: `Vector2(64, 32)`

- [ ] **Step 6.3：把 4 个瓦片加入 TileSet**

1. 在底部 TileSet 面板左下角点击 **+**，选 **Atlas**
2. 在弹窗中选择 `iso_tiles_placeholder.png`
3. Godot 会自动识别 4 个 64×32 的瓦片
4. 如果识别不对，手动调整 **Texture Region Size** 为 `Vector2(64, 32)`，**Separation** 为 0
5. 在 TileSet 面板顶部点击 **Setup → Create tiles automatically in non-transparent regions**，让 Godot 自动创建 4 个 tile

- [ ] **Step 6.4：保存并提交**

1. 保存场景：菜单 **Scene → Save**（或 Ctrl+S）
2. 终端：

```bash
cd ~/Desktop/MyGame
git add src/assets/tiles/iso_tileset_placeholder.tres
git commit -m "feat: create isometric TileSet with 4 placeholder tiles"
```

---

## Task 7：创建测试世界场景（一个等距地图）

**目标**：创建第一个可视化场景：一张 20×20 的等距地图，用 4 种瓦片随机铺设。

**Files**:
- Create: `~/Desktop/MyGame/src/scenes/world/test_world.tscn`

- [ ] **Step 7.1：新建场景**

1. 菜单：**Scene → New Scene**
2. 在 Scene 面板选 **2D Scene** 作为根节点
3. 双击根节点改名为 `TestWorld`
4. 保存场景到 `src/scenes/world/test_world.tscn`

- [ ] **Step 7.2：添加 TileMapLayer**

1. 选中 `TestWorld` 根节点
2. 右键 → **Add Child Node**
3. 选 `TileMapLayer`，命名为 `Ground`
4. 在 Inspector 中拖 `iso_tileset_placeholder.tres` 到 **Tile Set** 属性

- [ ] **Step 7.3：手动铺一张 20×20 的等距地图**

1. 选中 `Ground` 节点
2. 在编辑器底部的 **TileMap** 面板（如果没出来，View → 检查 Bottom Panel 中的 TileMap）
3. 选第一个瓦片（灰色路面）
4. 在 2D 编辑器中拖动鼠标，绘制一个 20×20 的菱形区域
5. 用第二个瓦片（暗红）在中间画一个 4×4 小方块（标记危险区）
6. 第三、四瓦片随意点缀

> ⚠️ 等距视角下，2D 编辑器坐标是逻辑坐标。你点 (0,0) 和 (1,0) 时，视觉上是斜着排列的菱形。这是正常的。

- [ ] **Step 7.4：运行场景验证**

1. 按 **F6**（运行当前场景），或菜单 **Scene → Run Current Scene**
2. **预期**：弹出窗口显示等距俯视的菱形地图，能看到灰色路面 + 中间的暗红色危险区

- [ ] **Step 7.5：截图保存到 docs/**

1. 截图保存到 `~/Desktop/MyGame/docs/tech-verification-p1/screenshot-task7-isomap.png`（手动创建目录）
2. 提交：

```bash
cd ~/Desktop/MyGame
mkdir -p docs/tech-verification-p1
# （手动放截图到 docs/tech-verification-p1/screenshot-task7-isomap.png）
git add src/scenes/world/test_world.tscn docs/tech-verification-p1/
git commit -m "feat: create test isometric world with 20x20 tilemap"
```

---

## Task 8：玩家输入抽象层（TDD：先写测试）

**目标**：用 TDD 方式创建一个可独立测试的输入抽象类 `PlayerInput`，让后续移动逻辑只依赖它，便于单元测试和移动端虚拟摇杆替换。

**Files**:
- Create: `~/Desktop/MyGame/src/scripts/player/player_input.gd`
- Create: `~/Desktop/MyGame/tests/unit/test_player_input.gd`

- [ ] **Step 8.1：先写失败的测试**

创建 `~/Desktop/MyGame/tests/unit/test_player_input.gd`：

```gdscript
extends GutTest

# 测试 PlayerInput 的基础接口与行为
# 注意：PlayerInput 用 Action 名读取输入，不能直接测真实键盘，需要 Input.action_press() 模拟

const PlayerInputScript = preload("res://src/scripts/player/player_input.gd")

var player_input: PlayerInput

func before_each() -> void:
    player_input = PlayerInputScript.new()

func after_each() -> void:
    # 清理可能模拟的输入状态
    for action in ["move_up", "move_down", "move_left", "move_right"]:
        Input.action_release(action)

func test_no_input_returns_zero_vector() -> void:
    var dir: Vector2 = player_input.get_move_direction()
    assert_eq(dir, Vector2.ZERO, "无输入时应返回零向量")

func test_move_right_only() -> void:
    Input.action_press("move_right")
    var dir: Vector2 = player_input.get_move_direction()
    assert_eq(dir, Vector2.RIGHT, "按 D 应得到 RIGHT 向量")

func test_move_up_only() -> void:
    Input.action_press("move_up")
    var dir: Vector2 = player_input.get_move_direction()
    assert_eq(dir, Vector2.UP, "按 W 应得到 UP 向量")

func test_diagonal_normalized() -> void:
    Input.action_press("move_up")
    Input.action_press("move_right")
    var dir: Vector2 = player_input.get_move_direction()
    assert_almost_eq(dir.length(), 1.0, 0.001, "对角移动后向量应被归一化为长度 1")
```

- [ ] **Step 8.2：运行测试，确认失败**

1. Godot 编辑器底部点 **GUT** 标签
2. 配置 GUT：
   - **Test Directories**: 添加 `res://tests/unit/`
3. 点 **Run All**
4. **预期**：所有 4 个测试失败，错误信息 "PlayerInputScript not found" 或类似（因为 player_input.gd 还没创建）

- [ ] **Step 8.3：写最小实现使测试通过**

创建 `~/Desktop/MyGame/src/scripts/player/player_input.gd`：

```gdscript
class_name PlayerInput
extends RefCounted

# 玩家输入抽象层
# 隔离 Godot 原生 Input，便于：
# 1. 单元测试（用 Input.action_press 模拟）
# 2. 移动端替换（虚拟摇杆只需替换这个类的实现）

func get_move_direction() -> Vector2:
    var dir: Vector2 = Vector2.ZERO
    if Input.is_action_pressed("move_right"):
        dir.x += 1.0
    if Input.is_action_pressed("move_left"):
        dir.x -= 1.0
    if Input.is_action_pressed("move_down"):
        dir.y += 1.0
    if Input.is_action_pressed("move_up"):
        dir.y -= 1.0
    if dir.length() > 0.0:
        dir = dir.normalized()
    return dir
```

- [ ] **Step 8.4：再次运行测试，确认通过**

1. GUT 面板 → **Run All**
2. **预期**：4 个测试全部 PASS

- [ ] **Step 8.5：提交**

```bash
cd ~/Desktop/MyGame
git add src/scripts/player/player_input.gd tests/unit/test_player_input.gd
git commit -m "feat: add PlayerInput abstraction with unit tests"
```

---

## Task 9：玩家移动逻辑（TDD：先写测试）

**目标**：创建 Player 节点的移动逻辑，并测试速度计算。

**Files**:
- Create: `~/Desktop/MyGame/src/scripts/player/player.gd`
- Create: `~/Desktop/MyGame/tests/unit/test_player_movement.gd`

- [ ] **Step 9.1：先写失败的测试**

创建 `~/Desktop/MyGame/tests/unit/test_player_movement.gd`：

```gdscript
extends GutTest

const PlayerScript = preload("res://src/scripts/player/player.gd")

var player: Player

func before_each() -> void:
    player = PlayerScript.new()

func after_each() -> void:
    if is_instance_valid(player):
        player.free()
    for action in ["move_up", "move_down", "move_left", "move_right"]:
        Input.action_release(action)

func test_default_speed_is_200() -> void:
    assert_eq(player.speed, 200.0, "默认速度应为 200 px/s")

func test_calculate_velocity_no_input() -> void:
    var vel: Vector2 = player.calculate_velocity()
    assert_eq(vel, Vector2.ZERO, "无输入时速度为零")

func test_calculate_velocity_right() -> void:
    Input.action_press("move_right")
    var vel: Vector2 = player.calculate_velocity()
    assert_eq(vel, Vector2(200.0, 0.0), "按 D 时速度应为 (200, 0)")

func test_calculate_velocity_iso_diagonal_compensates() -> void:
    # 等距视角下，对角输入应保持速度大小不超过 speed
    Input.action_press("move_up")
    Input.action_press("move_right")
    var vel: Vector2 = player.calculate_velocity()
    assert_almost_eq(vel.length(), 200.0, 0.01, "对角移动速度大小应等于 speed")
```

- [ ] **Step 9.2：运行测试，确认失败**

GUT → Run All → 预期：4 个测试失败（Player 类不存在）

- [ ] **Step 9.3：写最小实现**

创建 `~/Desktop/MyGame/src/scripts/player/player.gd`：

```gdscript
class_name Player
extends CharacterBody2D

# 玩家角色：齐夏（占位实现）
# 在 2.5D 等距场景中移动，使用 CharacterBody2D 与碰撞系统

@export var speed: float = 200.0  # 移动速度（像素/秒）

var _input: PlayerInput = PlayerInput.new()

func calculate_velocity() -> Vector2:
    var direction: Vector2 = _input.get_move_direction()
    return direction * speed

func _physics_process(_delta: float) -> void:
    velocity = calculate_velocity()
    move_and_slide()
```

- [ ] **Step 9.4：运行测试，确认通过**

GUT → Run All → 预期：8 个测试全部 PASS（之前的 4 个 + 新增的 4 个）

- [ ] **Step 9.5：提交**

```bash
cd ~/Desktop/MyGame
git add src/scripts/player/player.gd tests/unit/test_player_movement.gd
git commit -m "feat: add Player movement logic with unit tests"
```

---

## Task 10：玩家场景（视觉化）

**目标**：创建 `player.tscn`，把 player.gd 挂上 Sprite2D 和 CollisionShape2D，并放入测试世界。

**Files**:
- Create: `~/Desktop/MyGame/src/scenes/player/player.tscn`
- Modify: `~/Desktop/MyGame/src/scenes/world/test_world.tscn`

- [ ] **Step 10.1：创建 player.tscn**

1. Scene → New Scene
2. 根节点选 **CharacterBody2D**，命名 `Player`
3. 在 Inspector 面板的 Script 槽，拖入 `src/scripts/player/player.gd`
4. 给 `Player` 添加子节点：
   - **Sprite2D**，命名 `Sprite`
     - Inspector → **Texture** 拖入 `src/assets/characters/player_placeholder.png`
     - **Centered**: `true`
   - **CollisionShape2D**，命名 `Collision`
     - Inspector → **Shape** 点击 New → 选 `CircleShape2D`，半径设 12
   - **Camera2D**（暂留空，Task 11 配置）
5. 保存场景到 `src/scenes/player/player.tscn`

- [ ] **Step 10.2：把 Player 实例化到 TestWorld**

1. 打开 `test_world.tscn`
2. 在 Scene 面板右键 `TestWorld` → **Instantiate Child Scene** → 选 `src/scenes/player/player.tscn`
3. 在 2D 编辑器中把 Player 移动到地图中央（大约 Position (0, 0)）
4. 保存场景（Ctrl+S）

- [ ] **Step 10.3：运行场景验证移动**

1. F6 运行 test_world
2. **预期**：屏幕上有等距地图 + 一个小人，按 WASD 能移动
3. ⚠️ **预期 Bug**：玩家移动是直角坐标系，**不是等距坐标系**！按 D 不是沿着等距路径走，而是直接向右移动。这在 Task 12 修复。

- [ ] **Step 10.4：提交**

```bash
cd ~/Desktop/MyGame
git add src/scenes/player/player.tscn src/scenes/world/test_world.tscn
git commit -m "feat: create Player scene and place into TestWorld"
```

---

## Task 11：等距相机跟随（Camera2D）

**目标**：让相机以等距视角跟随玩家。

**Files**:
- Create: `~/Desktop/MyGame/src/scripts/camera/iso_camera.gd`
- Modify: `~/Desktop/MyGame/src/scenes/player/player.tscn`（给 Player 的 Camera2D 挂脚本）

- [ ] **Step 11.1：创建 iso_camera.gd**

```gdscript
class_name IsoCamera
extends Camera2D

# 等距相机：跟随父节点（玩家），并保持等距视角的视觉中心
# 后续可扩展：摇晃、平滑跟随、缩放控制

@export var follow_smoothing: float = 5.0  # 跟随平滑度（越大越紧跟）

func _ready() -> void:
    position_smoothing_enabled = true
    position_smoothing_speed = follow_smoothing
    # 等距视角通常需要轻微缩放以适应屏幕
    zoom = Vector2(1.5, 1.5)
```

- [ ] **Step 11.2：把脚本挂到 Player 场景的 Camera2D 节点**

1. 打开 `player.tscn`
2. 选中 Player 下的 Camera2D
3. 在 Inspector 中点 Script → **Load**
4. 选 `src/scripts/camera/iso_camera.gd`
5. 把节点类型升级提示（如有）确认

- [ ] **Step 11.3：让 Camera2D 设为 current**

1. 选中 Camera2D
2. Inspector 中勾选 **Current**: `true`

- [ ] **Step 11.4：运行 test_world 验证相机跟随**

1. F6 运行
2. **预期**：相机紧跟玩家，玩家始终在屏幕中央

- [ ] **Step 11.5：提交**

```bash
cd ~/Desktop/MyGame
git add src/scripts/camera/iso_camera.gd src/scenes/player/player.tscn
git commit -m "feat: add IsoCamera follow logic"
```

---

## Task 12：等距坐标修正（让 WASD 按视觉方向走）

**目标**：修复 Task 10 留下的 Bug —— 让"按 W 视觉向上"，而不是按直角坐标系移动。等距渲染下，逻辑空间和屏幕空间是相差 45° 的。

**Files**:
- Modify: `~/Desktop/MyGame/src/scripts/player/player.gd`

- [ ] **Step 12.1：增加坐标变换**

修改 `player.gd` 的 `calculate_velocity`：

```gdscript
class_name Player
extends CharacterBody2D

@export var speed: float = 200.0

# 等距视角的坐标修正矩阵（屏幕→世界的旋转）
# 在 2:1 等距下，屏幕 (1, 0) 对应世界 (1, 0.5)；屏幕 (0, 1) 对应世界 (-1, 0.5)
const ISO_TRANSFORM: Transform2D = Transform2D(
    Vector2(1.0, 0.5),   # x 轴在屏幕上的方向
    Vector2(-1.0, 0.5),  # y 轴在屏幕上的方向
    Vector2.ZERO
)

var _input: PlayerInput = PlayerInput.new()

func calculate_velocity() -> Vector2:
    var direction: Vector2 = _input.get_move_direction()
    # 把"玩家意图的方向"（直角）转换为"等距视觉对应的世界方向"
    var iso_direction: Vector2 = ISO_TRANSFORM * direction
    if iso_direction.length() > 0.0:
        iso_direction = iso_direction.normalized()
    return iso_direction * speed

func _physics_process(_delta: float) -> void:
    velocity = calculate_velocity()
    move_and_slide()
```

- [ ] **Step 12.2：更新测试以匹配新行为**

修改 `tests/unit/test_player_movement.gd`：

```gdscript
extends GutTest

const PlayerScript = preload("res://src/scripts/player/player.gd")

var player: Player

func before_each() -> void:
    player = PlayerScript.new()

func after_each() -> void:
    if is_instance_valid(player):
        player.free()
    for action in ["move_up", "move_down", "move_left", "move_right"]:
        Input.action_release(action)

func test_default_speed_is_200() -> void:
    assert_eq(player.speed, 200.0, "默认速度应为 200 px/s")

func test_calculate_velocity_no_input() -> void:
    var vel: Vector2 = player.calculate_velocity()
    assert_eq(vel, Vector2.ZERO, "无输入时速度为零")

func test_calculate_velocity_speed_magnitude() -> void:
    # 等距变换后速度大小仍应等于 speed（已 normalize）
    Input.action_press("move_right")
    var vel: Vector2 = player.calculate_velocity()
    assert_almost_eq(vel.length(), 200.0, 0.01, "单方向速度大小应等于 speed")

func test_calculate_velocity_iso_diagonal_compensates() -> void:
    Input.action_press("move_up")
    Input.action_press("move_right")
    var vel: Vector2 = player.calculate_velocity()
    assert_almost_eq(vel.length(), 200.0, 0.01, "对角移动速度大小应等于 speed")
```

- [ ] **Step 12.3：运行测试**

GUT → Run All → 预期：8 个测试全部 PASS

- [ ] **Step 12.4：运行场景视觉验证**

1. F6 运行 test_world
2. **预期**：按 W 视觉向"屏幕上方"走（实际上是世界的左上+右上之和），按 D 向"屏幕右下"走
3. 玩家应该沿着等距菱形的方向行走，**而不是直接横平竖直**

- [ ] **Step 12.5：提交**

```bash
cd ~/Desktop/MyGame
git add src/scripts/player/player.gd tests/unit/test_player_movement.gd
git commit -m "fix: apply isometric coordinate transform to player movement"
```

---

## Task 13：Y-sort 自动遮挡验证

**目标**：在测试世界里放几个 Y 坐标不同的建筑/障碍物，验证 Godot 的 Y-sort 能让玩家走到障碍物背后时被遮挡。

**Files**:
- Modify: `~/Desktop/MyGame/src/scenes/world/test_world.tscn`

- [ ] **Step 13.1：在 test_world.tscn 添加 Y-sort 父节点**

1. 打开 `test_world.tscn`
2. 在 Scene 面板右键 `TestWorld` → **Add Child Node** → 选 `Node2D`
3. 重命名为 `YSortContainer`
4. 在 Inspector 中勾选 **Y Sort Enabled**: `true`
5. 把现有的 Player 子节点拖到 `YSortContainer` 下

- [ ] **Step 13.2：添加几个静态建筑物（占位用 ColorRect）**

1. 选中 `YSortContainer`
2. Add Child Node → `Sprite2D`，命名 `Building1`
3. Inspector → Texture 暂时拖入 player_placeholder.png（作为占位）
4. 把 Building1 移到玩家附近位置 (100, -50)
5. 复制 Building1 → 重命名 `Building2`，移到 (-100, 50)

- [ ] **Step 13.3：运行场景验证 Y-sort**

1. F6 运行
2. 把玩家移动到 Building1 上方 → 玩家应被 Building1 遮挡（Building 显示在前）
3. 把玩家移动到 Building1 下方 → 玩家应在 Building1 前面

- [ ] **Step 13.4：截图保存**

保存截图到 `docs/tech-verification-p1/screenshot-task13-ysort.png`

- [ ] **Step 13.5：提交**

```bash
cd ~/Desktop/MyGame
git add src/scenes/world/test_world.tscn docs/tech-verification-p1/
git commit -m "feat: add Y-sort container and verify occlusion with test buildings"
```

---

## Task 14：性能基线测试（30 个 NPC 同屏 FPS 测试）

**目标**：验证 Godot 4 + 2.5D 等距能在 30 个 NPC 同屏时保持 60 FPS。

**Files**:
- Create: `~/Desktop/MyGame/src/scripts/test/spawn_test_npcs.gd`
- Modify: `~/Desktop/MyGame/src/scenes/world/test_world.tscn`

- [ ] **Step 14.1：创建批量 spawn 脚本**

```gdscript
class_name SpawnTestNPCs
extends Node

# P1 性能测试：在场景中生成 30 个静态 NPC（用玩家占位贴图）
# 用于验证 FPS 不掉到 60 以下

const NPC_COUNT: int = 30
const SPAWN_RADIUS: float = 400.0
const PLAYER_SPRITE: Texture2D = preload("res://src/assets/characters/player_placeholder.png")

@onready var ysort_container: Node2D = $"../YSortContainer"

func _ready() -> void:
    for i in range(NPC_COUNT):
        var npc: Sprite2D = Sprite2D.new()
        npc.texture = PLAYER_SPRITE
        var angle: float = (float(i) / NPC_COUNT) * TAU
        npc.position = Vector2(cos(angle), sin(angle) * 0.5) * SPAWN_RADIUS
        npc.modulate = Color(randf(), randf(), randf(), 1.0)
        ysort_container.add_child(npc)
```

- [ ] **Step 14.2：把 spawn 节点加入 test_world.tscn**

1. 打开 test_world.tscn
2. 右键 `TestWorld` → Add Child Node → `Node`，命名 `TestSpawner`
3. Inspector → Script → 选 `src/scripts/test/spawn_test_npcs.gd`

- [ ] **Step 14.3：打开 FPS 显示**

1. 菜单 **Debug → Visible Profiler**（或在游戏运行时按 F3）
2. 在项目设置启用 **Debug → Settings → Stdout → Print FPS**: true

- [ ] **Step 14.4：运行并测量**

1. F6 运行
2. 在游戏窗口内移动玩家 10 秒钟
3. **预期**：FPS ≥ 60（Godot 编辑器顶栏会显示 FPS）
4. 如果 FPS < 60，记录 NPC 数量与 FPS 关系

- [ ] **Step 14.5：把结果写入技术验证报告**

创建 `~/Desktop/MyGame/docs/tech-verification-p1/report.md`：

```markdown
# P1 技术验证报告

## 验证日期
2026-XX-XX  ← 实际日期填写

## 验证项

| 验证项 | 结果 | 数据 |
|---|---|---|
| Godot 4.3 创建项目 | ✅ Pass | - |
| 等距 TileMapLayer 渲染 | ✅ Pass | 见 screenshot-task7 |
| 玩家 WASD 移动 | ✅ Pass | 200 px/s |
| 等距坐标变换 | ✅ Pass | 视觉方向正确 |
| Y-sort 自动遮挡 | ✅ Pass | 见 screenshot-task13 |
| 等距相机跟随 | ✅ Pass | 平滑度 5.0 |
| 性能：30 NPC 同屏 FPS | ✅/❌ | 实测 XX FPS |

## 结论
[填写最终结论：技术栈是否可行，是否需要调整]
```

- [ ] **Step 14.6：提交**

```bash
cd ~/Desktop/MyGame
git add src/scripts/test/ src/scenes/world/test_world.tscn docs/tech-verification-p1/report.md
git commit -m "test: P1 perf baseline - 30 NPCs onscreen FPS measurement"
```

---

## Task 15：导出配置 + 跨平台 Build 验证

**目标**：配置 Godot 的导出预设，导出一个 Windows/macOS/Linux 可执行文件，验证能在目标平台启动。

**Files**:
- Create: `~/Desktop/MyGame/export_presets.cfg`（由 Godot 自动生成，但在 .gitignore 中）
- Create: `~/Desktop/MyGame/exports/`（构建产物目录）

- [ ] **Step 15.1：在 Godot 中下载 export templates**

1. 菜单 **Editor → Manage Export Templates**
2. 如果没下载过，点 **Download and Install** 等待完成

- [ ] **Step 15.2：配置主场景**

1. 菜单 **Project → Project Settings → Application → Run**
2. **Main Scene**: 选 `res://src/scenes/world/test_world.tscn`

- [ ] **Step 15.3：配置导出预设**

1. 菜单 **Project → Export**
2. 点 **Add** → 选择当前平台（macOS 选 macOS、Windows 选 Windows Desktop）
3. **Export Path**: `exports/MyGame-Mac.zip`（或 .exe）
4. 在导出预设的 Resources 标签：保持默认（导出所有）

- [ ] **Step 15.4：导出**

1. 点 **Export Project**
2. 把文件保存到 `~/Desktop/MyGame/exports/`
3. **预期**：生成可执行文件

- [ ] **Step 15.5：运行导出的可执行文件验证**

```bash
cd ~/Desktop/MyGame/exports
# macOS:
open MyGame.app
# Windows:
./MyGame.exe
# Linux:
./MyGame.x86_64
```

预期：能启动游戏并正常运行（看到等距地图、能移动玩家）。

- [ ] **Step 15.6：把验证结果加入技术报告**

在 `docs/tech-verification-p1/report.md` 添加：

```markdown
## 导出验证

| 平台 | Build 结果 | 运行结果 |
|---|---|---|
| macOS | ✅/❌ | ✅/❌ |
| Windows | ✅/❌ | ✅/❌ |
| Linux | ✅/❌ | ✅/❌ |
```

- [ ] **Step 15.7：提交（不提交 exports/，已在 .gitignore）**

```bash
cd ~/Desktop/MyGame
git add docs/tech-verification-p1/report.md
git commit -m "docs: P1 export verification report"
```

---

## Task 16：P1 完成总结 + 决策记录

**目标**：写一份"P1 结束总结"文档，记录所有验证结果，并明确是否进入 P2。

**Files**:
- Modify: `~/Desktop/MyGame/docs/tech-verification-p1/report.md`
- Modify: `~/Desktop/MyGame/README.md`

- [ ] **Step 16.1：完成技术验证报告**

更新 `report.md`，附上"P1 是否通过"的最终决议：

```markdown
## P1 最终结论

- [ ] Godot 4.3 技术栈可行 → 进入 P2
- [ ] 发现致命问题 → 需要调整 → [记录问题]

## 关键决策记录

1. 等距瓦片尺寸：64×32（标准 2:1）
2. 玩家移动速度：200 px/s
3. 相机平滑度：5.0
4. 测试框架：GUT 9.x
5. 项目结构：src/{scenes,scripts,assets} + tests/unit

## 下一步：进入 P2 — 对话系统框架
```

- [ ] **Step 16.2：更新 README.md 标记 P1 完成**

```markdown
## 当前阶段

✅ **P1 完成**：Godot 项目骨架 + 2.5D 等距验证（详见 docs/tech-verification-p1/report.md）

下一阶段：P2 — 对话系统框架
```

- [ ] **Step 16.3：最终提交**

```bash
cd ~/Desktop/MyGame
git add docs/tech-verification-p1/report.md README.md
git commit -m "docs: P1 complete - tech verification passed, ready for P2"

# 可选：打个 tag 标记 P1 完成
git tag -a v0.1-p1-complete -m "P1: Godot foundation + isometric verification"
```

---

## Self-Review Checklist（plan 写完后我已自检）

### 1. Spec 覆盖
P1 plan 是否覆盖 spec 中"M1 / 1.5 月：技术验证"的目标？

- ✅ Godot 4.3 项目骨架（spec §7.1）
- ✅ 2.5D 等距 TileMap（spec §3 + §7.3 "Y-sort 遮挡"）
- ✅ 玩家移动 + 等距坐标修正
- ✅ 相机跟随
- ✅ 性能基线（30 NPC）
- ✅ 导出验证（PC 三平台）
- ✅ 输入抽象层（spec §7.3 "移动端触摸控制重构"为后期做准备）
- ⚠️ 移动端导出未在 P1 验证（spec 中标为 P2 优先级，留给后续 plan）

### 2. Placeholder Scan

无 TBD / TODO / "implement later" / 没有代码块的代码步骤。所有 `[XX]` 占位都是用户实际填写的内容（如截图、FPS 数值等），不是文档占位。

### 3. Type Consistency

- `PlayerInput.get_move_direction() -> Vector2` ：Task 8 定义，Task 9、12 使用 ✅
- `Player.calculate_velocity() -> Vector2` ：Task 9 定义，Task 12 修改 ✅
- `Player.speed: float = 200.0` ：Task 9 定义，Task 12 沿用 ✅
- `IsoCamera.follow_smoothing: float` ：Task 11 定义 ✅
- 资源路径：`res://src/scenes/...`、`res://src/scripts/...`、`res://src/assets/...` 全文一致 ✅

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-05-31-p1-godot-foundation.md`.**

接下来你有两种执行方式：

### 选项 1：Subagent-Driven（推荐）

我每个 Task 派一个全新的 subagent 去执行，task 之间我做 review，确保每个任务做对了才进下一个。
- ✅ 上下文不会污染
- ✅ 错误可控
- ✅ 我能及时纠偏

### 选项 2：Inline Execution

我在当前会话直接按顺序执行所有 Task，每隔几个 Task 找你做 checkpoint 审阅。
- ✅ 速度快
- ⚠️ 上下文会变长
- ⚠️ 错误传播可能更严重

---

**注**：本 plan 的 **Task 1~5** 涉及大量"在 Godot GUI 中点击"的步骤，**这些步骤 AI 无法自动化执行**——你必须在 Godot 编辑器里手动操作。AI 能做的是：
- Task 1（git）：全自动
- Task 5、Step 5.1~5.2（画占位贴图）：你手动，或者用 AI 图像生成工具辅助
- Task 8、9、12（GDScript 编写）：AI 能写代码，但你需要把代码粘进 Godot 编辑器
- Task 11、13、14、15：GUI 操作为主，AI 只能给指令
- **真正全自动的只有 git 操作、文件读写、GDScript 编写、运行测试这几类**

所以"subagent-driven" 在 P1 不会比 "inline" 快太多——主要瓶颈是你手动操作 Godot。

**你的选择？**
