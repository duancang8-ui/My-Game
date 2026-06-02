extends Node2D

# P4 final · b1：NPC 头顶随机微表情气泡
# 每隔 5~15 秒随机显示一个符号约 0.8 秒
# 让 NPC 不像「死木桩」，给玩家一点环境活气
# 注意：纯视觉装饰，不携带游戏信息

@export var enabled: bool = true
@export var min_interval: float = 5.0
@export var max_interval: float = 15.0
@export var show_duration: float = 0.8

const SYMBOLS: Array = ["···", "?", "👀", "💭"]
const OFFSET: Vector2 = Vector2(0, -56)   ## NPC 头顶上方

var _label: Label
var _next_show_at: float = 0.0
var _hide_at: float = 0.0
var _time_acc: float = 0.0
var _rng: RandomNumberGenerator = null

func _ready() -> void:
	position = OFFSET
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	_build_label()
	_schedule_next()

func _build_label() -> void:
	_label = Label.new()
	_label.position = Vector2(-20, -10)
	_label.size = Vector2(40, 20)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.9, 0.9))
	_label.add_theme_constant_override("outline_size", 2)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_label.visible = false
	add_child(_label)

func _process(delta: float) -> void:
	if not enabled or _label == null:
		return
	_time_acc += delta
	if not _label.visible and _time_acc >= _next_show_at:
		_show_random()
	elif _label.visible and _time_acc >= _hide_at:
		_label.visible = false
		_schedule_next()

func _show_random() -> void:
	var sym: String = SYMBOLS[_rng.randi() % SYMBOLS.size()]
	_label.text = sym
	_label.visible = true
	_hide_at = _time_acc + show_duration

func _schedule_next() -> void:
	var interval: float = _rng.randf_range(min_interval, max_interval)
	_next_show_at = _time_acc + interval
