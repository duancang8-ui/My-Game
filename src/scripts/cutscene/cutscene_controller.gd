extends Node

# 过场剧情控制器：在关卡开始时播放叙述性对话
# 期间禁用玩家移动；播放完毕后通过 finished 信号通知
# 复用 DialogueRunner + DialogueBox UI（speaker 留空显示为旁白）

signal finished()

@export var dialogue_box_path: NodePath = NodePath("../DialogueBox")
@export var player_path: NodePath = NodePath("../YSortContainer/Player")
@export var dialogue_id: String = ""           ## 待播放的过场对话 id（在 DialogueDatabase 里）
@export var auto_start: bool = true
@export var lock_player: bool = true

var _runner: DialogueRunner = null
var _box: DialogueBox = null
var _player: Node = null

func _ready() -> void:
    _box = get_node_or_null(dialogue_box_path) as DialogueBox
    _player = get_node_or_null(player_path)
    print("[Cutscene/%s] _ready box=%s player=%s auto=%s id=%s" % [name, _box, _player, auto_start, dialogue_id])
    if _box == null:
        push_warning("CutsceneController/%s: DialogueBox not found at %s" % [name, str(dialogue_box_path)])
    if auto_start and dialogue_id != "":
        call_deferred("play", dialogue_id)

func play(id: String) -> void:
    print("[Cutscene/%s] play '%s'" % [name, id])
    if _box == null:
        push_warning("[Cutscene/%s] _box is null → skip & emit finished" % name)
        finished.emit()
        return
    var db = get_node_or_null("/root/DialogueDatabase")
    if db == null or not db.has_dialogue(id):
        push_warning("[Cutscene/%s] dialogue '%s' not found → emit finished" % [name, id])
        finished.emit()
        return
    if lock_player and _player != null:
        _player.set_physics_process(false)
        if _player.has_method("set"):
            _player.set("velocity", Vector2.ZERO)
    _runner = DialogueRunner.new()
    _runner.dialogue_ended.connect(_on_runner_ended, CONNECT_ONE_SHOT)
    _box.attach_runner(_runner)
    if not _box.continue_pressed.is_connected(_on_continue):
        _box.continue_pressed.connect(_on_continue)
    if not _box.choice_picked.is_connected(_on_choice):
        _box.choice_picked.connect(_on_choice)
    _runner.start(db.get_lines(id), db.get_start_id(id))

func _on_continue() -> void:
    if _runner != null:
        _runner.advance()

func _on_choice(index: int) -> void:
    if _runner != null:
        _runner.pick_choice(index)

func _on_runner_ended() -> void:
    print("[Cutscene/%s] ended → emit finished" % name)
    if lock_player and _player != null:
        _player.set_physics_process(true)
    if _box != null:
        if _box.continue_pressed.is_connected(_on_continue):
            _box.continue_pressed.disconnect(_on_continue)
        if _box.choice_picked.is_connected(_on_choice):
            _box.choice_picked.disconnect(_on_choice)
    _runner = null
    finished.emit()
