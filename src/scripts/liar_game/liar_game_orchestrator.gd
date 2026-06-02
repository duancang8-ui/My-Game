extends Node

# 「说谎者」关卡流程编排（P4.7 重构）
# 原作真相：所有 9 位"参与者"都抽到"说谎者"卡。唯一的正解是「人羊」(SHEEP_MASTER)。
# 因此：
#   - 投人羊 → WIN
#   - 投任意参与者 → LOSE（reason="wrong_vote"）
#   - 超时未投 → LOSE（reason="time_up"）
# 此重构同时删除了 P4.6 加的 hint 系统（暗示真假博弈）—— 原作没有这个机制，
# 玩家应靠"自己观察"和"NPC v2/v3 对话里的细节"推断真相。

@export var controller_path: NodePath = NodePath("../LiarGameController")
@export var vote_panel_path: NodePath = NodePath("../VotePanel")
@export var result_screen_path: NodePath = NodePath("../ResultScreen")
@export var player_path: NodePath = NodePath("../YSortContainer/Player")
@export var cutscene_path: NodePath = NodePath("../OpeningCutscene")
@export var rules_cutscene_path: NodePath = NodePath("../SheepRulesCutscene")
@export var level_hud_path: NodePath = NodePath("../LevelHUD")
@export var lose_cinematic_path: NodePath = NodePath("../LoseCinematic")
@export var win_cinematic_path: NodePath = NodePath("../WinCinematic")
# P4 final · 4.8 phase 2 节点（在同房间继续转桌）
@export var rainy_in_room_cutscene_path: NodePath = NodePath("../RainyInRoomCutscene")
@export var rotate_controller_path: NodePath = NodePath("../RotateGameController")
@export var rotate_hud_path: NodePath = NodePath("../RotateGameHud")
@export var ysort_path: NodePath = NodePath("../YSortContainer")

var _ctrl: LiarGameController
var _panel: Node
var _result_screen: Node
var _player: Node
var _opening: Node
var _rules: Node
var _hud: CanvasLayer
var _lose_cinematic: Node
var _win_cinematic: Node
# P4 final · 4.8
var _rainy_cutscene: Node
var _rotate_ctrl: RotateGameController
var _rotate_hud: Node
var _phase: int = 1   ## 1 = 说谎者 / 2 = 雨后春笋
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
    _ctrl.time_changed.connect(_on_time_changed)
    _ctrl.time_expired.connect(_on_time_expired)
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
    _lose_cinematic = get_node_or_null(lose_cinematic_path)
    _win_cinematic = get_node_or_null(win_cinematic_path)
    # P4 final · 4.8 phase 2 节点
    _rainy_cutscene = get_node_or_null(rainy_in_room_cutscene_path)
    _rotate_ctrl = get_node_or_null(rotate_controller_path) as RotateGameController
    _rotate_hud = get_node_or_null(rotate_hud_path)
    if _rotate_ctrl != null:
        _rotate_ctrl.rotated.connect(_on_rotate_rotated)
        _rotate_ctrl.time_changed.connect(_on_rotate_time_changed)
        _rotate_ctrl.game_ended.connect(_on_rotate_ended)

    _connect_all_interactables(get_tree().root)

    if _hud != null:
        _hud.visible = false

    call_deferred("_start_intro_flow")

func _start_intro_flow() -> void:
    print("[LiarOrch] _start_intro_flow opening=%s rules=%s" % [_opening, _rules])
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
    print("[LiarOrch] opening done")
    if _rules != null:
        _rules.finished.connect(_on_rules_done, CONNECT_ONE_SHOT)
        _rules.play("liar_sheep_rules")
    else:
        _enable_gameplay()

func _on_rules_done() -> void:
    print("[LiarOrch] rules done → enable gameplay")
    _enable_gameplay()

func _enable_gameplay() -> void:
    print("[LiarOrch] _enable_gameplay: unlocking player + showing HUD")
    if _hud != null:
        _hud.visible = true
        if _hud.has_method("update_timer"):
            _hud.update_timer(_ctrl.time_left)
        _show_environment_clue()
    _unlock_player()
    if _ctrl != null:
        _ctrl.set("auto_tick", true)
        _ctrl.set_process(true)
    if Toast != null:
        Toast.show_info("和每个人都聊聊。然后到桌上的座钟前写下名字。⏳ 10 分钟")

