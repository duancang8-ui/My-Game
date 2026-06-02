extends Node

# Audio Manager autoload（占位骨架）
#
# 这是音频系统的"接口层"——
# 当前**没有真音频文件**，所有 play_* 都只打印日志 + emit 信号。
# 等正式音频资源到位时，把 SFX_TABLE / BGM_TABLE 改成真 AudioStream 即可，
# 调用方代码（LiarGameOrchestrator 等）完全不用改。
#
# 设计目标：
#   - 全局单例（autoload）
#   - 简单接口：play_sfx(id) / play_bgm(id) / stop_bgm()
#   - 音量层级：master * (sfx|bgm)，由设置面板未来控制
#   - 即使无音频文件也不会 crash

signal sfx_played(id: String)
signal bgm_changed(id: String)

# 音量配置（0.0 - 1.0）
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var bgm_volume: float = 0.7

# 当前 BGM id（用于切歌避重）
var current_bgm: String = ""

# 音效表：id → AudioStream（暂时全 null，正式资源到位后填入）
# 注：用 const Dictionary，不能在 const 里写 null Stream，所以用 var + _ready 初始化
var SFX_TABLE: Dictionary = {}
var BGM_TABLE: Dictionary = {}

# 内部 player（占位 — 实际播放会用到）
var _sfx_player: AudioStreamPlayer
var _bgm_player: AudioStreamPlayer

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_players()
    _init_tables()

func _build_players() -> void:
    _sfx_player = AudioStreamPlayer.new()
    _sfx_player.bus = "Master"
    add_child(_sfx_player)
    _bgm_player = AudioStreamPlayer.new()
    _bgm_player.bus = "Master"
    add_child(_bgm_player)

func _init_tables() -> void:
    # 占位 - 所有 SFX 当前是 null，调用时只打印日志
    # 正式音频到位后，改为 preload("res://src/assets/audio/sfx/XXX.ogg")
    for id in [
        # 通用
        "ui_click", "ui_hover", "ui_open_panel", "ui_close_panel",
        # 对话
        "dialogue_advance", "dialogue_choice",
        # 关卡 · 胜负
        "win_chime", "lose_thud", "skull_crack",
        # 说谎者
        "liar_card_flip", "liar_vote_submit",
        # 雨后春笋
        "rain_drip", "table_rotate_click", "spear_swoosh", "shield_form",
        # 人鼠
        "rat_box_open", "rat_clue_aha", "rat_pocket_reveal",
        # 玉城
        "yucheng_step", "dao_earn", "dao_spend", "shop_purchase",
        # 道具
        "item_use", "rest_ticket_tear",
        # 灯/环境
        "light_switch", "footstep_wood",
    ]:
        SFX_TABLE[id] = null
    for id in ["bgm_yucheng_calm", "bgm_interview_tense", "bgm_rainy_field", "bgm_rat_warehouse", "bgm_main_menu"]:
        BGM_TABLE[id] = null

# ===== 公开接口 =====

func play_sfx(id: String) -> void:
    if not SFX_TABLE.has(id):
        push_warning("AudioManager: unknown sfx id '%s'" % id)
        return
    var stream: AudioStream = SFX_TABLE[id]
    sfx_played.emit(id)
    if stream == null:
        # 占位：没有真音频，仅日志
        print("[SFX] %s" % id)
        return
    _sfx_player.stream = stream
    _sfx_player.volume_db = _vol_to_db(master_volume * sfx_volume)
    _sfx_player.play()

func play_bgm(id: String, fade_duration: float = 0.6) -> void:
    if id == current_bgm:
        return   # 避重，正在播同一首
    if not BGM_TABLE.has(id):
        push_warning("AudioManager: unknown bgm id '%s'" % id)
        return
    current_bgm = id
    bgm_changed.emit(id)
    var stream: AudioStream = BGM_TABLE[id]
    if stream == null:
        print("[BGM] -> %s" % id)
        return
    if fade_duration > 0.0 and _bgm_player.playing:
        var t := create_tween()
        t.tween_property(_bgm_player, "volume_db", -60.0, fade_duration)
        await t.finished
    _bgm_player.stream = stream
    _bgm_player.volume_db = _vol_to_db(master_volume * bgm_volume)
    _bgm_player.play()

func stop_bgm(fade_duration: float = 0.6) -> void:
    if current_bgm == "":
        return
    var prev: String = current_bgm
    current_bgm = ""
    bgm_changed.emit("")
    if _bgm_player.stream == null:
        print("[BGM] stop (was %s)" % prev)
        return
    if fade_duration > 0.0:
        var t := create_tween()
        t.tween_property(_bgm_player, "volume_db", -60.0, fade_duration)
        await t.finished
    _bgm_player.stop()

# ===== 工具 =====

func _vol_to_db(linear: float) -> float:
    if linear <= 0.0:
        return -60.0
    return linear_to_db(linear)

# 测试 helper：把所有 SFX 静音（防止单元测试打印噪声）
func set_silent_for_test(silent: bool) -> void:
    master_volume = 0.0 if silent else 1.0
