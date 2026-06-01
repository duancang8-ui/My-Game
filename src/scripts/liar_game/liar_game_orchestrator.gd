extends Node

# 「说谎者」关卡流程编排：
# - 监听场景中 VOTE 类型 Interactable 的触发
# - 弹出 VotePanel，玩家选择目标
# - 把选择传给 LiarGameController
# - 处理 WIN/LOSE 结果（Toast + 锁玩家）

@export var controller_path: NodePath = NodePath("../LiarGameController")
@export var vote_panel_path: NodePath = NodePath("../VotePanel")
@export var result_screen_path: NodePath = NodePath("../ResultScreen")
@export var player_path: NodePath = NodePath("../YSortContainer/Player")
@export var cutscene_path: NodePath = NodePath("../OpeningCutscene")
@export var rules_cutscene_path: NodePath = NodePath("../SheepRulesCutscene")
@export var level_hud_path: NodePath = NodePath("../LevelHUD")

var _ctrl: LiarGameController
var _panel: Node
var _result_screen: Node
var _player: Node
var _opening: Node
var _rules: Node
var _hud: CanvasLayer
var _player_initial_position: Vector2 = Vector2.ZERO
var _player_initial_modulate: Color = Color.WHITE

func _ready() -> void:
    _ctrl = get_node_or_null(controller_path) as LiarGameController
    _panel = get_node_or_null(vote_panel_path)
    _result_screen = get_node_or_null(result_screen_path)
    _player = get_node_or_null(player_path)
    if _ctrl == null or _panel == null:
        push_error("LiarGameOrchestrator: missing controller or vote_panel")
        return
    if _player != null:
        _player_initial_position = _player.position
        if _player is CanvasItem:
            _player_initial_modulate = (_player as CanvasItem).modulate
    _ctrl.vote_submitted.connect(_on_vote_submitted)
    _panel.vote_picked.connect(_on_vote_picked)
    if _result_screen != null:
        if _result_screen.has_signal("retry_pressed"):
            _result_screen.retry_pressed.connect(_on_retry)
        if _result_screen.has_signal("load_save_pressed"):
            _result_screen.load_save_pressed.connect(_on_load_save)
        if _result_screen.has_signal("continue_pressed"):
            _result_screen.continue_pressed.connect(_on_continue)

    _opening = get_node_or_null(cutscene_path)
    _rules = get_node_or_null(rules_cutscene_path)
    _hud = get_node_or_null(level_hud_path) as CanvasLayer

    # 监听整个场景树中的所有 Interactable
    _connect_all_interactables(get_tree().root)

    # 暂时禁用 HUD 直到过场结束
    if _hud != null:
        _hud.visible = false

    # 启动开场过场流程：开场 → 张强规则 → 解锁玩家 + 显示 HUD
    call_deferred("_start_intro_flow")

func _start_intro_flow() -> void:
    if _opening == null and _rules == null:
        _enable_gameplay()
        return
    if _opening != null:
        _opening.finished.connect(_on_opening_done, CONNECT_ONE_SHOT)
        _opening.play("liar_opening_cutscene")
    elif _rules != null:
        _rules.finished.connect(_on_rules_done, CONNECT_ONE_SHOT)
        _rules.play("liar_sheep_rules")

func _on_opening_done() -> void:
    if _rules != null:
        _rules.finished.connect(_on_rules_done, CONNECT_ONE_SHOT)
        _rules.play("liar_sheep_rules")
    else:
        _enable_gameplay()

func _on_rules_done() -> void:
    _enable_gameplay()