func _show_environment_clue() -> void:
    # 没有「人羊暗示」——改为提示玩家观察环境
    # 每次进入随机选一句「环境观察」线索，让玩家意识到房间有蹊跷
    if _hud == null or not _hud.has_method("set_sheep_hint"):
        return
    var clues: Array = [
        "[color=#aaaaaa]（齐夏暗想）这屋子没有门……我们是怎么进来的？[/color]",
        "[color=#aaaaaa]（齐夏暗想）墙面和地板都有方格线……是有人在量什么吗？[/color]",
        "[color=#aaaaaa]（齐夏暗想）他说「九位」，可桌边明明坐着十个人……[/color]",
        "[color=#aaaaaa]（齐夏暗想）座钟还在走……可这房间到底是什么时候开始计时的？[/color]",
    ]
    var rng: RandomNumberGenerator = _ctrl.get_rng() if _ctrl != null else RandomNumberGenerator.new()
    if _ctrl == null:
        rng.randomize()
    _hud.set_sheep_hint(clues[rng.randi() % clues.size()])

func _on_time_changed(time_left: float) -> void:
    if _hud != null and _hud.has_method("update_timer"):
        _hud.update_timer(time_left)

func _on_time_expired() -> void:
    print("[LiarOrch] time expired → force_lose triggers vote_submitted")
    if _hud != null and _hud.has_method("hide_timer"):
        _hud.hide_timer()

func _connect_all_interactables(node: Node) -> void:
    if node is Interactable:
        var inter := node as Interactable
        if not inter.interaction_triggered.is_connected(_on_interaction):
            inter.interaction_triggered.connect(_on_interaction)
    for child in node.get_children():
        _connect_all_interactables(child)

func _on_interaction(interactable: Interactable) -> void:
    if interactable.interaction_type != Interactable.Type.VOTE:
        return
    if _ctrl.state == LiarGameController.State.SUBMITTED:
        if Toast != null:
            Toast.show_info("你已经写下答案了。")
        return
    # 候选 = 8 NPC + 人羊（VotePanel 内部把人羊单独渲染）
    _panel.show_for_npcs(LiarNpcId.ALL_VOTE_TARGETS)

func _on_vote_picked(npc_id: String) -> void:
    _ctrl.submit_vote(npc_id)

func _on_vote_submitted(target_id: String, result: int) -> void:
    if _ctrl != null:
        _ctrl.set("auto_tick", false)
    if _hud != null and _hud.has_method("hide_timer"):
        _hud.hide_timer()

    match result:
        LiarGameController.Result.WIN:
            _play_win_cinematic_then_result()
        LiarGameController.Result.LOSE:
            # P9：桃木防御符自动抵一次「制裁」
            if _try_consume_defense_charm():
                return
            _lock_player()
            _play_lose_cinematic_then_result(target_id)

# P9 · 桃木防御符：消耗 1 个 → 不进入 LOSE 演出，直接 retry 关卡
func _try_consume_defense_charm() -> bool:
    if GameState == null or not GameState.has_method("has_item"):
        return false
    if not GameState.has_item("item_defense_charm"):
        return false
    GameState.remove_item("item_defense_charm", 1)
    if Toast != null:
        Toast.show_success("桃木符替你挡了一次「制裁」 ✓  关卡重置")
    call_deferred("_on_retry")
    return true

func _play_win_cinematic_then_result() -> void:
    if Toast != null:
        Toast.show_success("纸上写着「人羊」—— 九份答案完全一致 ✓")
    if _win_cinematic != null and _win_cinematic.has_method("play"):
        if not _win_cinematic.finished.is_connected(_on_win_cinematic_done):
            _win_cinematic.finished.connect(_on_win_cinematic_done, CONNECT_ONE_SHOT)
        _win_cinematic.play(
            "枪声",
            "人羊掏出枪，对准了自己的心脏。\n屋子里只剩一声闷响——",
            Color(0.85, 0.75, 0.45, 0.55)   ## 暖金调
        )
    else:
        _on_win_cinematic_done()

func _on_win_cinematic_done() -> void:
    # P4 final · c3：胜利奖励 5 道
    if GameState != null and GameState.has_method("add_dao"):
        GameState.add_dao(5)
        if Toast != null:
            Toast.show_success("说谎者关卡过关  +5 道")
    # P4 final · 4.8：不再直接出门，而是同房间触发雨后春笋衔接
    _start_phase2()

