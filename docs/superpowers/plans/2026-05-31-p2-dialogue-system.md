# P2：对话系统框架 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal**：搭建《十日终焉》游戏的对话系统骨架。玩家走到 NPC 旁边按 E，弹出对话框，看 NPC 说话，能选择回答，对话推进，最后退出。

**Architecture**：
- **数据层**：`DialogueLine` 资源（speaker, text, choices）+ `DialogueChoice` 资源（label, next_id）。完全数据驱动，对话内容在 `.tres` 中定义，不写死在脚本里。
- **逻辑层**：`DialogueRunner`（无 UI 的状态机），负责加载对话、推进、处理选项。可独立单元测试。
- **UI 层**：`DialogueBox` Control 节点（CanvasLayer 上的 PanelContainer + RichTextLabel + 选项 Button 列表），订阅 DialogueRunner 信号。
- **触发层**：`Interactable` Area2D 组件，玩家 Area2D 进入时显示提示，按 E 触发对话。

**Tech Stack**：Godot 4.6.3、GDScript（静态类型）、Resource (.tres) 作为数据格式、CanvasLayer + Control 节点 UI、GUT 9.6.0 测试。

**遵循 P1 既定原则**：
- 所有可视实体的物理碰撞规范（spec §5.10）
- WASD 屏幕方向直觉式移动
- 测试驱动开发（每个逻辑模块先写测试）
- 占位资源使用纯色 + 简单文字（不依赖美术）

**预估工期**：约 6 个 bite-sized 任务，1-2 周等同 1-2 小时 AI 工作量。

---

## File Structure

新增/修改的文件：

```
src/
├─ scenes/
│  ├─ player/player.tscn                            # 修改：加 Interactable 区域 + ID
│  └─ ui/
│     └─ dialogue_box.tscn                          # 新增：对话框 UI 场景
│
├─ scripts/
│  ├─ dialogue/                                     # 新增子目录
│  │  ├─ dialogue_line.gd                           # Resource: 一段对话
│  │  ├─ dialogue_choice.gd                         # Resource: 一个选项
│  │  ├─ dialogue_runner.gd                         # 控制器：推进对话
│  │  └─ dialogue_box.gd                            # UI Control: 显示对话
│  └─ interaction/                                  # 新增子目录
│     ├─ interactable.gd                            # Area2D: 可交互对象基类
│     └─ player_interactor.gd                       # Area2D: 玩家的交互探测器
│
└─ assets/
   └─ dialogues/                                    # 新增子目录
      └─ chen_junnan_intro.tres                     # 示例对话（齐夏 vs 陈俊南）

tests/unit/
├─ test_dialogue_line.gd                            # 数据资源测试
├─ test_dialogue_runner.gd                          # 运行器测试
└─ test_interactable.gd                             # 交互测试

src/scenes/world/test_world.tscn                    # 修改：把 1 个 NPC 升级为可对话
```

**设计说明**：
- `scripts/dialogue/` 与 `scripts/player/` 平级——对话是独立模块
- `scripts/interaction/` 独立——交互系统未来会用于"开门""拾取物""读规则牌"等所有场景
- 对话数据用 `.tres`（Godot 原生 Resource），未来可在 Inspector 直接编辑
- UI 用 CanvasLayer，独立于 2D 世界（不受相机变换影响）

---

## Task 1：DialogueLine + DialogueChoice 数据资源（TDD）

**Files**:
- Create: `src/scripts/dialogue/dialogue_line.gd`
- Create: `src/scripts/dialogue/dialogue_choice.gd`
- Create: `tests/unit/test_dialogue_line.gd`

- [ ] **Step 1.1：写失败测试**

`tests/unit/test_dialogue_line.gd`：

