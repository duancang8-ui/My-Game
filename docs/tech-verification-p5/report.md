# P5 技术验证报告

| 项 | 内容 |
|---|---|
| 阶段 | P5 — 场景切换系统 |
| 完成日期 | 2026-06-01 |
| 测试 | **46/46** unit tests + E2E 集成验证 PASS |
| 结论 | ✅ 跨场景切换基础设施完成 |

---

## 1. 实现的子系统

### SceneManager autoload
- 单例 Node，含一个 layer=200 的 CanvasLayer + 全屏 ColorRect overlay
- 状态机：**IDLE → FADING_OUT → LOADING → FADING_IN → IDLE**
- API：`change_to(scene_path: String, fade_duration: float = 0.4)`
- 切换期间忽略二次请求（防止竞态）
- 切换期间 `mouse_filter = STOP` 阻挡输入穿透
- 信号：`scene_change_started(path)` / `scene_change_finished(path)`
- 切换完成自动更新 `GameState.current_scene_path`
- **自动监听**整个 SceneTree 中所有 `Interactable.SCENE_CHANGE` 触发

### Interactable.SCENE_CHANGE 实装
- `Interactable` 加 `scene_path: String` 字段
- 玩家走近 + 按 E → 触发 SceneManager 切换
- 配置完全 data-driven（在 .tscn 设置）

### GameState.current_scene_path
- 新字段记录当前所在场景
- to_dict / from_dict 持久化
- reset() 清空
- 7/7 GameState 测试覆盖（含 roundtrip）

### DaochengMain 占位场景
- `src/scenes/world/daocheng_main.tscn`：道城占位场景
- 24×16 等距地图（明显比面试房间大）
- 中央 6×6 血红危险区（视觉差异强烈）
- 边缘点缀草地/水
- 一扇蓝色"返回面试房间"门（在右下）
- 复用 DialogueBox + DialogueController

### 双向通道集成
- **interview_room → daocheng**：玩家胜利后自动 spawn 一扇蓝色光门（"出口 · 道城"）
- **daocheng → interview_room**：DaochengBuilder 自动生成返回门（"返回面试房间"）
- 玩家可在两个场景间无缝穿梭，过场带 0.4s 黑屏淡入淡出

---

## 2. 测试覆盖

| 模块 | 测试数 |
|---|---|
| (之前已有) | 43 |
| **test_scene_manager** ⭐ 新增 | **3** |
| **总计** | **46/46 ✅** |

**E2E 验证**（场景切换流程）：
1. DaochengMain 加载 + 返回门正确（type=3 + scene_path 正确）✅
2. InterviewRoom WIN 后自动 spawn ExitDoor 指向 daocheng ✅
3. SceneManager autoload 存在 + IDLE 状态 ✅

---

## 3. 关键技术决策

| # | 决策 | 选择 | 理由 |
|---|---|---|---|
| 1 | 场景切换 API | `change_scene_to_file()`（Godot 4 内置）| 简单可靠 |
| 2 | 玩家是否跨场景持久 | **不持久**（每个场景实例化新 Player）| 简化（spec 中 GameState.player_position 保存位置即可，不需跨场景节点）|
| 3 | Fade overlay 实现 | autoload 内置 CanvasLayer + ColorRect | 任何场景都自带 fade，不需各自配置 |
| 4 | Interactable 触发 | SceneManager 自动 connect 整棵树的 Interactable | 关卡作者只需配置 .tscn 字段，无需写代码 |
| 5 | empty scene_path 处理 | push_warning（不 push_error）| GUT 测试不把无效输入视为致命错误 |
| 6 | 切换期间输入阻挡 | overlay 的 mouse_filter = STOP | 防止玩家在 fade 时点穿到 UI |
| 7 | layer 数值 | overlay layer=200（高于 Toast=100 / ResultScreen=80）| 切换期间黑屏遮盖所有 UI |

---

## 4. 用户验证步骤

按 **F5** 启动：

1. 看完开场过场 + 张强讲规则（已有）
2. 跟 5 个 NPC 都聊一遍，到桌前提交 → **指认 林檎**
3. WIN ResultScreen 弹出 → "继续探索"
4. 注意房间右侧**多出一扇蓝色光门** "[出口 · 道城]"
5. 走过去 + **按 E** → 看到 **0.4s 黑屏渐入** → 场景切换 → **黑屏渐出**
6. 现在在**道城**：更大的地图 + 中央血红危险区 + 视觉明显不同
7. 走到右下蓝色"返回面试房间"门 + 按 E → 黑屏过场 → 回到面试房间
8. 注意：返回的面试房间是**全新实例**（玩家位置 reset、关卡状态 reset），这是 P5 的预期行为（"重启关卡"）
9. F9 存档：GameState.current_scene_path 会写入存档文件

---

## 5. 局限性 / 后续改进

| 项 | 当前 | 后续 |
|---|---|---|
| 玩家跨场景位置 | 不保持（重新生成）| P5.5：用 GameState.player_position 在新场景 _ready 时恢复 |
| 关卡状态跨场景 | 不保持 | P5.5：扩展 GameState 字段，例如"已完成的关卡 id 集合" |
| 加载大场景的进度条 | 无（瞬切）| 大场景出现时加 ResourceLoader.load_threaded |
| 过场动画 | 仅黑屏 fade | 后续可加场景特有的过渡（如"血色淡入"）|
| 返回门美术 | 蓝色发光球占位 | 后期美术 sprint 替换为真正"门"|
| 不可逆切换标记 | 没有 | 某些故事节点不允许返回（待 P6+）|

---

## 6. 产出清单

### 新增脚本
- `src/scripts/scene/scene_manager.gd`（autoload）
- `src/scripts/test/daocheng_builder.gd`

### 新增场景
- `src/scenes/world/daocheng_main.tscn`

### 新增测试
- `tests/unit/test_scene_manager.gd`（3 个）

### 修改
- `src/scripts/save/game_state.gd`：加 `current_scene_path` 字段
- `src/scripts/interaction/interactable.gd`：加 `scene_path` 字段
- `src/scripts/liar_game/liar_game_orchestrator.gd`：WIN 时 spawn ExitDoor
- `tests/unit/test_game_state.gd`：roundtrip 测试包含 scene_path
- `project.godot`：注册 SceneManager autoload

---

## 7. P5 最终结论

✅ **跨场景切换基础设施完成**。验证假设：

1. SceneManager autoload 模式可行 ✅
2. Godot `change_scene_to_file()` 工作良好 ✅
3. Fade overlay 通过 autoload 全局共享 ✅
4. Interactable.SCENE_CHANGE 是 data-driven，关卡作者零代码即可加门 ✅
5. GameState 序列化包含场景路径，支持"读档后跳回正确场景"（实施留给 P5.5）

---

## 8. 下一步候选

- **P5.5**：跨场景玩家位置/状态持久化（读档跳回正确场景，记忆轮回机制起点）
- **P6**：第二个生肖游戏（雨后春笋 — 验证不同关卡 reuse SceneManager + 既有系统）
- **P4.5**：扩说谎者到 10 NPC（更接近原作）
- **批量**：等用户提供 zip 后替换原作台词