# ===== P4 final · 4.8 Phase 2：雨后春笋（同房间）=====

func _start_phase2() -> void:
    print("[LiarOrch] start phase 2: rainy in same room")
    _phase = 2
    # 清理 phase 1 的所有可交互对象（NPC 对话 / 观察点 / 提交标记 / 人羊对话）
    _cleanup_phase1_interactables()
    if _hud != null:
        _hud.visible = false   ## 隐藏「说谎者」HUD
    # 触发衔接过场
    if _rainy_cutscene != null and _rainy_cutscene.has_method("play"):
        if not _rainy_cutscene.finished.is_connected(_on_phase2_intro_done):
            _rainy_cutscene.finished.connect(_on_phase2_intro_done, CONNECT_ONE_SHOT)
        _rainy_cutscene.play("rainy_in_room_intro")
    else:
        _on_phase2_intro_done()

func _cleanup_phase1_interactables() -> void:
    # 把所有以 NPC / 观察点 / SubmitMarker / 人羊为名的子节点的 Interactable 摘掉
    # 但保留它们的 Sprite，让画面里依然有「人围在桌边」的氛围
    var ysort: Node = get_node_or_null(ysort_path)
    if ysort == null:
        return
    for child in ysort.get_children():
        if child == _player:
            continue
        # 找子节点里的 Interactable Area2D
        for sub in child.get_children():
            if sub is Interactable:
                sub.queue_free()

func _on_phase2_intro_done() -> void:
    print("[LiarOrch] phase 2 intro done → start rotate game")
    # 显示 RotateGameHud + 启动 RotateGameController
    if _rotate_hud != null:
        _rotate_hud.visible = true
        if _rotate_hud.has_method("update_time"):
            _rotate_hud.update_time(_rotate_ctrl.time_limit)
        if _rotate_hud.has_method("update_progress"):
            _rotate_hud.update_progress(0, _rotate_ctrl.target_rotations)
    if _rotate_ctrl != null:
        _rotate_ctrl.set_process(true)
        _rotate_ctrl.start_game()
    _unlock_player()
    if Toast != null:
        Toast.show_info("按 [E] 转动桌子，30 秒内转够 100 圈！")

func _on_rotate_rotated(current: int, target: int) -> void:
    if _rotate_hud != null and _rotate_hud.has_method("update_progress"):
        _rotate_hud.update_progress(current, target)
    if current % 25 == 0 and current > 0 and current < target and Toast != null:
        Toast.show_info("还差 %d 圈！" % (target - current))

func _on_rotate_time_changed(time_left: float) -> void:
    if _rotate_hud != null and _rotate_hud.has_method("update_time"):
        _rotate_hud.update_time(time_left)

func _on_rotate_ended(result: int) -> void:
    if _rotate_hud != null:
        _rotate_hud.visible = false
    if result == RotateGameController.Result.WIN:
        # P4 final · c3：转桌也给奖励
        if GameState != null and GameState.has_method("add_dao"):
            GameState.add_dao(3)
        if Toast != null:
            Toast.show_success("春笋盾牌长出来了  +3 道")
        if _result_screen != null:
            _result_screen.show_win(
                "活到了下一关",
                "你和其他八个人一起把桌子转过了一百圈。\n桌面碎成九块尖角板，被你们快速拼成一个棱锥——\n[color=#ffd93d]鱼叉从四面八方落下，却被春笋牢牢挡住。[/color]\n\n远处的狗叫渐渐远去。一道门在房间侧墙出现了。"
            )
        _spawn_exit_to_yucheng()
    else:
        _lock_player()
        if Toast != null:
            Toast.show_error("鱼叉穿透了你")
        if _result_screen != null:
            _result_screen.show_lose(
                "雨后无春笋",
                "你转得不够快。\n头顶的鱼叉如雨般落下，无一遗漏。"
            )