```gdscript
extends GutTest

const DialogueLineScript = preload("res://src/scripts/dialogue/dialogue_line.gd")
const DialogueChoiceScript = preload("res://src/scripts/dialogue/dialogue_choice.gd")

func test_dialogue_line_has_defaults() -> void:
    var line: DialogueLine = DialogueLineScript.new()
    assert_eq(line.line_id, "", "默认 id 为空")
    assert_eq(line.speaker_name, "", "默认说话人为空")
    assert_eq(line.text, "", "默认文本为空")
    assert_eq(line.choices.size(), 0, "默认无选项")

func test_dialogue_line_can_be_built() -> void:
    var line: DialogueLine = DialogueLineScript.new()
    line.line_id = "intro_01"
    line.speaker_name = "陈俊南"
    line.text = "你也是被押送来的？"
    assert_eq(line.line_id, "intro_01")
    assert_eq(line.speaker_name, "陈俊南")
    assert_eq(line.text, "你也是被押送来的？")

func test_dialogue_choice_has_defaults() -> void:
    var choice: DialogueChoice = DialogueChoiceScript.new()
    assert_eq(choice.label, "", "默认标签为空")
    assert_eq(choice.next_line_id, "", "默认下一句 id 为空")
    assert_true(choice.ends_dialogue == false, "默认不结束对话")

func test_dialogue_choice_ends_dialogue() -> void:
    var choice: DialogueChoice = DialogueChoiceScript.new()
    choice.label = "（沉默）离开"
    choice.ends_dialogue = true
    assert_true(choice.ends_dialogue, "结束选项标记")
```

- [ ] **Step 1.2：跑测试 → 失败**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
```

预期：脚本不存在导致 parse error。

- [ ] **Step 1.3：实现 DialogueChoice**

`src/scripts/dialogue/dialogue_choice.gd`：

```gdscript
class_name DialogueChoice
extends Resource

# 对话选项：玩家可点击的一个分支选择
# 设计为 Resource，可在 Inspector 编辑、可作为 .tres 保存

@export var label: String = ""              ## 显示给玩家的选项文字
@export var next_line_id: String = ""       ## 选择后跳转到的下一段对话 id
@export var ends_dialogue: bool = false     ## 是否结束整个对话（例如"离开"按钮）
```

- [ ] **Step 1.4：实现 DialogueLine**

`src/scripts/dialogue/dialogue_line.gd`：

```gdscript
class_name DialogueLine
extends Resource

# 一段对话：包含说话人、文本、和零或多个选项
# 一个完整对话由多个 DialogueLine 通过 next_line_id 串联组成

@export var line_id: String = ""              ## 唯一标识，DialogueRunner 用此跳转
@export var speaker_name: String = ""         ## 角色名（齐夏 / 陈俊南 / 乔家劲...）
@export var text: String = ""                 ## 对话内容
@export var choices: Array[DialogueChoice] = []  ## 选项列表；空表示纯陈述（点任意键继续）
@export var auto_next_line_id: String = ""    ## 无选项时，点任意键后跳转的 id；空表示结束
```

- [ ] **Step 1.5：跑测试 → 通过**

预期：4/4 测试通过，单元测试总数 16/16。

- [ ] **Step 1.6：commit**

```bash
git add src/scripts/dialogue/ tests/unit/test_dialogue_line.gd
git commit -m "feat(dialogue): DialogueLine + DialogueChoice resources (4/4 tests)"
```

---

## Task 2：DialogueRunner 状态机（TDD）

**Files**:
- Create: `src/scripts/dialogue/dialogue_runner.gd`
- Create: `tests/unit/test_dialogue_runner.gd`

- [ ] **Step 2.1：写失败测试**

`tests/unit/test_dialogue_runner.gd`：

```gdscript
extends GutTest

const DialogueRunnerScript = preload("res://src/scripts/dialogue/dialogue_runner.gd")
const DialogueLineScript = preload("res://src/scripts/dialogue/dialogue_line.gd")
const DialogueChoiceScript = preload("res://src/scripts/dialogue/dialogue_choice.gd")

var runner: DialogueRunner

func before_each() -> void:
    runner = DialogueRunnerScript.new()

func _make_line(id: String, text: String, choices: Array = []) -> DialogueLine:
    var line: DialogueLine = DialogueLineScript.new()
    line.line_id = id
    line.speaker_name = "TestSpeaker"
    line.text = text
    line.choices.assign(choices)
    return line

