extends Node

# P8「人鼠 · 仓库寻道」关卡流程编排
# 流程：
#   - 玩家进场（玉城已扣 1 道）→ _ready 启动倒计时 + 人鼠门口宣布规则过场
#   - 玩家触发"仓鼠协会"贴纸 → mark observed clue
#   - 玩家走到门口跟人鼠对话：
#       · 未观察过线索 → rat_door_talk（普通寒暄）
#       · 已观察过线索 → rat_door_talk_v2（含"摸她口袋"赢取选项）
#   - 玩家选择"摸口袋" → reveal_win → 胜利演出 → 回玉城 + 2 道
#   - 5 分钟超时 → 失败演出 → 回玉城（道币已扣，不再追加）
#   - 玩家走"离开门" → 直接回玉城（视为放弃；门票不退）

const RAT_CLUE_ID: String = "rat_hamster_note"

@export var controller_path: NodePath = NodePath("../RatGameController")
@export var hud_path: NodePath = NodePath("../RatGameHud")
@export var intro_cutscene_path: NodePath = NodePath("../IntroCutscene")
@export var ending_cutscene_path: NodePath = NodePath("../EndingCutscene")
@export var dialogue_controller_path: NodePath = NodePath("../DialogueController")
@export var npc_door_path: NodePath = NodePath("../YSortContainer/RatNpc/Interactable")
@export var return_scene: String = "res://src/scenes/world/yucheng_main.tscn"
@export var zhuque_cinematic_path: NodePath = NodePath("../ZhuqueCinematic")   ## P8.5

var _ctrl: RatGameController
var _hud: Node
var _intro: Node           ## CutsceneController
var _ending: Node          ## CutsceneController
var _dlg_ctrl: DialogueController
var _npc_door: Interactable
var _has_started_game: bool = false
var _bet_mode: bool = false   ## P8.5：本次进场是否为「赌命」模式
var _zhuque: Node             ## P8.5：朱雀处决演出 cinematic

func _ready() -> void:
	_ctrl = get_node_or_null(controller_path) as RatGameController
	_hud = get_node_or_null(hud_path)
	_intro = get_node_or_null(intro_cutscene_path)
	_ending = get_node_or_null(ending_cutscene_path)
	_dlg_ctrl = get_node_or_null(dialogue_controller_path) as DialogueController
	_npc_door = get_node_or_null(npc_door_path) as Interactable
	_zhuque = get_node_or_null(zhuque_cinematic_path)

	# P8.5：从 GameState 读「是否赌命模式」（YuchengOrchestrator 入场时设置）
	if GameState != null:
		_bet_mode = bool(GameState.rat_bet_mode)
		# 立刻消费 flag（避免下次进场误带）
		GameState.rat_bet_mode = false
	if _bet_mode and Toast != null:
		Toast.show_info("「赌命」模式 · 输了……朱雀会亲自来")

	if _ctrl == null:
		push_error("RatGameOrchestrator: controller not found")
		return

	_ctrl.time_changed.connect(_on_time_changed)
	_ctrl.game_ended.connect(_on_game_ended)
	if _dlg_ctrl != null:
		_dlg_ctrl.dialogue_ended_with_id.connect(_on_dialogue_ended_with_id)

	# 一进场就启动 intro → 完毕后开计时
	call_deferred("_start_intro")

func _start_intro() -> void:
	if _intro != null and _intro.has_method("play"):
		if not _intro.finished.is_connected(_on_intro_done):
			_intro.finished.connect(_on_intro_done, CONNECT_ONE_SHOT)
		_intro.play("rat_warehouse_intro")
	else:
		_on_intro_done()

func _on_intro_done() -> void:
	_refresh_door_dialogue_id()
	if _ctrl != null:
		_ctrl.start_game()
		_ctrl.set("auto_tick", true)
		_ctrl.set_process(true)
	_has_started_game = true
	if _hud != null and _hud.has_method("update_time"):
		_hud.update_time(_ctrl.time_limit)
	if Toast != null:
		Toast.show_info("5 分钟内找到「道」并带出去")

func _on_time_changed(time_left: float) -> void:
	if _hud != null and _hud.has_method("update_time"):
		_hud.update_time(time_left)

func _on_dialogue_ended_with_id(dialogue_id: String) -> void:
	# 观察了仓鼠协会贴纸 → 解锁门口"摸口袋"选项
	if dialogue_id == RAT_CLUE_ID:
		_refresh_door_dialogue_id()
	# 玩家选了"摸口袋" → 触发胜利
	elif dialogue_id == "rat_door_talk_v2":
		_ctrl.reveal_win()

func _refresh_door_dialogue_id() -> void:
	# 根据是否已观察过线索，把人鼠 NPC 的 dialogue_id 切换到 v1/v2
	if _npc_door == null:
		return
	var gs = get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("has_observed") and gs.has_observed(RAT_CLUE_ID):
		_npc_door.dialogue_id = "rat_door_talk_v2"
	else:
		_npc_door.dialogue_id = "rat_door_talk"