func _unhandled_input(event: InputEvent) -> void:
    # Phase 2：按 E 转桌
    if _phase == 2:
        if _rotate_ctrl == null:
            return
        if _rotate_ctrl.state != RotateGameController.State.PLAYING:
            return
        if event.is_action_pressed("interact"):
            _rotate_ctrl.add_rotation()
            get_viewport().set_input_as_handled()
        return
    # Phase 1：P9 道具快捷键（C = 线索袋，X = 灵闻笔记）
    if _phase != 1:
        return
    if _ctrl == null or _ctrl.state != LiarGameController.State.PLAYING:
        return
    if not (event is InputEventKey):
        return
    var k := event as InputEventKey
    if not k.pressed or k.echo:
        return
    if k.keycode == KEY_C:
        _try_use_clue_bag()
        get_viewport().set_input_as_handled()
    elif k.keycode == KEY_X:
        _try_use_smell_note()
        get_viewport().set_input_as_handled()

# P9 · 线索袋：消耗 1 → 随机揭示 1 个未观察线索
const _CLUE_LABELS: Dictionary = {
    "observe_wall_grid": "墙上的方格",
    "observe_clock":     "桌上的座钟",
    "observe_corpse":    "桌上的尸体",
}

func _try_use_clue_bag() -> void:
    if GameState == null or not GameState.has_method("has_item"):
        return
    if not GameState.has_item("item_clue_bag"):
        if Toast != null:
            Toast.show_error("你没有「线索袋」")
        return
    # 找一个尚未观察的线索
    var candidates: Array = []
    for cid in _CLUE_LABELS.keys():
        if not GameState.has_observed(cid):
            candidates.append(cid)
    if candidates.is_empty():
        if Toast != null:
            Toast.show_info("你已经观察过这屋子的所有线索了")
        return
    var rng: RandomNumberGenerator = _ctrl.get_rng() if _ctrl != null and _ctrl.has_method("get_rng") else RandomNumberGenerator.new()
    var picked: String = candidates[rng.randi() % candidates.size()]
    GameState.remove_item("item_clue_bag", 1)
    GameState.mark_observed(picked)
    if Toast != null:
        Toast.show_success("线索袋打开了 ✓  你「看到」了：%s" % _CLUE_LABELS[picked])
    # 触发灵光闪现检查（与 DialogueController._on_dialogue_ended 同款逻辑）
    if GameState.observed_clue_count() >= 3 and not GameState.completed_dialogues.has("liar_insight"):
        var dc = get_node_or_null("../DialogueController")
        if dc != null and dc.has_method("_start_dialogue"):
            dc.call_deferred("_start_dialogue", "liar_insight")

# P9 · 灵闻笔记：消耗 1 → 随机闻 1 个未灵闻的 NPC
# 清香摘要是本项目自创笔触：保留人物姓名作为事实参考，所有描述均原创
const _SMELL_TABLE: Dictionary = {
    "liar_sheep_master":  "浓郁的腐臭，混着别的什么……像「不属于人」的味道。这是答案的方向。",
    "liar_tiantian":      "脂粉味偏重，底下有一点点酸涩。普通人。",
    "liar_qiao_jiajin":   "陈年烟味、汗，还有一丝若有若无的血腥。普通人。",
    "liar_han_yimo":      "墨水。还有一点冷意。普通人。",
    "liar_zhang_chenze":  "干净到刻意的消毒水味。普通人。",
    "liar_li_shangwu":    "火药燃过的余烬。普通人。",
    "liar_lin_qin":       "极淡的薄荷。普通人。",
    "liar_zhao_haibo":    "医院的味道，又凉又干。普通人。",
    "liar_xiao_ran":      "几乎闻不到什么味道。普通人。",
}

func _try_use_smell_note() -> void:
    if GameState == null or not GameState.has_method("has_item"):
        return
    if not GameState.has_item("item_smell_note"):
        if Toast != null:
            Toast.show_error("你没有「灵闻笔记」")
        return
    var candidates: Array = []
    for nid in _SMELL_TABLE.keys():
        if not GameState.has_sniffed(nid):
            candidates.append(nid)
    if candidates.is_empty():
        if Toast != null:
            Toast.show_info("你已经闻遍了屋里每一个人")
        return
    var rng: RandomNumberGenerator = _ctrl.get_rng() if _ctrl != null and _ctrl.has_method("get_rng") else RandomNumberGenerator.new()
    var picked: String = candidates[rng.randi() % candidates.size()]
    GameState.remove_item("item_smell_note", 1)
    GameState.mark_sniffed(picked)
    var npc_name: String = ""
    if picked == "liar_sheep_master":
        npc_name = "人羊"
    else:
        # 把 dialogue_id 还原成 npc_id 然后查 name
        var npc_id: String = picked.substr(5)   # 去掉 "liar_" 前缀
        npc_name = LiarNpcId.name_of(npc_id)
    var desc: String = _SMELL_TABLE[picked]
    if Toast != null:
        Toast.show_info("灵闻 · %s —— %s" % [npc_name, desc])