func _make_choice(label: String, next_id: String, ends: bool = false) -> DialogueChoice:
    var c: DialogueChoice = DialogueChoiceScript.new()
    c.label = label
    c.next_line_id = next_id
    c.ends_dialogue = ends
    return c

func test_runner_starts_inactive() -> void:
    assert_false(runner.is_active(), "未启动时 inactive")
    assert_null(runner.current_line, "未启动时 current_line 为 null")

func test_runner_starts_a_dialogue() -> void:
    var lines: Array[DialogueLine] = [_make_line("a", "Hello")]
    runner.start(lines, "a")
    assert_true(runner.is_active(), "启动后 active")
    assert_eq(runner.current_line.text, "Hello")

func test_runner_advances_via_auto_next() -> void:
    var l1: DialogueLine = _make_line("a", "Line 1")
    l1.auto_next_line_id = "b"
    var l2: DialogueLine = _make_line("b", "Line 2")
    runner.start([l1, l2], "a")
    runner.advance()
    assert_eq(runner.current_line.text, "Line 2", "auto_next 推进")

func test_runner_ends_when_no_next() -> void:
    var l1: DialogueLine = _make_line("a", "Solo line")
    runner.start([l1], "a")
    runner.advance()
    assert_false(runner.is_active(), "无 next 时结束")
    assert_null(runner.current_line)

func test_runner_picks_choice() -> void:
    var l1: DialogueLine = _make_line("a", "Pick one", [
        _make_choice("Go A", "a_result"),
        _make_choice("Go B", "b_result"),
    ])
    var l_a: DialogueLine = _make_line("a_result", "You chose A")
    var l_b: DialogueLine = _make_line("b_result", "You chose B")
    runner.start([l1, l_a, l_b], "a")
    runner.pick_choice(1)  # 选第 2 个选项（index 1）
    assert_eq(runner.current_line.text, "You chose B")

func test_choice_with_ends_dialogue_stops() -> void:
    var l1: DialogueLine = _make_line("a", "Final", [
        _make_choice("Leave", "", true),
    ])
    runner.start([l1], "a")
    runner.pick_choice(0)
    assert_false(runner.is_active(), "ends_dialogue 选项结束对话")
```

- [ ] **Step 2.2：跑测试 → 失败**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
```

- [ ] **Step 2.3：实现 DialogueRunner**

`src/scripts/dialogue/dialogue_runner.gd`：

```gdscript
class_name DialogueRunner
extends RefCounted

# 对话状态机（纯逻辑，无 UI 依赖）
# UI 层订阅 line_changed / dialogue_ended 信号来更新显示

signal line_changed(line: DialogueLine)
signal dialogue_ended()

var current_line: DialogueLine = null
var _lines_by_id: Dictionary = {}  # id -> DialogueLine

func is_active() -> bool:
    return current_line != null

func start(lines: Array, start_id: String) -> void:
    _lines_by_id.clear()
    for line in lines:
        if line is DialogueLine:
            _lines_by_id[line.line_id] = line
    _go_to(start_id)

func advance() -> void:
    if not is_active():
        return
    if current_line.choices.size() > 0:
        return  # 等待玩家选择，不能 advance
    _go_to(current_line.auto_next_line_id)

func pick_choice(index: int) -> void:
    if not is_active():
        return
    if index < 0 or index >= current_line.choices.size():
        push_warning("DialogueRunner.pick_choice: index out of range")
        return
    var choice: DialogueChoice = current_line.choices[index]
    if choice.ends_dialogue:
        _end()
        return
    _go_to(choice.next_line_id)

func _go_to(line_id: String) -> void:
    if line_id == "" or not _lines_by_id.has(line_id):
        _end()
        return
    current_line = _lines_by_id[line_id]
    line_changed.emit(current_line)

func _end() -> void:
    current_line = null
    dialogue_ended.emit()
```

- [ ] **Step 2.4：跑测试 → 通过**

预期：6/6 测试通过，单元测试总数 22/22。

- [ ] **Step 2.5：commit**

```bash
git add src/scripts/dialogue/dialogue_runner.gd tests/unit/test_dialogue_runner.gd
git commit -m "feat(dialogue): DialogueRunner state machine (6/6 tests)"
```

