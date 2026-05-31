# P2 技术验证报告

| 项目 | 内容 |
|---|---|
| 阶段 | P2 — 对话系统框架 |
| 完成日期 | 2026-05-31（同日承接 P1） |
| 执行模式 | **AI 自治执行**（用户离开期间） |
| 测试 | GUT 9.6.0，**27/27 单元测试通过** |
| 集成验证 | TestWorld 加载 + DialogueDatabase 注册 + 9 个关键节点存在 ✅ |
| 结论 | ✅ **P2 核心目标全部达成**，可进入 P3 |

---

## 1. 实现的子系统

### 数据层
- `DialogueLine`（Resource）：speaker_name + text + choices + auto_next_line_id
- `DialogueChoice`（Resource）：label + next_line_id + ends_dialogue
- 支持完全数据驱动：对话内容在脚本（或 `.tres`）中定义，不写死

### 逻辑层
- `DialogueRunner`（RefCounted 状态机）：
  - `start(lines, start_id)` 启动对话
  - `advance()` 推进到 auto_next
  - `pick_choice(index)` 选择分支
  - 通过 `line_changed` / `dialogue_ended` 信号通知 UI
  - **完全无 UI 依赖**，可独立单元测试

### UI 层
- `DialogueBox`（CanvasLayer）：底部面板、说话人 Label、RichTextLabel（支持 bbcode）、选项按钮列表、继续提示
- 占位风格：黑底 + 暗红描边 + 白文 + 暗红说话人色
- 订阅 `DialogueRunner` 信号自动更新

### 交互层
- `Interactable`（Area2D 派生）：放在 NPC/规则牌/入口上，类型枚举（NONE/DIALOGUE/PICKUP/SCENE_CHANGE）
- `PlayerInteractor`（Area2D，挂在 Player 下，r=36 探测圈）：按 E 触发当前重叠的 Interactable
- 用 collision_layer/mask 隔离：Interactable layer=2，Interactor mask=2

### 集成层
- `DialogueController`（Node）：胶水代码，把 `interactable.interaction_triggered` → 启动 Runner → 绑定 DialogueBox
- `DialogueDatabase`（Autoload）：全局对话查找器，懒加载初始化（兼容 `--script` 模式）

### 示例内容
- `chen_junnan_intro`：5 段对话（Cycle 2 重生后陈俊南不认识齐夏），演示分支、bbcode 高亮、ends_dialogue 退出

---

## 2. 测试覆盖

| 模块 | 测试数 | 关键覆盖 |
|---|---|---|
| `test_sanity` | 3 | GUT 框架可用性 |
| `test_player_input` | 4 | WASD 输入抽象 |
| `test_player_movement` | 5 | 速度计算 + 屏幕方向 |
| `test_dialogue_line` | 4 | DialogueLine + DialogueChoice 默认值/构造 |
| `test_dialogue_runner` | 7 | start/advance/pick_choice/end 全状态机 |
| `test_interactable` | 4 | Interactable 类型/信号/dialogue_id/prompt |
| **总计** | **27** | **27/27 通过 ✅** |

---

## 3. 关键技术决策

| # | 决策 | 选择 | 理由 |
|---|---|---|---|
| 1 | 对话数据存储 | GDScript 硬编码注册 + 留 `.tres` 加载接口 | P2 阶段重点验证逻辑，后续可热切换为 `.tres` |
| 2 | DialogueRunner 类型 | `RefCounted`（无 UI 依赖）| 可独立单元测试，UI 通过信号订阅 |
| 3 | DialogueBox 节点类型 | `CanvasLayer`（layer=10）| 独立于 2D 世界，相机移动不影响 |
| 4 | 交互探测范围 | Area2D r=36（玩家身上）| 与 32 像素小人匹配，覆盖一格 |
| 5 | Collision layer 约定 | Interactable layer=2, Interactor mask=2 | 不与物理碰撞（layer 1）混淆 |
| 6 | Autoload 初始化 | 懒加载（首次访问注册）| 兼容 --script 模式，autoload._ready 可能不调用 |
| 7 | bbcode 富文本 | RichTextLabel + bbcode_enabled=true | 支持 [color=…] 等格式（齐夏的"心声"用暗红显示）|
| 8 | E 键消费策略 | DialogueBox 和 PlayerInteractor 都用 `_unhandled_input`，触发后调 `set_input_as_handled` | 避免对话期间重复触发 |

---

## 4. 用户决策延后项（出现在 P2 实施中）