func _on_game_ended(result: int) -> void:
	# S3：桃木防御符在仓库关也生效（LOSE 时消耗 1 个 → 关卡重启）
	if result == RatGameController.Result.LOSE and _try_consume_defense_charm():
		return
	if _hud != null:
		_hud.visible = false
	if _ctrl != null:
		_ctrl.set("auto_tick", false)
	var dlg_id: String = ""
	match result:
		RatGameController.Result.WIN:
			# P8.5：赌命模式 +5 道（净 +4）；普通 +2 道（净 +1）
			var reward: int = 5 if _bet_mode else 2
			if GameState != null and GameState.has_method("add_dao"):
				GameState.add_dao(reward)
			if Toast != null:
				if _bet_mode:
					Toast.show_success("识破了人鼠！[赌命] +%d 道" % reward)
				else:
					Toast.show_success("识破了人鼠！+%d 道" % reward)
			if AudioManager != null:
				AudioManager.play_sfx("rat_pocket_reveal")
				AudioManager.play_sfx("dao_earn")
			dlg_id = "rat_win"
		RatGameController.Result.LOSE:
			if _bet_mode:
				# P8.5：赌命输 → 朱雀演出
				_play_zhuque_then_end()
				return
			if Toast != null:
				Toast.show_error("时间到 ⌛ 门票作废")
			if AudioManager != null:
				AudioManager.play_sfx("lose_thud")
			dlg_id = "rat_lose_timeout"
	# 用 ending cutscene 播放收尾对话；完毕后切回玉城
	if dlg_id != "" and _ending != null and _ending.has_method("play"):
		if not _ending.finished.is_connected(_on_ending_done):
			_ending.finished.connect(_on_ending_done, CONNECT_ONE_SHOT)
		_ending.play(dlg_id)
	else:
		_on_ending_done()

func _on_ending_done() -> void:
	var sm = get_node_or_null("/root/SceneManager")
	if sm != null and sm.has_method("change_to"):
		sm.change_to(return_scene)

# P8.5：朱雀处决演出（红色 fade + 长对话 + 回玉城）
func _play_zhuque_then_end() -> void:
	if _hud != null:
		_hud.visible = false
	if _ctrl != null:
		_ctrl.set("auto_tick", false)
	if Toast != null:
		Toast.show_error("远处传来一声鸟啼……")
	if AudioManager != null:
		AudioManager.play_sfx("skull_crack")
	# 第 1 步：红色 fade（如果有 cinematic 节点）
	if _zhuque != null and _zhuque.has_method("play"):
		if not _zhuque.finished.is_connected(_on_zhuque_fade_done):
			_zhuque.finished.connect(_on_zhuque_fade_done, CONNECT_ONE_SHOT)
		_zhuque.play(
			"朱雀飞临",
			"愿赌服输。",
			Color(0.55, 0.05, 0.05, 0.85)
		)
	else:
		_on_zhuque_fade_done()

func _on_zhuque_fade_done() -> void:
	# 第 2 步：紧接着播 rat_bet_lose_zhuque 对话
	if _ending != null and _ending.has_method("play"):
		if not _ending.finished.is_connected(_on_ending_done):
			_ending.finished.connect(_on_ending_done, CONNECT_ONE_SHOT)
		_ending.play("rat_bet_lose_zhuque")
	else:
		_on_ending_done()

# ===== S3 · 道具效果覆盖到人鼠关 =====

# 桃木防御符：LOSE 时消耗 1 个 → 关卡重启
func _try_consume_defense_charm() -> bool:
	if GameState == null or not GameState.has_method("has_item"):
		return false
	if not GameState.has_item("item_defense_charm"):
		return false
	GameState.remove_item("item_defense_charm", 1)
	if Toast != null:
		Toast.show_success("桃木符替你挡了一次 ✓  仓库重置")
	if AudioManager != null:
		AudioManager.play_sfx("item_use")
	# 重启：重置计时 + 重置 controller + 重新启动
	if _ctrl != null:
		_ctrl.reset()
		_ctrl.start_game()
		_ctrl.set("auto_tick", true)
	if _hud != null:
		_hud.visible = true
		if _hud.has_method("update_time"):
			_hud.update_time(_ctrl.time_limit)
	return true

func _unhandled_input(event: InputEvent) -> void:
	if _ctrl == null or _ctrl.state != RatGameController.State.PLAYING:
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

# 线索袋：消耗 1 → 直接揭示「仓鼠协会贴纸」线索 → 解锁人鼠 NPC 的 v2 对话
func _try_use_clue_bag() -> void:
	if GameState == null or not GameState.has_method("has_item"):
		return
	if not GameState.has_item("item_clue_bag"):
		if Toast != null:
			Toast.show_error("你没有「线索袋」")
		return
	if GameState.has_observed(RAT_CLUE_ID):
		if Toast != null:
			Toast.show_info("线索已经摸清了")
		return
	GameState.remove_item("item_clue_bag", 1)
	GameState.mark_observed(RAT_CLUE_ID)
	_refresh_door_dialogue_id()   # 立即解锁 v2「摸口袋」选项
	if Toast != null:
		Toast.show_success("线索袋打开了 ✓  仓鼠的习惯——把东西藏在颊袋")
	if AudioManager != null:
		AudioManager.play_sfx("item_use")

# 灵闻笔记：消耗 1 → 直接 Toast 指明「她口袋鼓鼓的」+ 解锁 v2
func _try_use_smell_note() -> void:
	if GameState == null or not GameState.has_method("has_item"):
		return
	if not GameState.has_item("item_smell_note"):
		if Toast != null:
			Toast.show_error("你没有「灵闻笔记」")
		return
	GameState.remove_item("item_smell_note", 1)
	# 灵闻笔记在这里也起到"揭线索"作用，标记观察点同时切对话 id
	GameState.mark_observed(RAT_CLUE_ID)
	_refresh_door_dialogue_id()
	if Toast != null:
		Toast.show_info("灵闻 · 你嗅到门口那姑娘的口袋——有股温热的、隐隐发光的味道")
	if AudioManager != null:
		AudioManager.play_sfx("item_use")