func _play_lose_cinematic_then_result(target_id: String) -> void:
    var reason: String = _ctrl.lose_reason if _ctrl != null else "wrong_vote"
    var title: String
    var sub: String
    if reason == "time_up":
        title = "时间到了"
        sub = "「九位都没写完？」\n人羊把那只血手举了起来——"
        if Toast != null:
            Toast.show_error("时间到了 ⌛")
    else:
        title = "九份答案，不一致"
        sub = "你写下了「%s」。\n人羊看了一眼桌上的纸，慢慢摇了摇头——" % LiarNpcId.name_of(target_id)
        if Toast != null:
            Toast.show_error("你写下了 %s，但九份纸不一致。" % LiarNpcId.name_of(target_id))
    if _lose_cinematic != null and _lose_cinematic.has_method("play"):
        if not _lose_cinematic.finished.is_connected(_on_lose_cinematic_done):
            _lose_cinematic.finished.connect(_on_lose_cinematic_done.bind(target_id, reason), CONNECT_ONE_SHOT)
        _lose_cinematic.play(title, sub, Color(0.6, 0.05, 0.05, 0.85))
    else:
        _on_lose_cinematic_done(target_id, reason)

func _on_lose_cinematic_done(target_id: String, reason: String) -> void:
    if _result_screen != null:
        if reason == "time_up":
            _result_screen.show_lose(
                "时间耗尽",
                "你还没在纸上写下名字。\n人羊抬起手——其余八人和你一起，被「制裁」。"
            )
        else:
            _result_screen.show_lose(
                "九人同归",
                "九张纸上至少有一张写了错的名字。\n规则是绝对的。\n人羊抬起手——"
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
    _ctrl.reset()
    if _player != null:
        _player.position = _player_initial_position
    _unlock_player()
    if _hud != null and _hud.has_method("update_timer"):
        _hud.update_timer(_ctrl.time_left)
    _ctrl.set("auto_tick", true)
    _ctrl.set_process(true)
    if Toast != null:
        Toast.show_info("再来一次。这一次你打算写谁？")

func _on_load_save() -> void:
    var ss = get_node_or_null("/root/SaveSystem")
    if ss == null:
        if Toast != null:
            Toast.show_error("存档系统未就绪")
        return
    var ok: bool = ss.load_from_slot(0)
    if not ok:
        if Toast != null:
            Toast.show_info("没有可读取的存档（建议先 F9 存一次）")
        _on_retry()
        return
    _ctrl.reset()
    _unlock_player()
    if _player != null and GameState != null:
        _player.position = GameState.player_position
    if Toast != null:
        Toast.show_success("已读取存档 ✓")

func _on_continue() -> void:
    if Toast != null:
        Toast.show_info("（人羊面具的内衬有字……走到墙边出口出去吧）")

func _spawn_exit_to_yucheng() -> void:
    # P4.7：胜利后房间一侧凭空出现门，门外是玉城（原作 Cycle 2 醒来的地方）
    var ysort: Node = get_node_or_null("../YSortContainer")
    if ysort == null:
        return
    var interactable_script: Script = load("res://src/scripts/interaction/interactable.gd")
    var door: Node2D = Node2D.new()
    door.name = "ExitDoor"
    door.position = Vector2(680, 280)

    var sprite: Sprite2D = Sprite2D.new()
    sprite.texture = preload("res://src/assets/characters/submit_marker.png")
    sprite.modulate = Color(0.5, 0.85, 1.0, 1.0)
    sprite.scale = Vector2(1.5, 1.5)
    door.add_child(sprite)

    var label: Label = Label.new()
    label.text = "[出口 · 玉城]"
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
    inter.set("scene_path", "res://src/scenes/world/yucheng_main.tscn")
    inter.set("prompt_text", "[E] 走进玉城")
    var ishape: CollisionShape2D = CollisionShape2D.new()
    var icirc: CircleShape2D = CircleShape2D.new()
    icirc.radius = 32
    ishape.shape = icirc
    inter.add_child(ishape)
    door.add_child(inter)

    ysort.add_child(door)