func _enable_gameplay() -> void:
    if _hud != null:
        _hud.visible = true
    if Toast != null:
        Toast.show_info("和 5 个人都谈谈，然后到桌前提交答案。")

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
            if _result_screen != null:
                _result_screen.show_win(
                    "识破了！",
                    "你成功识破了「说谎者」—— %s。\n人羊掀开山羊面具，露出诡异的微笑：'有意思的小齐夏……'\n\n[房间侧面的墙缓缓打开，露出通往「道城」的大门]" % target_name
                )
            _spawn_exit_to_daocheng()
        LiarGameController.Result.LOSE:
            if Toast != null:
                Toast.show_error("失败！%s 不是说谎者。" % target_name)
            _lock_player()
            if _result_screen != null:
                _result_screen.show_lose(
                    "全员被人羊制裁",
                    "你指认了 %s，但 TA 不是说谎者。\n人羊冷笑一声，整个房间陷入血色——" % target_name
                )

func _lock_player() -> void:
    if _player != null:
        _player.set_physics_process(false)
        if _player.has_method("set"):
            _player.set("velocity", Vector2.ZERO)
        if _player is CanvasItem:
            (_player as CanvasItem).modulate = Color(0.4, 0.25, 0.25, 1.0)

func _unlock_player() -> void:
    if _player != null:
        _player.set_physics_process(true)
        if _player is CanvasItem:
            (_player as CanvasItem).modulate = _player_initial_modulate

func _on_retry() -> void:
    # 重置关卡：玩家回初始位 + 解锁 + 重置 controller
    _ctrl.reset()
    if _player != null:
        _player.position = _player_initial_position
    _unlock_player()
    if Toast != null:
        Toast.show_info("重新开始本关。再仔细想想……")

func _on_load_save() -> void:
    # 委托给 SaveSystem 读 slot 0
    var ss = get_node_or_null("/root/SaveSystem")
    if ss == null:
        if Toast != null:
            Toast.show_error("存档系统未就绪")
        return
    var ok: bool = ss.load_from_slot(0)
    if not ok:
        if Toast != null:
            Toast.show_info("没有可读取的存档（建议先 F9 存一次）")
        # 读不到存档时也重置本关，避免玩家卡死
        _on_retry()
        return
    _ctrl.reset()
    _unlock_player()
    if _player != null and GameState != null:
        _player.position = GameState.player_position
    if Toast != null:
        Toast.show_success("已读取存档 ✓")

func _on_continue() -> void:
    # WIN 后玩家可以继续在房间里走动（关卡未"重置"，submit 仍是 SUBMITTED）
    if Toast != null:
        Toast.show_info("（看到房间一侧的蓝色光门了吗？按 E 走出去）")

func _spawn_exit_to_daocheng() -> void:
    # 胜利后在房间一侧 spawn 通往道城的门
    var ysort: Node = get_node_or_null("../YSortContainer")
    if ysort == null:
        return
    var interactable_script: Script = load("res://src/scripts/interaction/interactable.gd")
    var door: Node2D = Node2D.new()
    door.name = "ExitDoor"
    door.position = Vector2(680, 280)   ## 房间右侧

    var sprite: Sprite2D = Sprite2D.new()
    sprite.texture = preload("res://src/assets/characters/submit_marker.png")
    sprite.modulate = Color(0.5, 0.85, 1.0, 1.0)   ## 蓝色光门
    sprite.scale = Vector2(1.5, 1.5)
    door.add_child(sprite)

    var label: Label = Label.new()
    label.text = "[出口 · 道城]"
    label.position = Vector2(-40, 20)
    label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0, 1.0))
    label.add_theme_font_size_override("font_size", 11)
    door.add_child(label)

    var inter: Area2D = Area2D.new()
    inter.name = "Interactable"
    inter.set_script(interactable_script)
    inter.collision_layer = 2
    inter.collision_mask = 0
    inter.set("interaction_type", 3)   ## SCENE_CHANGE
    inter.set("scene_path", "res://src/scenes/world/daocheng_main.tscn")
    inter.set("prompt_text", "[E] 进入道城")
    var ishape: CollisionShape2D = CollisionShape2D.new()
    var icirc: CircleShape2D = CircleShape2D.new()
    icirc.radius = 32
    ishape.shape = icirc
    inter.add_child(ishape)
    door.add_child(inter)

    ysort.add_child(door)
