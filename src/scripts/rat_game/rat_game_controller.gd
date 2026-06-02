class_name RatGameController
extends Node

# P8 「人鼠 · 仓库寻道」核心逻辑
# 表面规则：5 分钟内找到 1 个「道」带出仓库
# 真相：「道」不在房间里，在人鼠口袋里
# 玩家只有走到门口和人鼠对话、选「摸她口袋」才能赢
#
# 控制器只管状态机和计时，"如何赢"的判断由 Orchestrator 触发 reveal_win()

signal time_changed(time_left: float)
signal time_expired()
signal game_ended(result: int)

enum State { READY, PLAYING, ENDED }
enum Result { NONE, WIN, LOSE }

@export var time_limit: float = 300.0   ## 5 分钟
@export var auto_tick: bool = false

var state: int = State.READY
var time_left: float = 0.0
var last_result: int = Result.NONE

func _ready() -> void:
    time_left = time_limit
    set_process(auto_tick)

func _process(delta: float) -> void:
    if not auto_tick:
        return
    advance_time(delta)

func start_game() -> void:
    state = State.PLAYING
    time_left = time_limit
    last_result = Result.NONE

func advance_time(delta: float) -> void:
    if state != State.PLAYING:
        return
    time_left = max(0.0, time_left - delta)
    time_changed.emit(time_left)
    if time_left <= 0.0:
        time_expired.emit()
        _finish(Result.LOSE)

func reveal_win() -> void:
    # 玩家成功识破：从人鼠身上拿到「道」
    if state != State.PLAYING:
        return
    _finish(Result.WIN)

func give_up() -> void:
    # 玩家中途退出（走出场景而不胜利）
    if state != State.PLAYING:
        return
    _finish(Result.LOSE)

func _finish(result: int) -> void:
    state = State.ENDED
    last_result = result
    game_ended.emit(result)

func reset() -> void:
    state = State.READY
    time_left = time_limit
    last_result = Result.NONE