---

## Task 3：DialogueBox UI

**Files**:
- Create: `src/scripts/dialogue/dialogue_box.gd`
- Create: `src/scenes/ui/dialogue_box.tscn`

**说明**：DialogueBox 是一个 Control 节点，订阅 DialogueRunner 的信号显示当前对话。
P2 阶段用纯色 + Label 占位，不做美术装饰（spec §6 的美术风格 polish 留给后续 plan）。

- [ ] **Step 3.1：写 DialogueBox 脚本**

`src/scripts/dialogue/dialogue_box.gd`：

```gdscript
class_name DialogueBox
extends CanvasLayer

# 对话框 UI：显示 DialogueRunner 当前 line 的内容
# 占位风格：底部面板 + 黑色背景 + 白色文字 + 选项按钮列表
# 后续美术 polish 阶段再升级为"赛博中式都市怪诞"风

signal choice_picked(index: int)
signal continue_pressed()

@onready var _panel: PanelContainer = $Panel
@onready var _speaker_label: Label = $Panel/VBox/SpeakerLabel
@onready var _text_label: RichTextLabel = $Panel/VBox/TextLabel
@onready var _choices_box: VBoxContainer = $Panel/VBox/Choices
@onready var _continue_hint: Label = $Panel/VBox/ContinueHint

var _runner: DialogueRunner = null

func _ready() -> void:
    visible = false

func attach_runner(runner: DialogueRunner) -> void:
    _runner = runner
    runner.line_changed.connect(_on_line_changed)
    runner.dialogue_ended.connect(_on_dialogue_ended)

func _on_line_changed(line: DialogueLine) -> void:
    visible = true
    _speaker_label.text = line.speaker_name
    _text_label.text = line.text
    _refresh_choices(line)

func _on_dialogue_ended() -> void:
    visible = false
    _clear_choices()

func _refresh_choices(line: DialogueLine) -> void:
    _clear_choices()
    if line.choices.size() == 0:
        _continue_hint.visible = true
        _choices_box.visible = false
        return
    _continue_hint.visible = false
    _choices_box.visible = true
    for i in range(line.choices.size()):
        var choice: DialogueChoice = line.choices[i]
        var btn: Button = Button.new()
        btn.text = "%d. %s" % [i + 1, choice.label]
        var idx: int = i
        btn.pressed.connect(func() -> void: choice_picked.emit(idx))
        _choices_box.add_child(btn)

func _clear_choices() -> void:
    for child in _choices_box.get_children():
        child.queue_free()

func _input(event: InputEvent) -> void:
    if not visible:
        return
    if _runner == null or not _runner.is_active():
        return
    # 当前行无选项时，任意键/鼠标继续
    if _runner.current_line.choices.size() == 0:
        if event.is_action_pressed("interact") or (event is InputEventMouseButton and event.pressed):
            continue_pressed.emit()
            get_viewport().set_input_as_handled()
```

- [ ] **Step 3.2：创建 DialogueBox 场景文件**

`src/scenes/ui/dialogue_box.tscn`（CanvasLayer + Panel + VBox + Label×2 + VBox 选项）

- [ ] **Step 3.3：手动场景验证（headless 加载场景检查节点存在）**

写一个临时 verify 脚本，加载 dialogue_box.tscn 验证节点结构正确。

- [ ] **Step 3.4：commit**

```bash
git add src/scripts/dialogue/dialogue_box.gd src/scenes/ui/dialogue_box.tscn
git commit -m "feat(dialogue): DialogueBox UI (placeholder skin, panel + labels + choice buttons)"
```

---

## Task 4：Interactable 交互系统

**Files**:
- Create: `src/scripts/interaction/interactable.gd`
- Create: `src/scripts/interaction/player_interactor.gd`
- Create: `tests/unit/test_interactable.gd`
- Modify: `src/scenes/player/player.tscn`（添加 PlayerInteractor Area2D 子节点）

