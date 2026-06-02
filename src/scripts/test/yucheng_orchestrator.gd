extends Node

# P7：玉城场景级"胶水"
# - 监听 DialogueController.dialogue_ended_with_id
# - 当玩家与商店老板聊完 → 弹出 ShopPanel
# 其他 NPC 对话由 DialogueController 自动处理，无需额外逻辑

@export var dialogue_controller_path: NodePath = NodePath("../DialogueController")
@export var shop_panel_path: NodePath = NodePath("../ShopPanel")

var _dialogue_ctrl: DialogueController
var _shop: Node

func _ready() -> void:
	_dialogue_ctrl = get_node_or_null(dialogue_controller_path) as DialogueController
	_shop = get_node_or_null(shop_panel_path)
	if _dialogue_ctrl != null:
		_dialogue_ctrl.dialogue_ended_with_id.connect(_on_dialogue_ended_with_id)
		_dialogue_ctrl.choice_picked_action.connect(_on_choice_action)
	else:
		push_warning("YuchengOrchestrator: DialogueController not found at " + str(dialogue_controller_path))

func _on_dialogue_ended_with_id(dialogue_id: String) -> void:
	if dialogue_id == "yu_shopkeeper":
		if _shop != null and _shop.has_method("show_panel"):
			# 等一帧让 DialogueBox 完成隐藏后再弹 ShopPanel
			call_deferred("_open_shop")

func _open_shop() -> void:
	if _shop != null and _shop.has_method("show_panel"):
		_shop.show_panel()

# P8：人鼠 NPC 的「付 1 道入场」选项触发
# P8.5：新增「赌命入场」分支（赢得更多，输了触发朱雀演出）
func _on_choice_action(action_id: String) -> void:
	if action_id == "enter_rat_warehouse":
		_enter_rat_warehouse(false)
	elif action_id == "enter_rat_warehouse_bet":
		_enter_rat_warehouse(true)

func _enter_rat_warehouse(bet_mode: bool) -> void:
	if GameState == null:
		return
	if GameState.dao_count < 1:
		if Toast != null:
			Toast.show_error("「道」不够 —— 至少要 1 个才能入场")
		return
	GameState.dao_count -= 1
	GameState.rat_bet_mode = bet_mode
	if Toast != null:
		if bet_mode:
			Toast.show_info("付了 1 道 + 押上你的命 · 进入仓库")
		else:
			Toast.show_info("付了 1 道 · 进入仓库")
	if AudioManager != null:
		AudioManager.play_sfx("dao_spend")
	var sm = get_node_or_null("/root/SceneManager")
	if sm != null and sm.has_method("change_to"):
		sm.call_deferred("change_to", "res://src/scenes/world/rat_warehouse.tscn")
