class_name DialogueController
extends Node

# 把 Interactable.interaction_triggered → DialogueRunner → DialogueBox 的胶水代码
# 挂在场景里，监听场景内任何 Interactable 的对话触发，启动对应对话

@export var dialogue_box_path: NodePath          ## DialogueBox CanvasLayer 节点路径
@export var interactor_path: NodePath            ## 玩家 PlayerInteractor 节点路径

var _dialogue_box: DialogueBox = null
var _interactor: PlayerInteractor = null
var _runner: DialogueRunner = null
var _active_dialogue_id: String = ""
var _player_node: Node = null   ## 用于对话期间禁用玩家移动

func _ready() -> void:
    _dialogue_box = get_node_or_null(dialogue_box_path) as DialogueBox
    _interactor = get_node_or_null(interactor_path) as PlayerInteractor
    if _dialogue_box == null:
        push_error("DialogueController: DialogueBox not found at " + str(dialogue_box_path))
        return
    if _interactor == null:
        push_error("DialogueController: PlayerInteractor not found at " + str(interactor_path))
        return
    _player_node = _interactor.get_parent()  ## PlayerInteractor 的父节点 = Player CharacterBody2D
    _interactor.interactable_entered.connect(_on_interactable_entered)
    _dialogue_box.choice_picked.connect(_on_choice_picked)
    _dialogue_box.continue_pressed.connect(_on_continue_pressed)
    # 监听场景树中所有 Interactable
    _connect_all_interactables(get_tree().root)

func _connect_all_interactables(node: Node) -> void:
    if node is Interactable:
        var i := node as Interactable
        if not i.interaction_triggered.is_connected(_on_interaction):
            i.interaction_triggered.connect(_on_interaction)
    for child in node.get_children():
        _connect_all_interactables(child)

func _on_interactable_entered(interactable: Interactable) -> void:
    # 玩家进入 Interactable 范围时把信号连上（仅一次）
    if not interactable.interaction_triggered.is_connected(_on_interaction):
        interactable.interaction_triggered.connect(_on_interaction)

func _on_interaction(interactable: Interactable) -> void:
    match interactable.interaction_type:
        Interactable.Type.DIALOGUE:
            _start_dialogue(interactable.dialogue_id)
        _:
            push_warning("DialogueController: interaction type %s not handled" % interactable.interaction_type)

func _start_dialogue(dialogue_id: String) -> void:
    var db: Node = get_node_or_null("/root/DialogueDatabase")
    if db == null:
        push_error("DialogueController: DialogueDatabase autoload missing")
        return
    if not db.has_dialogue(dialogue_id):
        push_error("DialogueController: no dialogue '%s' registered" % dialogue_id)
        return
    var lines: Array = db.get_lines(dialogue_id)
    var start_id: String = db.get_start_id(dialogue_id)
    _runner = DialogueRunner.new()
    _active_dialogue_id = dialogue_id
    _runner.dialogue_ended.connect(_on_dialogue_ended)
    _dialogue_box.attach_runner(_runner)
    _set_player_input_enabled(false)   ## 对话期间锁住玩家
    _runner.start(lines, start_id)

func _on_choice_picked(index: int) -> void:
    if _runner != null:
        _runner.pick_choice(index)

func _on_continue_pressed() -> void:
    if _runner != null:
        _runner.advance()

func _on_dialogue_ended() -> void:
    # 把已完成的对话记录到 GameState（用于存档 + Cycle 切换时检索记忆）
    if _active_dialogue_id != "":
        var gs = get_node_or_null("/root/GameState")
        if gs != null:
            gs.mark_dialogue_completed(_active_dialogue_id)
        _active_dialogue_id = ""
    _runner = null
    _set_player_input_enabled(true)   ## 对话结束恢复玩家控制

func _set_player_input_enabled(enabled: bool) -> void:
    if _player_node == null:
        return
    # 暂停 physics_process 即可让 player.gd 的移动循环停下；
    # velocity 已经在上一帧被赋值，但 move_and_slide 不再调用，玩家会立刻停住
    _player_node.set_physics_process(enabled)
    # 同时清掉残余速度，避免恢复时"惯性滑行"
    if not enabled and _player_node.has_method("set"):
        _player_node.set("velocity", Vector2.ZERO)
