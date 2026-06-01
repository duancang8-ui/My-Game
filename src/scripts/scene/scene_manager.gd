extends Node

# 场景切换管理器（autoload）
# - 用 ColorRect 黑屏 overlay 做 fade in/out
# - 状态机：IDLE → FADING_OUT → LOADING → FADING_IN → IDLE
# - 切换期间忽略二次切换请求（防止竞态）
# - 自动监听场景里 type==SCENE_CHANGE 的 Interactable 触发

signal scene_change_started(target_path: String)
signal scene_change_finished(target_path: String)

enum State { IDLE, FADING_OUT, LOADING, FADING_IN }

const DEFAULT_FADE: float = 0.4

var state: int = State.IDLE
var _overlay: ColorRect
var _layer: CanvasLayer

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_overlay()
    # 玩家进入新场景时，自动扫描场景树连接 SCENE_CHANGE Interactable
    get_tree().node_added.connect(_on_node_added)
    # 当前场景启动时也扫一遍
    call_deferred("_scan_current_tree")

func _build_overlay() -> void:
    _layer = CanvasLayer.new()
    _layer.layer = 200    ## 最顶层（覆盖 Toast/ResultScreen）
    add_child(_layer)

    _overlay = ColorRect.new()
    _overlay.color = Color(0, 0, 0, 0)
    _overlay.anchor_left = 0
    _overlay.anchor_top = 0
    _overlay.anchor_right = 1
    _overlay.anchor_bottom = 1
    _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _layer.add_child(_overlay)

func change_to(scene_path: String, fade_duration: float = DEFAULT_FADE) -> void:
    if state != State.IDLE:
        push_warning("SceneManager: already changing scenes (state=%d), ignoring %s" % [state, scene_path])
        return
    if scene_path == "":
        push_warning("SceneManager: empty scene_path, ignored")
        return
    scene_change_started.emit(scene_path)
    state = State.FADING_OUT
    _overlay.mouse_filter = Control.MOUSE_FILTER_STOP   ## 阻挡输入，避免 fade 期间穿透
    var t1 := create_tween()
    t1.tween_property(_overlay, "color:a", 1.0, fade_duration)
    await t1.finished

    state = State.LOADING
    var err: int = get_tree().change_scene_to_file(scene_path)
    if err != OK:
        push_error("SceneManager: change_scene_to_file(%s) returned err=%d" % [scene_path, err])
        # 回滚
        _overlay.color.a = 0.0
        _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
        state = State.IDLE
        scene_change_finished.emit("")
        return
    # 更新 GameState
    var gs = get_node_or_null("/root/GameState")
    if gs != null:
        gs.current_scene_path = scene_path
    # 等一帧让新场景加载
    await get_tree().process_frame

    state = State.FADING_IN
    var t2 := create_tween()
    t2.tween_property(_overlay, "color:a", 0.0, fade_duration)
    await t2.finished

    _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    state = State.IDLE
    scene_change_finished.emit(scene_path)

func is_busy() -> bool:
    return state != State.IDLE

func _on_node_added(node: Node) -> void:
    if node is Interactable:
        var inter := node as Interactable
        if not inter.interaction_triggered.is_connected(_on_interaction):
            inter.interaction_triggered.connect(_on_interaction)

func _scan_current_tree() -> void:
    _scan_node_recursive(get_tree().root)

func _scan_node_recursive(node: Node) -> void:
    if node is Interactable:
        var inter := node as Interactable
        if not inter.interaction_triggered.is_connected(_on_interaction):
            inter.interaction_triggered.connect(_on_interaction)
    for child in node.get_children():
        _scan_node_recursive(child)

func _on_interaction(interactable: Interactable) -> void:
    if interactable.interaction_type != Interactable.Type.SCENE_CHANGE:
        return
    var target: String = interactable.scene_path
    if target == "":
        push_warning("SceneManager: Interactable SCENE_CHANGE has empty scene_path")
        return
    change_to(target)
