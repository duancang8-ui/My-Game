class_name RotateGameController
extends Node

# 「雨后春笋」关卡核心逻辑（无 UI 依赖，可独立测试）
# - 玩家按 E 旋转桌面（add_rotation）累积进度
# - 限时内达到 target_rotations 即胜利
# - 超时未达标即失败
# - 验证项目架构对"时间反应类"关卡的支持（vs 说谎者的"社交推理类"）

signal rotated(current: int, target: int)
signal time_changed(time_left: float)
signal game_ended(result: int)

enum State { READY, PLAYING, ENDED }
enum Result { NONE, WIN, LOSE }

@export var target_rotations: int = 100   ## 通关所需旋转次数
@export var time_limit: float = 30.0      ## 限定时间（秒）

var state: int = State.READY
var rotations: int = 0
var time_left: float = 0.0
var last_result: int = Result.NONE

func _ready() -> void:
    time_left = time_limit

func start_game() -> void:
    state = State.PLAYING
    rotations = 0
    time_left = time_limit
    last_result = Result.NONE

func _process(delta: float) -> void:
    if state != State.PLAYING:
        return
    time_left = max(0.0, time_left - delta)
    time_changed.emit(time_left)
    if time_left <= 0.0:
        _finish(Result.LOSE)

func add_rotation() -> void:
    if state != State.PLAYING:
        return
    rotations += 1
    rotated.emit(rotations, target_rotations)
    if rotations >= target_rotations:
        _finish(Result.WIN)

func _finish(result: int) -> void:
    state = State.ENDED
    last_result = result
    game_ended.emit(result)

func reset() -> void:
    state = State.READY
    rotations = 0
    time_left = time_limit
    last_result = Result.NONE
