extends Node

# P10「黑熊地下室」流程编排
# - _ready：等 intro 过场 → start_game + 启 timer
# - 监听 controller 的所有信号：time/stamina/warning/judgement/impact/ended
# - 咆哮判定瞬间：查 builder.is_player_safe(player.position) → apply_roar_judgement
# - WIN：+10 道 + 胜利演出 → 回玉城
# - LOSE：检查桃木防御符 → 重置 / 失败演出 → 回玉城

@export var controller_path: NodePath = NodePath("../BearGameController")
@export var hud_path: NodePath = NodePath("../BearLairHud")
@export var builder_path: NodePath = NodePath("../Builder")
@export var intro_cutscene_path: NodePath = NodePath("../IntroCutscene")
@export var ending_cutscene_path: NodePath = NodePath("../EndingCutscene")
@export var player_path: NodePath = NodePath("../YSortContainer/Player")
@export var return_scene: String = "res://src/scenes/world/yucheng_main.tscn"

var _ctrl: BearGameController
var _hud: Node
var _builder: Node
var _intro: Node
var _ending: Node
var _player: Node

func _ready() -> void:
	_ctrl = get_node_or_null(controller_path) as BearGameController
	_hud = get_node_or_null(hud_path)
	_builder = get_node_or_null(builder_path)
	_intro = get_node_or_null(intro_cutscene_path)
	_ending = get_node_or_null(ending_cutscene_path)
	_player = get_node_or_null(player_path)

	if _ctrl == null:
		push_error("BearGameOrchestrator: controller not found")
		return

	_ctrl.time_changed.connect(_on_time_changed)
	_ctrl.stamina_changed.connect(_on_stamina_changed)
	_ctrl.roar_warning.connect(_on_roar_warning)
	_ctrl.roar_judgement_needed.connect(_on_roar_judgement_needed)
	_ctrl.roar_impact.connect(_on_roar_impact)
	_ctrl.game_ended.connect(_on_game_ended)

	call_deferred("_start_intro")

func _start_intro() -> void:
	if _intro != null and _intro.has_method("play"):
		if not _intro.finished.is_connected(_on_intro_done):
			_intro.finished.connect(_on_intro_done, CONNECT_ONE_SHOT)
		_intro.play("bear_lair_intro")
	else:
		_on_intro_done()

func _on_intro_done() -> void:
	if _ctrl != null:
		_ctrl.start_game()
		_ctrl.set("auto_tick", true)
		_ctrl.set_process(true)
	if _hud != null:
		if _hud.has_method("update_time"):
			_hud.update_time(_ctrl.time_limit)
		if _hud.has_method("update_stamina"):
			_hud.update_stamina(_ctrl.max_stamina)
	if Toast != null:
		Toast.show_info("撑过 90 秒。咆哮预警时找最近的铁柱。")

func _on_time_changed(time_left: float) -> void:
	if _hud != null and _hud.has_method("update_time"):
		_hud.update_time(time_left)

func _on_stamina_changed(stamina: int) -> void:
	if _hud != null and _hud.has_method("update_stamina"):
		_hud.update_stamina(stamina)

func _on_roar_warning(_seconds_until_roar: float) -> void:
	if _hud != null and _hud.has_method("show_warning"):
		_hud.show_warning(_ctrl.warning_duration)
	if Toast != null:
		Toast.show_error("⚠️ 黑熊准备咆哮 · 找铁柱！")
	if AudioManager != null:
		AudioManager.play_sfx("ui_open_panel")   ## 暂代预警音

func _on_roar_judgement_needed() -> void:
	# 同步：立刻查玩家是否在安全区 + 调 apply_roar_judgement
	if _player == null or _builder == null:
		_ctrl.apply_roar_judgement(false)   ## 兜底：算不安全
		return
	if _builder.has_method("is_player_safe"):
		var safe: bool = _builder.is_player_safe((_player as Node2D).position)
		_ctrl.apply_roar_judgement(safe)
		if _builder.has_method("play_roar_shake"):
			_builder.play_roar_shake()
	else:
		_ctrl.apply_roar_judgement(false)

func _on_roar_impact(was_safe: bool, _stamina_after: int) -> void:
	if AudioManager != null:
		if was_safe:
			AudioManager.play_sfx("ui_close_panel")
		else:
			AudioManager.play_sfx("skull_crack")
	if Toast != null:
		if was_safe:
			Toast.show_success("躲过去了 ✓")
		else:
			Toast.show_error("被冲击波刮中 -1 体力")

func _on_game_ended(result: int) -> void:
	if _ctrl != null:
		_ctrl.set("auto_tick", false)
	# S3：桃木防御符在地下室关也生效
	if result == BearGameController.Result.LOSE and _try_consume_defense_charm():
		return
	var dlg_id: String = ""
	if result == BearGameController.Result.WIN:
		if GameState != null and GameState.has_method("add_dao"):
			GameState.add_dao(10)
		if Toast != null:
			Toast.show_success("撑过去了！+10 道")
		if AudioManager != null:
			AudioManager.play_sfx("win_chime")
			AudioManager.play_sfx("dao_earn")
		dlg_id = "bear_win"
	else:
		if Toast != null:
			Toast.show_error("被黑熊压在地上 · 门票作废")
		if AudioManager != null:
			AudioManager.play_sfx("lose_thud")
		dlg_id = "bear_lose"
	if dlg_id != "" and _ending != null and _ending.has_method("play"):
		if not _ending.finished.is_connected(_on_ending_done):
			_ending.finished.connect(_on_ending_done, CONNECT_ONE_SHOT)
		_ending.play(dlg_id)
	else:
		_on_ending_done()

func _try_consume_defense_charm() -> bool:
	if GameState == null or not GameState.has_method("has_item"):
		return false
	if not GameState.has_item("item_defense_charm"):
		return false
	GameState.remove_item("item_defense_charm", 1)
	if Toast != null:
		Toast.show_success("桃木符替你挡了一次冲击 ✓  地下室重置")
	if AudioManager != null:
		AudioManager.play_sfx("item_use")
	if _ctrl != null:
		_ctrl.reset()
		_ctrl.start_game()
		_ctrl.set("auto_tick", true)
	if _hud != null:
		if _hud.has_method("update_time"):
			_hud.update_time(_ctrl.time_limit)
		if _hud.has_method("update_stamina"):
			_hud.update_stamina(_ctrl.max_stamina)
	return true

func _on_ending_done() -> void:
	var sm = get_node_or_null("/root/SceneManager")
	if sm != null and sm.has_method("change_to"):
		sm.change_to(return_scene)
