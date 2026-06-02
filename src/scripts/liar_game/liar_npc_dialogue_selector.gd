extends Node

# P4.6 · a2 多轮对话切换器
# 根据 GameState.npc_visit_count[base_dialogue_id] 把 Interactable.dialogue_id
# 在 base / base_v2 / base_v3 之间切换。
#
# 工作流：
#   - _ready: 扫描场景中所有 dialogue_id 以 "liar_" 开头的 Interactable，
#     把当前 dialogue_id 记为 base_dialogue_id（v1）
#   - _process: 每帧根据 visit_count 调整 Interactable.dialogue_id
#     count == 0 → base
#     count == 1 → base + "_v2"
#     count >= 2 → base + "_v3"
#
# 注意：dialogue_id 修改不会触发 Interactable 内部任何变化，DialogueController
# 在 _on_interaction 时直接读取最新 dialogue_id，所以切换是即时生效的。

@export var npc_id_prefix: String = "liar_"   ## 只接管 dialogue_id 以此为前缀的 Interactable

var _base_by_node: Dictionary = {}            ## Interactable Node → base dialogue_id (String)

func _ready() -> void:
	# 等场景里所有 Interactable 都 _ready 完毕再扫描
	call_deferred("_scan_interactables")

func _scan_interactables() -> void:
	_base_by_node.clear()
	_collect(get_tree().root)

func _collect(node: Node) -> void:
	if node is Interactable:
		var inter := node as Interactable
		if inter.interaction_type == Interactable.Type.DIALOGUE \
				and inter.dialogue_id.begins_with(npc_id_prefix):
			# 取最短前缀（去掉 _v2/_v3 后缀，得到 base）
			var base: String = _strip_version_suffix(inter.dialogue_id)
			_base_by_node[inter] = base
			# 初始就根据当前 visit_count 设置
			_apply_for(inter, base)
	for child in node.get_children():
		_collect(child)

func _process(_delta: float) -> void:
	# 每帧轮询（9 个节点开销极小）；保证 visit_count 变化后下一帧即生效
	for node in _base_by_node.keys():
		if is_instance_valid(node):
			_apply_for(node, _base_by_node[node])

func _apply_for(inter: Interactable, base: String) -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null or not gs.has_method("get_visit_count"):
		return
	var count: int = gs.get_visit_count(base)
	var target_id: String
	if count == 0:
		target_id = base
	elif count == 1:
		target_id = base + "_v2"
	else:
		target_id = base + "_v3"
	if inter.dialogue_id != target_id:
		inter.dialogue_id = target_id

# 把 "liar_lin_qin_v3" 还原成 "liar_lin_qin"
func _strip_version_suffix(dialogue_id: String) -> String:
	if dialogue_id.ends_with("_v3"):
		return dialogue_id.substr(0, dialogue_id.length() - 3)
	if dialogue_id.ends_with("_v2"):
		return dialogue_id.substr(0, dialogue_id.length() - 3)
	return dialogue_id

# 测试 helper：手动注册 Interactable（绕过 _scan）
func register_interactable_for_test(inter: Interactable, base: String) -> void:
	_base_by_node[inter] = base
	_apply_for(inter, base)
