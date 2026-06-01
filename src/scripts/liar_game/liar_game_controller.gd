class_name LiarGameController
extends Node

# 「说谎者」关卡核心逻辑（无 UI 依赖，可独立测试）
# - 关卡开始：state == PLAYING
# - 玩家提交投票后：state -> SUBMITTED, result == WIN/LOSE
# - 重复提交被忽略（投票一次性）

signal vote_submitted(target_id: String, result: int)

enum State { PLAYING, SUBMITTED }
enum Result { NONE, WIN, LOSE }

@export var liar_target_id: String = ""   ## 由场景或 Inspector 设置；空则使用 LiarNpcId.LIAR_ID

var state: int = State.PLAYING
var last_result: int = Result.NONE
var last_voted: String = ""

func _ready() -> void:
    if liar_target_id == "":
        liar_target_id = LiarNpcId.LIAR_ID

func submit_vote(target_id: String) -> void:
    if state == State.SUBMITTED:
        return
    state = State.SUBMITTED
    last_voted = target_id
    last_result = Result.WIN if target_id == liar_target_id else Result.LOSE
    vote_submitted.emit(target_id, last_result)

func reset() -> void:
    state = State.PLAYING
    last_result = Result.NONE
    last_voted = ""
