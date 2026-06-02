class_name BearGameController
extends Node

# P10 「地牛 · 黑熊地下室」核心逻辑
# - 90 秒限时
# - 每 12 秒一轮咆哮：[0-9s] 自由 → [9-12s] 预警 → [12s] 判定
# - 判定时玩家若在「安全区」（铁柱附近）→ 0 伤；否则 -1 体力
# - 体力 0 = LOSE；时限到 = WIN
#
# 控制器只管时间和体力，"玩家是否在安全区" 由 Orchestrator 判断后调 apply_roar_judgement(safe)

signal time_changed(time_left: float)
signal stamina_changed(stamina: int)
signal roar_warning(seconds_until_roar: float)   ## 预警阶段
signal roar_judgement_needed()                   ## 咆哮判定瞬间，Orchestrator 必须立即调 apply_roar_judgement(safe)
signal roar_impact(was_safe: bool, stamina_after: int)
signal game_ended(result: int)

enum State { READY, PLAYING, ENDED }
enum Result { NONE, WIN, LOSE }

@export var time_limit: float = 90.0
@export var max_stamina: int = 5
@export var roar_interval: float = 12.0   ## 每 12 秒一轮
@export var warning_duration: float = 3.0 ## 咆哮前的预警时长（玩家能听到/看到才公平）
@export var auto_tick: bool = false

var state: int = State.READY
var time_left: float = 0.0
var stamina: int = 0
var last_result: int = Result.NONE

# 内部周期计时
var _phase_elapsed: float = 0.0   ## 距离上一次咆哮的累积秒数
var _in_warning: bool = false     ## 是否处于预警阶段
var _warning_emitted: bool = false

func _ready() -> void:
    time_left = time_limit
    stamina = max_stamina
    set_process(auto_tick)

func _process(delta: float) -> void:
    if not auto_tick:
        return
    advance_time(delta)

func start_game() -> void:
    state = State.PLAYING
    time_left = time_limit
    stamina = max_stamina
    last_result = Result.NONE
    _phase_elapsed = 0.0
    _in_warning = false
    _warning_emitted = false

func advance_time(delta: float) -> void:
    if state != State.PLAYING:
        return
    # 整体倒计时
    time_left = max(0.0, time_left - delta)
    time_changed.emit(time_left)
    if time_left <= 0.0:
        _finish(Result.WIN)
        return
    # 咆哮周期
    _phase_elapsed += delta
    var time_to_roar: float = roar_interval - _phase_elapsed
    if not _in_warning and time_to_roar <= warning_duration:
        _in_warning = true
        _warning_emitted = false
    if _in_warning and not _warning_emitted:
        roar_warning.emit(time_to_roar)
        _warning_emitted = true
    if _phase_elapsed >= roar_interval:
        # 同步信号：Orchestrator 监听器会立即调 apply_roar_judgement(safe)
        # signal 派发是同步的，所以 emit 返回时 stamina 已经更新
        roar_judgement_needed.emit()
        _phase_elapsed = 0.0
        _in_warning = false
        _warning_emitted = false

# Orchestrator 在咆哮判定瞬间调这个：传入玩家是否在安全区
func apply_roar_judgement(player_safe: bool) -> void:
    if state != State.PLAYING:
        return
    if not player_safe:
        stamina = max(0, stamina - 1)
    stamina_changed.emit(stamina)
    roar_impact.emit(player_safe, stamina)
    if stamina <= 0:
        _finish(Result.LOSE)

func _finish(result: int) -> void:
    state = State.ENDED
    last_result = result
    game_ended.emit(result)

func reset() -> void:
    state = State.READY
    time_left = time_limit
    stamina = max_stamina
    last_result = Result.NONE
    _phase_elapsed = 0.0
    _in_warning = false
    _warning_emitted = false

# 测试 helper：直接强制结束
func force_lose() -> void:
    if state == State.PLAYING:
        _finish(Result.LOSE)
