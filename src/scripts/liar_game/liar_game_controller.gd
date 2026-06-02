class_name LiarGameController
extends Node

# 「说谎者」关卡核心逻辑（无 UI 依赖，可独立测试）
# P4.7 重构 · 按原作 Ch1-10 校正：
#   - 所有 9 位"参与者"（玩家齐夏 + 8 NPC）手中都是「说谎者」卡
#   - 唯一的"非参与者讲故事人"是人羊（开场讲了"创造神"的故事）
#   - 解法：所有人投「人羊」→ WIN；任意一票投到参与者 → LOSE
# 因此本控制器在玩家提交答案时：
#   target == SHEEP_MASTER → WIN
#   target ∈ ALL 参与者     → LOSE (reason="wrong_vote")
#   超时未提交              → LOSE (reason="time_up")
#
# hint 系统（P4.6 加的暗示真假博弈）已**整体移除** —— 原作没有"人羊给暗示"的机制，
# 玩家应靠观察房间细节（方格、座钟、人羊"九位"措辞、人羊讲了创造神的故事）来推断。

signal vote_submitted(target_id: String, result: int)
signal time_changed(time_left: float)
signal time_expired()

enum State { PLAYING, SUBMITTED }
enum Result { NONE, WIN, LOSE }

@export var time_limit: float = 600.0     ## 10 分钟（原作没有明确时限，这是 game-feel 加的）
@export var auto_tick: bool = false       ## true → _process 自动驱动
@export var random_seed: int = 0          ## P4 final · c1：0 = 真随机；非零 = 复现（调试用）

var _rng: RandomNumberGenerator = null

var state: int = State.PLAYING
var last_result: int = Result.NONE
var last_voted: String = ""
var lose_reason: String = ""              ## "" / "wrong_vote" / "time_up"

# P4.6 · a3 倒计时
var time_left: float = 0.0

func _ready() -> void:
    time_left = time_limit
    set_process(auto_tick)

func get_rng() -> RandomNumberGenerator:
    # P4 final · c1：统一的随机源，可被 random_seed 控制
    if _rng == null:
        _rng = RandomNumberGenerator.new()
        if random_seed != 0:
            _rng.seed = random_seed
        else:
            _rng.randomize()
    return _rng

func _process(delta: float) -> void:
    if not auto_tick:
        return
    advance_time(delta)

func advance_time(delta: float) -> void:
    if state == State.SUBMITTED:
        return
    time_left = max(0.0, time_left - delta)
    time_changed.emit(time_left)
    if time_left <= 0.0:
        time_expired.emit()
        force_lose("time_up")

func submit_vote(target_id: String) -> void:
    if state == State.SUBMITTED:
        return
    state = State.SUBMITTED
    last_voted = target_id
    if target_id == LiarNpcId.SHEEP_MASTER:
        last_result = Result.WIN
        lose_reason = ""
    else:
        last_result = Result.LOSE
        lose_reason = "wrong_vote"
    vote_submitted.emit(target_id, last_result)

func force_lose(reason: String) -> void:
    if state == State.SUBMITTED:
        return
    state = State.SUBMITTED
    last_voted = ""
    last_result = Result.LOSE
    lose_reason = reason
    vote_submitted.emit("", last_result)

func reset() -> void:
    state = State.PLAYING
    last_result = Result.NONE
    last_voted = ""
    lose_reason = ""
    time_left = time_limit
