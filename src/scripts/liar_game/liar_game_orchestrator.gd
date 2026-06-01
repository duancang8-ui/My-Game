extends Node

# 「说谎者」关卡流程编排：
# - 监听场景中 VOTE 类型 Interactable 的触发
# - 弹出 VotePanel，玩家选择目标
# - 把选择传给 LiarGameController
# - 处理 WIN/LOSE 结果（Toast + 锁玩家）

@export var controller_path: NodePath = NodePath("../LiarGameController")
@export var vote_panel_path: NodePath = NodePath("../VotePanel")
@export var player_path: NodePath = NodePath("../YSortContainer/Player")

var _ctrl: LiarGameController
var _panel: Node
var _player: Node

func _ready() -> void:
    _ctrl = get_node_or_null(controller_path) as LiarGameController
    _panel = get_node_or_null(vote_panel_path)
    _player = get_node_or_null(player_path)
    if _ctrl == null or _panel == null:
        push_error("LiarGameOrchestrator: missing controller or vote_panel")
        return
    _ctrl.vote_submitted.connect(_on_vote_submitted)
    _panel.vote_picked.connect(_on_vote_picked)
    # 监听整个场景树中的所有 Interactable
    _connect_all_interactables(get_tree().root)

func _connect_all_interactables(node: Node) -> void:
    if node is Interactable:
        var inter := node as Interactable
        if not inter.interaction_triggered.is_connected(_on_interaction):
            inter.interaction_triggered.connect(_on_interaction)
    for child in node.get_children():
        _connect_all_interactables(child)

func _on_interaction(interactable: Interactable) -> void:
    if interactable.interaction_type != Interactable.Type.VOTE:
        return  # DIALOGUE 等其他类型已由 DialogueController 处理
    if _ctrl.state == LiarGameController.State.SUBMITTED:
        if Toast != null:
            Toast.show_info("你已提交过答案了。")
        return
    _panel.show_for_npcs(LiarNpcId.ALL)

func _on_vote_picked(npc_id: String) -> void:
    _ctrl.submit_vote(npc_id)

func _on_vote_submitted(target_id: String, result: int) -> void:
    var target_name: String = LiarNpcId.name_of(target_id)
    match result:
        LiarGameController.Result.WIN:
            if Toast != null:
                Toast.show_success("识破了！「说谎者」就是 %s ✓" % target_name)
        LiarGameController.Result.LOSE:
            if Toast != null:
                Toast.show_error("失败！%s 不是说谎者。全员被人羊制裁。" % target_name)
            _lock_player()

func _lock_player() -> void:
    if _player != null:
        _player.set_physics_process(false)
        if _player.has_method("set"):
            _player.set("velocity", Vector2.ZERO)
        # 视觉变暗
        var modulate := Color(0.4, 0.3, 0.3, 1.0)
        if _player is CanvasItem:
            (_player as CanvasItem).modulate = modulate