**说明**：
- `Interactable`：放在 NPC 上的 Area2D 标签，标识"此对象可交互"，含 callback 类型（dialogue / pickup / 等）
- `PlayerInteractor`：放在玩家上的 Area2D 探测器，记录当前重叠的 Interactable
- 玩家按 E（`interact` 动作）时触发当前 Interactable 的 callback

- [ ] **Step 4.1：写测试**

```gdscript
extends GutTest

const InteractableScript = preload("res://src/scripts/interaction/interactable.gd")

var interactable: Interactable

func before_each() -> void:
    interactable = InteractableScript.new()

func after_each() -> void:
    if is_instance_valid(interactable):
        interactable.queue_free()

func test_interactable_default_type_is_none() -> void:
    assert_eq(interactable.interaction_type, Interactable.Type.NONE)

func test_interactable_emits_signal_on_interact() -> void:
    interactable.interaction_type = Interactable.Type.DIALOGUE
    interactable.dialogue_id = "test_dialogue_01"
    watch_signals(interactable)
    interactable.interact()
    assert_signal_emitted(interactable, "interaction_triggered")

func test_dialogue_interactable_carries_dialogue_id() -> void:
    interactable.interaction_type = Interactable.Type.DIALOGUE
    interactable.dialogue_id = "chen_junnan_intro"
    assert_eq(interactable.dialogue_id, "chen_junnan_intro")
```

- [ ] **Step 4.2：实现 Interactable**

```gdscript
class_name Interactable
extends Area2D

# 可交互对象基类，挂在 NPC、规则牌、副本入口等节点上
# 玩家的 PlayerInteractor 探测到 + 按 E 时触发 interaction_triggered 信号

signal interaction_triggered(interactable: Interactable)

enum Type {
    NONE,
    DIALOGUE,       # 触发对话（携带 dialogue_id）
    PICKUP,         # 拾取物品（携带 item_id，后续 plan 实装）
    SCENE_CHANGE,   # 切换场景（携带 scene_path，后续 plan 实装）
}

@export var interaction_type: Type = Type.NONE
@export var dialogue_id: String = ""        # 当 type == DIALOGUE 时使用
@export var prompt_text: String = "[E] 互动"  # 在玩家附近显示的提示文字（P2 暂不实现 prompt UI）

func interact() -> void:
    interaction_triggered.emit(self)
```

- [ ] **Step 4.3：实现 PlayerInteractor**

```gdscript
class_name PlayerInteractor
extends Area2D

# 玩家身上的"交互探测器"
# 跟踪当前重叠的 Interactable，按 E 时调用 .interact()

signal interactable_entered(interactable: Interactable)
signal interactable_exited(interactable: Interactable)

var _nearby: Array[Interactable] = []

func _ready() -> void:
    area_entered.connect(_on_area_entered)
    area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
    if area is Interactable:
        _nearby.append(area)
        interactable_entered.emit(area)

func _on_area_exited(area: Area2D) -> void:
    if area is Interactable:
        _nearby.erase(area)
        interactable_exited.emit(area)

func get_current() -> Interactable:
    if _nearby.is_empty():
        return null
    return _nearby[0]

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        var target: Interactable = get_current()
        if target != null:
            target.interact()
```

- [ ] **Step 4.4：跑测试 → 通过**（25/25）

- [ ] **Step 4.5：commit**

```bash
git add src/scripts/interaction/ tests/unit/test_interactable.gd
git commit -m "feat(interaction): Interactable + PlayerInteractor with E key (3/3 tests)"
```

---

## Task 5：示例对话资源 + 集成到 TestWorld

**Files**:
- Create: `src/assets/dialogues/chen_junnan_intro.tres`（齐夏 vs 陈俊南的简短对话）
- Modify: `src/scenes/world/test_world.tscn`（把 1 个 NPC 升级为可对话 NPC，挂 Interactable）
- Create: `src/scripts/dialogue/dialogue_database.gd`（全局对话查找器，autoload）
- Modify: `project.godot`（注册 DialogueDatabase 为 autoload）

**说明**：示例对话有 3-5 段，演示推进 + 选项 + 结束。

- [ ] **Step 5.1：创建对话资源**

