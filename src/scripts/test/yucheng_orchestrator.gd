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
