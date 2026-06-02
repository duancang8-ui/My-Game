extends Node

# 「雨后春笋」关卡编排
# 流程：
#   入场过场 → 解锁玩家 + 启动 RotateGameController + 显示 HUD
#   玩家按 E（interact action） → ctrl.add_rotation()
#   游戏结束（WIN/LOSE） → ResultScreen + Toast + 胜利时 spawn 返回门

@export var controller_path: NodePath = NodePath("../RotateGameController")
@export var hud_path: NodePath = NodePath("../RotateHud")
@export var result_screen_path: NodePath = NodePath("../ResultScreen")
@export var player_path: NodePath = NodePath("../YSortContainer/Player")
@export var cutscene_path: NodePath = NodePath("../IntroCutscene")

var _ctrl: RotateGameController
var _hud: Node
var _result_screen: Node
var _player: Node
var _cutscene: Node
var _player_initial_position: Vector2 = Vector2.ZERO
var _player_initial_modulate: Color = Color.WHITE
var _accepting_input: bool = false   ## 是否监听 E 键作为旋转

func _ready() -> void:
    _ctrl = get_node_or_null(controller_path) as RotateGameController
    _hud = get_node_or_null(hud_path)
    _result_screen = get_node_or_null(result_screen_path)
    _player = get_node_or_null(player_path)
    _cutscene = get_node_or_null(cutscene_path)

    if _ctrl == null:
        push_error("RotateGameOrchestrator: controller missing")
        return

    if _player != null:
        _player_initial_position = _player.position
        if _player is CanvasItem:
            _player_initial_modulate = (_player as CanvasItem).modulate

    _ctrl.rotated.connect(_on_rotated)
    _ctrl.time_changed.connect(_on_time_changed)
    _ctrl.game_ended.connect(_on_game_ended)

    if _result_screen != null:
        if _result_screen.has_signal("retry_pressed"):
            _result_screen.retry_pressed.connect(_on_retry)
        if _result_screen.has_signal("load_save_pressed"):
            _result_screen.load_save_pressed.connect(_on_load_save)
        if _result_screen.has_signal("continue_pressed"):
            _result_screen.continue_pressed.connect(_on_continue)

    if _hud != null:
        _hud.visible = false

    call_deferred("_start_intro")

func _start_intro() -> void:
    print("[RotateOrch] _start_intro cutscene=%s" % _cutscene)
    if _cutscene == null:
        _begin_round()
        return
    _cutscene.finished.connect(_on_intro_done, CONNECT_ONE_SHOT)
    _cutscene.play("rainy_field_intro")

func _on_intro_done() -> void:
    print("[RotateOrch] intro done → begin round")
    _begin_round()

func _begin_round() -> void:
    print("[RotateOrch] _begin_round: unlock + start ctrl + show HUD")
    if _hud != null:
        _hud.visible = true
        _hud.update_time(_ctrl.time_limit)
        _hud.update_progress(0, _ctrl.target_rotations)
    # 防御性：即使 cutscene 没正确 unlock，也强制 unlock
    _unlock_player()
    _ctrl.start_game()
    _accepting_input = true
    if Toast != null:
        Toast.show_info("按 [E] 旋转桌面！30 秒内转够 100 圈！")

func _unhandled_input(event: InputEvent) -> void:
    if not _accepting_input:
        return
    if event.is_action_pressed("interact"):
        _ctrl.add_rotation()
        get_viewport().set_input_as_handled()

func _on_rotated(current: int, target: int) -> void:
    if _hud != null:
        _hud.update_progress(current, target)
    # 每 25 圈一个鼓励
    if current % 25 == 0 and current > 0 and current < target and Toast != null:
        Toast.show_info("还差 %d 圈！" % (target - current))

func _on_time_changed(time_left: float) -> void:
    if _hud != null:
        _hud.update_time(time_left)

func _on_game_ended(result: int) -> void:
    _accepting_input = false
    match result:
        RotateGameController.Result.WIN:
            # P4 final · c3：胜利奖励 3 道
            if GameState != null and GameState.has_method("add_dao"):
                GameState.add_dao(3)
            if _result_screen != null:
                _result_screen.show_win(
                    "盾牌长出来了！",
                    "你转够了 100 圈——9 个春笋盾牌从桌子四周升起，正好挡住头顶飞来的鱼叉。\n人狗摇了摇尾巴：「汪——很好啊小齐夏，你过关了。」"
                )
            if Toast != null:
                Toast.show_success("过关 ✓  +3 道")
            _spawn_return_door()
        RotateGameController.Result.LOSE:
            if _result_screen != null:
                _result_screen.show_lose(
                    "鱼叉穿透了你",
                    "你转得不够快——头顶的鱼叉如雨般落下。\n（人狗在远处发出短促的笑声）"
                )
            _lock_player()

func _lock_player() -> void:
    if _player != null:
        _player.set_physics_process(false)
        if _player is CanvasItem:
            (_player as CanvasItem).modulate = Color(0.4, 0.25, 0.25)

func _unlock_player() -> void:
    if _player != null:
        _player.set_physics_process(true)
        if _player is CanvasItem:
            (_player as CanvasItem).modulate = _player_initial_modulate

func _on_retry() -> void:
    _ctrl.reset()
    _ctrl.start_game()
    if _player != null:
        _player.position = _player_initial_position
    _unlock_player()
    _accepting_input = true
    if _hud != null:
        _hud.visible = true
        _hud.update_time(_ctrl.time_limit)
        _hud.update_progress(0, _ctrl.target_rotations)
    if Toast != null:
        Toast.show_info("重新开始，加油！")

func _on_load_save() -> void:
    var ss = get_node_or_null("/root/SaveSystem")
    if ss == null or not ss.load_from_slot(0):
        _on_retry()
        if Toast != null:
            Toast.show_info("无存档，从头来过")
        return
    _on_retry()
    if Toast != null:
        Toast.show_success("已读取存档 ✓")

func _on_continue() -> void:
    if Toast != null:
        Toast.show_info("（走到蓝色门返回玉城）")

func _spawn_return_door() -> void:
    var ysort: Node = get_node_or_null("../YSortContainer")
    if ysort == null:
        return
    var interactable_script: Script = load("res://src/scripts/interaction/interactable.gd")
    var door: Node2D = Node2D.new()
    door.name = "ReturnDoor"
    door.position = Vector2(550, 460)

    var sprite: Sprite2D = Sprite2D.new()
    sprite.texture = preload("res://src/assets/characters/submit_marker.png")
    sprite.modulate = Color(0.5, 0.85, 1.0, 1.0)
    sprite.scale = Vector2(1.5, 1.5)
    door.add_child(sprite)

    var label: Label = Label.new()
    label.text = "[返回玉城]"
    label.position = Vector2(-32, 20)
    label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
    label.add_theme_font_size_override("font_size", 11)
    door.add_child(label)

    var inter: Area2D = Area2D.new()
    inter.name = "Interactable"
    inter.set_script(interactable_script)
    inter.collision_layer = 2
    inter.collision_mask = 0
    inter.set("interaction_type", 3)   ## SCENE_CHANGE
    inter.set("scene_path", "res://src/scenes/world/yucheng_main.tscn")
    inter.set("prompt_text", "[E] 返回玉城")
    var ishape: CollisionShape2D = CollisionShape2D.new()
    var icirc: CircleShape2D = CircleShape2D.new()
    icirc.radius = 32
    ishape.shape = icirc
    inter.add_child(ishape)
    door.add_child(inter)

    ysort.add_child(door)