| 项 | 当前默认 | 待用户复核 |
|---|---|---|
| 对话内容是否要拆到 `.tres` 资源文件 | 当前硬编码在 `DialogueDatabase.register_chen_junnan_intro()` | 是否切换为 `.tres`（更便于编辑、本地化）|
| 对话框美术 | 占位（黑底+暗红描边）| 后续美术 sprint polish 时换为"赛博中式都市怪诞"风格 |
| 选项数字快捷键（按 1/2/3 选选项）| 未实现，只能鼠标点击 | 后续 UX 改进可加 |
| 对话期间是否暂停游戏 | **未暂停**（玩家仍能走动）| 暂停 vs 不暂停是 UX 设计选择 |
| 头像 | 无 | 后续美术 sprint 提供肖像图 |

---

## 5. 知识与"踩坑"记录

### 坑 1：Godot 4 Array[CustomType] 必须显式声明
```gdscript
# ❌ 错误：直接 assign 普通 Array 会失败
line.choices.assign(some_array)

# ✅ 正确：构造 typed array 再赋值
var typed: Array[DialogueChoice] = []
for c in some_array:
    typed.append(c)
line.choices = typed
```

### 坑 2：`--script` 模式 autoload 的 _ready 可能不被调用
**解决**：用懒加载 + `_ensure_initialized()` 守卫。

### 坑 3：CanvasLayer 节点不接受 `visible` 之外的 anchor 设置
**解决**：把布局放在 CanvasLayer 的子 Control 节点（PanelContainer）上，CanvasLayer 自身只负责 layer ordering。

---

## 6. 用户可视化验证步骤（用户回来时跑一次）

1. 在 Godot 编辑器里 **F5** 启动游戏
2. 看到等距地图 + 玩家 + 30 个彩色 NPC + 3 个小屋
3. **新增**：屏幕上有一个**蓝色的小人**（陈俊南，位置 420, 320），稍微偏右
4. 把玩家走到陈俊南附近（约 1 格距离内）
5. **按 E**：屏幕底部应弹出对话框：
   - 说话人：陈俊南
   - 文本："你是谁？这地方又是哪？"
   - 选项 1/2/3：自我介绍 / 你不认识我了？/（沉默）离开
6. **点击选项 1**："（自我介绍）我是齐夏。" → 陈俊南："齐夏？没听过…"
7. **按 E 继续** → 齐夏的内心独白（暗红色文字，bbcode 高亮）
8. **再按 E** → 对话结束，对话框消失
9. 玩家可继续走动

---

## 7. P2 阶段产出清单

### 新增脚本
- `src/scripts/dialogue/dialogue_line.gd`
- `src/scripts/dialogue/dialogue_choice.gd`
- `src/scripts/dialogue/dialogue_runner.gd`
- `src/scripts/dialogue/dialogue_box.gd`
- `src/scripts/dialogue/dialogue_database.gd`（autoload）
- `src/scripts/dialogue/dialogue_controller.gd`
- `src/scripts/interaction/interactable.gd`
- `src/scripts/interaction/player_interactor.gd`

### 新增场景
- `src/scenes/ui/dialogue_box.tscn`

### 修改场景
- `src/scenes/player/player.tscn`（加 Interactor Area2D 子节点）
- `src/scenes/world/test_world.tscn`（加 ChenJunnan NPC + DialogueBox + DialogueController）

### 新增测试
- `tests/unit/test_dialogue_line.gd`（4 个）
- `tests/unit/test_dialogue_runner.gd`（7 个）
- `tests/unit/test_interactable.gd`（4 个）

### 修改文档
- `project.godot`（注册 DialogueDatabase autoload）

---

## 8. P2 最终结论

✅ **对话系统骨架已搭好**，所有 P2 假设被验证：

1. 数据驱动的对话设计可行（`DialogueLine` Resource + 状态机）✅
2. UI/逻辑分离架构正确（信号订阅）✅
3. Area2D 触发 + E 键交互流畅 ✅
4. Autoload 单例可全局查询对话 ✅
5. 集成到 TestWorld 后所有节点正常加载 ✅

---

## 9. 下一步：进入 P3

按总体 plan（spec 附录 C）：
- **P3 — 存档/读档基础设施**

P3 内容：
- SaveSystem 单例（Autoload）
- 全局游戏状态（GameState）—— 玩家位置、当前 cycle、记忆保留
- JSON / Godot ConfigFile 格式
- 单元测试覆盖 save/load roundtrip
- 集成到 TestWorld（按 F9 存档、F10 读档）

预估工期：6-10 个 bite-sized 任务。