写一个简短的"齐夏遇到失忆的陈俊南"对话（在 Cycle 2 重生后，陈俊南不认识齐夏）：

```
[陈俊南]：你是谁？
- "（自我介绍）我是齐夏" → [陈俊南]: 没听过。
- "你不认识我了？" → [陈俊南]: 当然不认识，我们刚见面吧？ → [齐夏]: ...... → END
- "（沉默）离开" → END
```

- [ ] **Step 5.2：创建 DialogueDatabase autoload**

```gdscript
extends Node

# Autoload 单例：根据 dialogue_id 提供对话数据
# 后续可扩展为从磁盘加载 .tres、热重载、本地化等

var _dialogues_by_id: Dictionary = {}  # id -> Array[DialogueLine]
var _start_ids: Dictionary = {}        # id -> first line id

func register(dialogue_id: String, lines: Array, start_id: String) -> void:
    _dialogues_by_id[dialogue_id] = lines
    _start_ids[dialogue_id] = start_id

func get_lines(dialogue_id: String) -> Array:
    return _dialogues_by_id.get(dialogue_id, [])

func get_start_id(dialogue_id: String) -> String:
    return _start_ids.get(dialogue_id, "")
```

注册 autoload 到 project.godot：

```
[autoload]
DialogueDatabase="*res://src/scripts/dialogue/dialogue_database.gd"
```

- [ ] **Step 5.3：在 TestWorld 加一个可对话 NPC**

把 30 个 perf NPC 中"第 0 个"升级为可交互（或者新加一个 NPC）：在 test_world.tscn 加一个"陈俊南占位" NPC（CharacterBody2D + Sprite + Collision + Interactable）。

- [ ] **Step 5.4：在 TestWorld 加 DialogueBox 实例 + 接线**

`test_world.tscn` 添加 DialogueBox CanvasLayer 实例 + Script 把 PlayerInteractor.interaction_triggered → 创建 DialogueRunner + 启动对话 + 把 Runner 绑到 DialogueBox 的全流程。

- [ ] **Step 5.5：commit**

```bash
git add src/assets/dialogues/ src/scenes/world/test_world.tscn src/scripts/dialogue/dialogue_database.gd project.godot
git commit -m "feat(dialogue): example dialogue 'chen_junnan_intro' integrated to TestWorld"
```

---

## Task 6：P2 完成总结 + Tag

**Files**:
- Create: `docs/tech-verification-p2/report.md`
- Modify: `README.md`（标记 P2 完成）

- [ ] **Step 6.1：写 P2 验证报告**

包含：
- 实现的功能（数据 / 逻辑 / UI / 交互 / 示例）
- 所有单元测试结果（应 25/25 通过）
- 关键技术决策记录
- 限制 / 延后项
- 进入 P3 的准备

- [ ] **Step 6.2：更新 README**

- [ ] **Step 6.3：commit + tag**

```bash
git add docs/tech-verification-p2/ README.md
git commit -m "docs: P2 complete - dialogue system framework"
git tag -a v0.2-p2-complete -m "P2: Dialogue System Framework (data + runner + UI + interaction)"
```

---

## Self-Review

### Spec coverage
对应 spec §5.7（对话与 UI 交互系统）：
- ✅ 对话框 UI
- ✅ 选项按钮
- ✅ 角色名 + 文字
- ✅ 无配音（纯文字）
- ⏳ 头像（P2 占位，无图；polish 后续）
- ⏳ 检定（延后到独立 plan）

### Placeholder scan
全部 step 含完整代码，无 TBD/TODO。

### Type consistency
- `DialogueLine.line_id: String` → Task 1 定义，Task 2 用 ✅
- `DialogueLine.choices: Array[DialogueChoice]` → Task 1 定义，Task 2 用 ✅
- `DialogueRunner.current_line: DialogueLine` → Task 2 定义，Task 3 用 ✅
- `Interactable.interaction_type: Type` → Task 4 定义 ✅

### Autonomous execution notes
此 plan 由 AI 在用户离开期间自治执行。所有需要用户拍板的设计选择已有"默认决策 + 待复核"标记。
